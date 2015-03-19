// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentPreparationQueue.h"
#import "FBComponentPreparationQueueInternal.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "CKMutex.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentPreparationQueueListenerAnnouncer.h"

@implementation FBComponentPreparationInputItem
{
  FBSizeRange _constrainedSize;
}

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                         constrainedSize:(FBSizeRange)constrainedSize
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                               indexPath:(NSIndexPath *)indexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
{
  if (self = [super init]) {
    _replacementModel = replacementModel;
    _lifecycleManager = lifecycleManager;
    _constrainedSize = constrainedSize;
    _UUID = [UUID copy];
    _indexPath = [indexPath copy];
    _changeType = changeType;
    _passthrough = passthrough;
    _oldSize = oldSize;
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

@synthesize replacementModel = _replacementModel;
@synthesize lifecycleManager = _lifecycleManager;
@synthesize UUID = _UUID;
@synthesize indexPath = _indexPath;
@synthesize changeType = _changeType;
@synthesize passthrough = _passthrough;
@synthesize oldSize = _oldSize;

- (FBSizeRange)constrainedSize
{
  return _constrainedSize;
}

@end

@implementation FBComponentPreparationOutputItem
{
  FBComponentLifecycleManagerState _lifecycleManagerState;
}

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(FBComponentLifecycleManagerState)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                               indexPath:(NSIndexPath *)indexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough
{
  if (self = [super init]) {
    _replacementModel = replacementModel;
    _lifecycleManager = lifecycleManager;
    _lifecycleManagerState = lifecycleManagerState;
    _UUID = [UUID copy];
    _indexPath = [indexPath copy];
    _changeType = changeType;
    _passthrough = passthrough;
    _oldSize = oldSize;
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

@synthesize replacementModel = _replacementModel;
@synthesize lifecycleManager = _lifecycleManager;
@synthesize UUID = _UUID;
@synthesize indexPath = _indexPath;
@synthesize changeType = _changeType;
@synthesize passthrough = _passthrough;
@synthesize oldSize = _oldSize;

- (FBComponentLifecycleManagerState)lifecycleManagerState
{
  return _lifecycleManagerState;
}

@end

@interface FBComponentPreparationQueueJob : NSObject {
  @public
  FBComponentPreparationInputBatch _batch;
  FBComponentPreparationQueueCallback _block;
}

- (instancetype)initWithBatch:(const FBComponentPreparationInputBatch &)batch
                        block:(FBComponentPreparationQueueCallback)block;
@end

@implementation FBComponentPreparationQueueJob

- (instancetype)initWithBatch:(const FBComponentPreparationInputBatch &)batch
                        block:(FBComponentPreparationQueueCallback)block
{
  self = [super init];
  if (self) {
    _batch = batch;
    _block = block;
  }
  return self;
}
@end

@implementation FBComponentPreparationQueue
{
  dispatch_queue_t _concurrentQueue;
  dispatch_queue_t _inputQueue;
  NSUInteger _queueWidth;

  CK::Mutex _lock;

  FBComponentPreparationQueueListenerAnnouncer *_announcer;
}

- (instancetype)initWithQueueWidth:(NSInteger)queueWidth
{
  if (self = [super init]) {
    _announcer = [[FBComponentPreparationQueueListenerAnnouncer alloc] init];
    _concurrentQueue = dispatch_queue_create("com.facebook.component-preparation-queue.concurrent", DISPATCH_QUEUE_CONCURRENT);
    _inputQueue = dispatch_queue_create("com.facebook.component-preparation-queue.serial", DISPATCH_QUEUE_SERIAL);
    if (queueWidth > 0) {
      _queueWidth = queueWidth;
    } else {
      CKFailAssert(@"The queue width is zero, the queue is blocked and no items will be computed");
      // Fallback to a sensible value
      _queueWidth = 5;
    }
  }
  return self;
}

#pragma mark - Public

- (void)enqueueBatch:(const FBComponentPreparationInputBatch &)batch
               block:(FBComponentPreparationQueueCallback)block
{
  CKAssertMainThread();
  FBComponentPreparationQueueJob *job = [[FBComponentPreparationQueueJob alloc] initWithBatch:batch block:block];
  // We dispatch every batch processing operation to a serial queue as
  // each batch needs to be processed in the enqueue order.
  dispatch_async(_inputQueue, ^{
    [self _processJob:job];
  });
}

#pragma mark - Private

- (void)_processJob:(FBComponentPreparationQueueJob *)job
{
  // All announcments are scheduled on the main thread
  dispatch_async(dispatch_get_main_queue(), ^{
    [_announcer componentPreparationQueue:self
             didStartPreparingBatchOfSize:job->_batch.items.size()
                                  batchID:job->_batch.ID];
  });

  // Each story in the batch is dispatched on a concurrent queue, we use a semaphore to regulate the width of the queue
  NSMutableArray *outputBatch = [NSMutableArray arrayWithCapacity:job->_batch.items.size()];
  dispatch_semaphore_t regulationSemaphore = dispatch_semaphore_create(_queueWidth);
  dispatch_group_t group = dispatch_group_create();
  for (FBComponentPreparationInputItem *inputItem : job->_batch.items) {
    dispatch_semaphore_wait(regulationSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_group_async(group, _concurrentQueue, ^{
      FBComponentPreparationOutputItem *result = [[self class] prepare:inputItem];
      {
        CK::MutexLocker l(_lock);
        [outputBatch addObject:result];
      }
      dispatch_semaphore_signal(regulationSemaphore);
    });
  }

  // We have to wait until all the stories are computed before announcing the new batch on the main thread
  // As soon as we return from this method _inputQueue may begin processing the next job.
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  dispatch_async(dispatch_get_main_queue(), ^{
    [_announcer componentPreparationQueue:self
            didFinishPreparingBatchOfSize:job->_batch.items.size()
                                  batchID:job->_batch.ID];
    NSArray *outputBatchCopy = [outputBatch copy];
    job->_block(job->_batch.sections, job->_batch.ID, outputBatchCopy, job->_batch.isContiguousTailInsertion);
  });
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

#pragma mark - Listeners

- (void)addListener:(id<FBComponentPreparationQueueListener>)listener
{
  [_announcer addListener:listener];
}
- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener
{
  [_announcer removeListener:listener];
}

@end
