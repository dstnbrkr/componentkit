// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentNonRegulatedPreparationQueue.h"

#import <queue>

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "CKMutex.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentPreparationQueueListenerAnnouncer.h"

struct FBComponentPreparationQueueJob {
  FBComponentPreparationInputBatch batch;
  FBComponentPreparationQueueCallback block;
};

@implementation FBComponentNonRegulatedPreparationQueue
{
  std::queue<FBComponentPreparationQueueJob> _inputJobs;

  dispatch_queue_t _queue;
  dispatch_group_t _group;

  CK::Mutex _lock;

  FBComponentPreparationQueueListenerAnnouncer *_announcer;
}

- (instancetype)initWithQueueWidth:(NSInteger)queueWidth
{
  if (self = [super init]) {
    _announcer = [[FBComponentPreparationQueueListenerAnnouncer alloc] init];
    _queue = dispatch_queue_create("com.facebook.component-preparation-queue.concurrent", DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

#pragma mark - Public

- (void)enqueueBatch:(const FBComponentPreparationInputBatch &)batch
               block:(FBComponentPreparationQueueCallback)block
{
  CKAssertMainThread();
  _inputJobs.push({
    .batch = batch,
    .block = block,
  });
  [self _processBatch];
}

#pragma mark - Private

- (void)_processBatch
{
  if (_inputJobs.size() && !_group) {

    FBComponentPreparationQueueJob firstJob = _inputJobs.front();
    _inputJobs.pop();
    _group = dispatch_group_create();

    [_announcer componentPreparationQueue:self
             didStartPreparingBatchOfSize:firstJob.batch.items.size()
                                  batchID:firstJob.batch.ID];

    NSMutableArray *outputBatch = [NSMutableArray arrayWithCapacity:firstJob.batch.items.size()];
    for (FBComponentPreparationInputItem *inputItem : firstJob.batch.items) {
      dispatch_group_async(_group, _queue, ^{
        FBComponentPreparationOutputItem *result = [[self class] prepare:inputItem];
        CK::MutexLocker l(_lock);
        [outputBatch addObject:result];
      });
    }

    dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
      [_announcer componentPreparationQueue:self
              didFinishPreparingBatchOfSize:firstJob.batch.items.size()
                                    batchID:firstJob.batch.ID];

      NSArray *outputBatchCopy = [outputBatch copy];
      firstJob.block(firstJob.batch.sections, firstJob.batch.ID, outputBatchCopy, firstJob.batch.isContiguousTailInsertion);

      _group = NULL; // Clear out to mark the queue as "not processing a batch".
      [self _processBatch];
    });
  }
}

#pragma mark - Concurrent Queue

+ (FBComponentPreparationOutputItem *)prepare:(FBComponentPreparationInputItem *)inputItem
{
  FBComponentPreparationOutputItem *outputItem = nil;
  if (![inputItem isPassthrough]) {
    CKArrayControllerChangeType changeType = [inputItem changeType];
    if (changeType == CKArrayControllerChangeTypeInsert ||
        changeType == CKArrayControllerChangeTypeUpdate) {

      FBComponentLifecycleManager *lifecycleManager = [inputItem lifecycleManager];
      FBComponentLifecycleManagerState state = [lifecycleManager prepareForUpdateWithModel:[inputItem replacementModel]
                                                                           constrainedSize:[inputItem constrainedSize]];

      outputItem = [[FBComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                     lifecycleManager:lifecycleManager
                                                                lifecycleManagerState:state
                                                                              oldSize:[inputItem oldSize]
                                                                                 UUID:[inputItem UUID]
                                                                            indexPath:[inputItem indexPath]
                                                                           changeType:[inputItem changeType]
                                                                          passthrough:[inputItem isPassthrough]];
    } else if (changeType == CKArrayControllerChangeTypeDelete) {
      outputItem = [[FBComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                     lifecycleManager:nil
                                                                lifecycleManagerState:FBComponentLifecycleManagerStateEmpty
                                                                              oldSize:[inputItem oldSize]
                                                                                 UUID:[inputItem UUID]
                                                                            indexPath:[inputItem indexPath]
                                                                           changeType:[inputItem changeType]
                                                                          passthrough:[inputItem isPassthrough]];
    } else {
      CKFailAssert(@"Unimplemented %d", changeType);
    }
  } else {
    outputItem = [[FBComponentPreparationOutputItem alloc] initWithReplacementModel:[inputItem replacementModel]
                                                                   lifecycleManager:[inputItem lifecycleManager]
                                                              lifecycleManagerState:FBComponentLifecycleManagerStateEmpty
                                                                            oldSize:[inputItem oldSize]
                                                                               UUID:[inputItem UUID]
                                                                          indexPath:[inputItem indexPath]
                                                                         changeType:[inputItem changeType]
                                                                        passthrough:[inputItem isPassthrough]];
  }
  return outputItem;
}

@end
