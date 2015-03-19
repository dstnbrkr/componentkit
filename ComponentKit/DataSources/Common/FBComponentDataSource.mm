// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentDataSource.h"

#include <queue>

#import <FBComponentKit/CKSectionedArrayController.h>

#import <FBComponentKit/CKArgumentPrecondition.h>
#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "FBComponentDataSourceInputItem.h"
#import "FBComponentDataSourceOutputItem.h"
#import "FBComponentDeciding.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentLifecycleManagerAsynchronousUpdateHandler.h"
#import "FBComponentNonRegulatedPreparationQueue.h"
#import "FBComponentPreparationQueue.h"
#import "FBComponentPreparationQueueListener.h"
#import "FBSuspensionController.h"

using namespace CK::ArrayController;

@interface FBComponentDataSource () <
FBSuspensionControllerOutputHandler,
FBComponentLifecycleManagerDelegate,
FBComponentLifecycleManagerAsynchronousUpdateHandler
>
@end

@implementation FBComponentDataSource
{
  id<FBComponentDeciding> _decider;

  /*
   Please see the discussion on why we need two arrays
   https://www.facebook.com/groups/574870245894928/permalink/645686615479957/

   The basic flow is

   Changes -> _inputArrayController -(async)-> Queue -(async)-> _outputArrayController -> delegate

   The _inputArrayController reflects the updated state to the subsequent changes
   that are coming in immediately since it is updated in sync.
   */
  FBSectionedArrayController *_outputArrayController;
  FBSectionedArrayController *_inputArrayController;
  FBComponentPreparationQueue *_componentPreparationQueue;
  FBSuspensionController *_suspensionController;
  std::queue<PreparationBatchID> _operationsInPreparationQueueTracker;
}

CK_FINAL_CLASS([FBComponentDataSource class]);

#pragma mark - Lifecycle

- (instancetype)initWithLifecycleManagerFactory:(FBComponentLifecycleManagerFactory)lifecycleManagerFactory
                                        decider:(id<FBComponentDeciding>)decider
                           inputArrayController:(FBSectionedArrayController *)inputArrayController
                          outputArrayController:(FBSectionedArrayController *)outputArrayController
                               preparationQueue:(FBComponentPreparationQueue *)preparationQueue
                           suspensionController:(FBSuspensionController *)suspensionController
{
  if (self = [super init]) {
    // Injected dependencies.
    _lifecycleManagerFactory = lifecycleManagerFactory;
    _decider = decider;

    // Internal dependencies.
    _inputArrayController = inputArrayController;
    _outputArrayController = outputArrayController;
    _componentPreparationQueue = preparationQueue;
    _suspensionController = suspensionController;

    Sections sections;
    sections.insert(0);
    CKArrayControllerInputChangeset changeset = {sections, {}};
    (void)[_inputArrayController applyChangeset:changeset];
    (void)[_outputArrayController applyChangeset:changeset];

    _suspensionController.state = FBSuspensionControllerStateFullySuspended;
  }
  return self;
}

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<FBComponentDeciding>)decider
{
  return [self initWithComponentProvider:componentProvider
                                 context:context
                                 decider:decider
                   preparationQueueWidth:0];
}

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<FBComponentDeciding>)decider
                    preparationQueueWidth:(NSInteger)preparationQueueWidth
{
  FBComponentLifecycleManagerFactory lifecycleManagerFactory = ^{
    return [[FBComponentLifecycleManager alloc] initWithComponentProvider:componentProvider context:context];
  };
  FBComponentPreparationQueue *prepQueue = (preparationQueueWidth > 0) ? [[FBComponentPreparationQueue alloc] initWithQueueWidth:preparationQueueWidth] :
  [[FBComponentNonRegulatedPreparationQueue alloc] initWithQueueWidth:0];
  return [self initWithLifecycleManagerFactory:lifecycleManagerFactory
                                       decider:decider
                          inputArrayController:[[FBSectionedArrayController alloc] init]
                         outputArrayController:[[FBSectionedArrayController alloc] init]
                              preparationQueue:prepQueue
                          suspensionController:[[FBSuspensionController alloc] initWithOutputHandler:self]];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Public API

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p; inputArrayController = %@; outputArrayController = %@>",
          [self class],
          self,
          _inputArrayController,
          _outputArrayController];
}

- (NSInteger)numberOfSections
{
  return [_outputArrayController numberOfSections];
}

- (NSInteger)numberOfObjectsInSection:(NSInteger)section
{
  return (NSInteger)[_outputArrayController numberOfObjectsInSection:section];
}

- (FBComponentDataSourceOutputItem *)objectAtIndexPath:(NSIndexPath *)indexPath
{
  return [_outputArrayController objectAtIndexPath:indexPath];
}

- (void)enumerateObjectsUsingBlock:(FBComponentDataSourceEnumerator)block
{
  if (block) {
    [_outputArrayController enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
      block(object, indexPath, stop);
    }];
  }
}

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(FBComponentDataSourceEnumerator)block
{
  if (block) {
    [_outputArrayController enumerateObjectsInSectionAtIndex:section
                                                  usingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
                                                    block(object, indexPath, stop);
                                                  }];
  }
}

- (std::pair<FBComponentDataSourceOutputItem *, NSIndexPath *>)firstObjectPassingTest:(FBComponentDataSourcePredicate)predicate
{
  return [_outputArrayController firstObjectPassingTest:predicate];
}

- (std::pair<FBComponentDataSourceOutputItem *, NSIndexPath *>)objectForUUID:(NSString *)UUID
{
  return [self firstObjectPassingTest:
          ^BOOL(FBComponentDataSourceOutputItem *object, NSIndexPath *indexPath, BOOL *stop) {
            return [[object UUID] isEqual:UUID];
          }];
}

- (void)enqueueReload
{
  __block Input::Items items;
  [_inputArrayController enumerateObjectsUsingBlock:^(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop) {
    items.update(indexPath, object);
  }];
  Input::Changeset changeset(items);
  [self _enqueueChangeset:changeset];
}

/**
 External client is either FBComponentTableViewDataSource or the owner of the table view data source.
 They can't insert an FBComponentDataSourceInput b/c they don't have access to existing lifecycle managers that are in
 the _writeArrayController.

 Therefore we map() the input to wrap each item given to us.
 */
- (PreparationBatchID)enqueueChangeset:(const Input::Changeset &)changeset constrainedSize:(const FBSizeRange &)constrainedSize
{
  Input::Changeset::Mapper mapper =
  ^id<NSObject>(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    FBComponentLifecycleManager *lifecycleManager = nil;
    NSString *UUID = nil;
    if (type == CKArrayControllerChangeTypeInsert) {
      lifecycleManager = _lifecycleManagerFactory();
      lifecycleManager.asynchronousUpdateHandler = self;
      lifecycleManager.delegate = self;
      UUID = [[NSUUID UUID] UUIDString];
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      FBComponentDataSourceInputItem *oldInput = [_inputArrayController objectAtIndexPath:indexPath.toNSIndexPath()];
      lifecycleManager = [oldInput lifecycleManager];
      UUID = [oldInput UUID];
    }
    return [[FBComponentDataSourceInputItem alloc] initWithLifecycleManager:lifecycleManager
                                                                      model:object
                                                            constrainedSize:constrainedSize
                                                                       UUID:UUID];
  };
  return [self _enqueueChangeset:changeset.map(mapper)];
}

- (PreparationBatchID)_enqueueChangeset:(const Input::Changeset &)changeset
{
  auto output = [_inputArrayController applyChangeset:changeset];

  __block FBComponentPreparationInputBatch preparationQueueBatch;
  preparationQueueBatch.sections = output.getSections();

  __block BOOL batchContainsSectionInserts = NO;
  __block BOOL batchContainsUpdates = NO;
  __block BOOL batchContainsDeletions = NO;

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      batchContainsDeletions = YES;
    }

    if (type == CKArrayControllerChangeTypeInsert) {
      batchContainsSectionInserts = YES;
    }
  };

  NSMutableSet *insertedIndexPaths = [[NSMutableSet alloc] init];
  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      batchContainsDeletions = YES;
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      batchContainsUpdates = YES;
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [insertedIndexPaths addObject:change.indexPath.toNSIndexPath()];
    }

    FBComponentDataSourceInputItem *before = change.before;
    FBComponentDataSourceInputItem *after = change.after;
    id componentCompliantModel = [_decider componentCompliantModel:[after model]];

    FBSizeRange constrainedSize = (type == CKArrayControllerChangeTypeDelete) ? FBSizeRange() : [after constrainedSize];
    FBComponentPreparationInputItem *queueItem =
    [[FBComponentPreparationInputItem alloc] initWithReplacementModel:[after model]
                                                     lifecycleManager:[after lifecycleManager]
                                                      constrainedSize:constrainedSize
                                                              oldSize:[before lifecycleManager].size
                                                                 UUID:[after UUID]
                                                            indexPath:change.indexPath.toNSIndexPath()
                                                           changeType:type
                                                          passthrough:(componentCompliantModel == nil)];
    preparationQueueBatch.items.push_back(queueItem);
  };

  output.enumerate(sectionsEnumerator, itemsEnumerator);

  // TODO: What about empty trailing sections? Should we find the last non-empty section?
  const NSInteger numberOfSections = [_inputArrayController numberOfSections];
  if (numberOfSections > 0) {
    BOOL insertAtTail = NO;

    const NSInteger lastSectionIndex = numberOfSections - 1;
    // If you are suspended you might try to add elements to a section that does not exist yet in the output array
    // Hence protecting from accessing it
    if (lastSectionIndex < [_inputArrayController numberOfSections]) {
      const NSInteger numberOfObjects = [_inputArrayController numberOfObjectsInSection:lastSectionIndex] - insertedIndexPaths.count;
      NSIndexPath *expectedNextTailIndexPath = [NSIndexPath indexPathForItem:numberOfObjects inSection:lastSectionIndex];
      insertAtTail = _indexPathsAreContiguousFromStartingIndexPath(insertedIndexPaths, expectedNextTailIndexPath);
    }
    preparationQueueBatch.isContiguousTailInsertion = (!batchContainsDeletions &&
                                                       !batchContainsUpdates &&
                                                       !batchContainsSectionInserts &&
                                                       insertAtTail
                                                       );
  }

  preparationQueueBatch.ID = batchID();
  _operationsInPreparationQueueTracker.push(preparationQueueBatch.ID);
  [_componentPreparationQueue enqueueBatch:preparationQueueBatch
                                     block:^(const Sections &sections, PreparationBatchID ID, NSArray *outputBatch, BOOL isContiguousTailInsertion) {
                                       CKInternalConsistencyCheckIf(_operationsInPreparationQueueTracker.size() > 0, @"We dequeued more batches than what we enqueued something went really wrong.");
                                       CKInternalConsistencyCheckIf(_operationsInPreparationQueueTracker.front() == ID, @"Batches were executed out of order some were dropped on the floor.");
                                       _operationsInPreparationQueueTracker.pop();
                                       [self _componentPreparationQueueDidPrepareBatch:outputBatch
                                                                              sections:sections
                                                             isContiguousTailInsertion:(isContiguousTailInsertion && sections.size() == 0)];
                                     }];
  return preparationQueueBatch.ID;
}

- (FBSuspensionControllerState)state
{
  return _suspensionController.state;
}

- (void)setState:(FBSuspensionControllerState)state
{
  _suspensionController.state = state;
}

- (BOOL)hasPendingChanges
{
  return [_suspensionController hasPendingChanges];
}

#pragma mark - Enqueued changes tracking

- (BOOL)isComputingChanges
{
  return !_operationsInPreparationQueueTracker.empty();
}

#pragma mark - Listeners to FBComponentPreparationQueue
- (void)addListener:(id<FBComponentPreparationQueueListener>)listener
{
  [_componentPreparationQueue addListener:listener];
}

- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener
{
  [_componentPreparationQueue removeListener:listener];
}

#pragma mark - FBComponentPreparationQueueDelegate

- (void)_componentPreparationQueueDidPrepareBatch:(NSArray *)batch
                                         sections:(const Sections &)sections
                        isContiguousTailInsertion:(BOOL)isContiguousTailInsertion
{
  CKAssertMainThread();

  Input::Items items;

  for (FBComponentPreparationOutputItem *outputItem in batch) {
    CKArrayControllerChangeType type = [outputItem changeType];
    switch (type) {
      case CKArrayControllerChangeTypeUpdate: {
        items.update([outputItem indexPath], outputItem);
      }
        break;
      case CKArrayControllerChangeTypeInsert: {
        items.insert([outputItem indexPath], outputItem);
      }
        break;
      case CKArrayControllerChangeTypeDelete: {
        items.remove([outputItem indexPath]);
      }
        break;
      default:
        break;
    }
  }

  if (isContiguousTailInsertion) {
    [_suspensionController processTailInsertion:items];
  } else {
    [_suspensionController processChangeset:{sections, items}];
  }
}

#pragma mark - FBSuspensionControllerOutputHandler
- (NSIndexPath *)startingIndexPathForTailChangesetInSuspensionController:(FBSuspensionController *)controller
{
  const NSInteger numberOfSections = [_outputArrayController numberOfSections];
  const NSInteger lastSectionIndex = numberOfSections - 1;
  return [NSIndexPath indexPathForItem:[_outputArrayController numberOfObjectsInSection:lastSectionIndex]
                             inSection:lastSectionIndex];
}

- (void)suspensionController:(FBSuspensionController *)controller
         didDequeueChangeset:(const Input::Changeset &)changeset
                      ticker:(fb_ticker_block_t)ticker
{
  Input::Changeset::Mapper mapper =
  ^id<NSObject>(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    FBComponentPreparationOutputItem *item = (FBComponentPreparationOutputItem *)object;
    FBComponentLifecycleManager *lifecycleManager = [item lifecycleManager];
    FBComponentLifecycleManagerState lifecycleManagerState = [item lifecycleManagerState];
    if (![item isPassthrough]) {
      [lifecycleManager updateWithStateWithoutMounting:lifecycleManagerState];
    }
    return [[FBComponentDataSourceOutputItem alloc] initWithLifecycleManager:lifecycleManager
                                                       lifecycleManagerState:lifecycleManagerState
                                                                     oldSize:[item oldSize]
                                                                       model:[item replacementModel]
                                                                        UUID:[item UUID]];
  };
  auto mappedChangeset = changeset.map(mapper);

  __block BOOL hasUpdateWithHeightChange = NO;
  Input::Items::Enumerator itemEnumerator =
  ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeUpdate) {
      __block NSUInteger i = 0;
      [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *s) {
        FBComponentDataSourceOutputItem *after = (FBComponentDataSourceOutputItem *)objects[i];
        hasUpdateWithHeightChange = !CGSizeEqualToSize([after oldSize], [after lifecycleManagerState].layout.size);
        if (hasUpdateWithHeightChange) {
          *s = YES;
        }
        ++i;
      }];
      if (hasUpdateWithHeightChange) {
        *stop = YES;
      }
    } else if (type == CKArrayControllerChangeTypeInsert || type == CKArrayControllerChangeTypeDelete) {
      hasUpdateWithHeightChange = YES;
      *stop = YES;
    }
  };
  mappedChangeset.enumerate(nil, itemEnumerator);

  [_delegate componentDataSource:self
     changesetIncludesSizeChange:hasUpdateWithHeightChange
             changesetApplicator:^{
    return [_outputArrayController applyChangeset:mappedChangeset];
  }
                          ticker:ticker];
}

#pragma mark - FBComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(FBComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const FBComponentBoundsAnimation &)animation
{
  __block FBComponentDataSourceOutputItem *matchingObject;
  __block NSIndexPath *matchingIndexPath;
  [_outputArrayController enumerateObjectsUsingBlock:^(FBComponentDataSourceOutputItem *object, NSIndexPath *indexPath, BOOL *stop) {
    if (object.lifecycleManager == manager) {
      matchingObject = object;
      matchingIndexPath = indexPath;
      *stop = YES;
    }
  }];
  if (matchingObject) {
    [_delegate componentDataSource:self
            didChangeSizeForObject:matchingObject
                       atIndexPath:matchingIndexPath
                         animation:animation];
  }
}

#pragma mark - FBComponentLifecycleManagerAsynchronousUpdateHandler

- (void)handleAsynchronousUpdateForComponentLifecycleManager:(FBComponentLifecycleManager *)manager
{
  std::pair<id<NSObject>, NSIndexPath *> itemToUpdate = [_inputArrayController firstObjectPassingTest:^BOOL(FBComponentDataSourceInputItem *object, NSIndexPath *indexPath, BOOL *stop) {
    return object.lifecycleManager == manager;
  }];
  // There is a possibility that when we enqueue the udpate, a deletion has already
  // been enqueued for the same item, in this case we won't find a corresponding
  // item in the input array.
  if (itemToUpdate.first && itemToUpdate.second ) {
    Input::Items items;
    items.update(itemToUpdate.second, itemToUpdate.first);
    [self _enqueueChangeset:{items}];
  }
}

#pragma mark - Utilities

static BOOL _indexPathsAreContiguousFromStartingIndexPath(NSSet *indexPaths,
                                                          NSIndexPath *expectedStartingIndexPath)
{
  BOOL contiguous = YES;
  NSInteger section = [expectedStartingIndexPath section];
  NSInteger item = [expectedStartingIndexPath item];
  NSArray *sortedIndexPaths = [[indexPaths allObjects] sortedArrayUsingSelector:@selector(compare:)];
  for (NSIndexPath *indexPath in sortedIndexPaths) {
    BOOL sectionDidIncrement = ([indexPath section] == (section + 1) && [indexPath item] == 0);
    if (sectionDidIncrement) {
      section++;
      item = 0;
      continue;
    }
    BOOL isOneMoreThanPreviousIndexPath = ([indexPath section] == section && [indexPath item] == item++);
    if (!isOneMoreThanPreviousIndexPath) {
      contiguous = NO;
      break;
    }
  }
  return contiguous;
}

/** @return the UUID for a changeset sent to the preparationQueue */
static PreparationBatchID batchID()
{
  CKCAssertMainThread();
  static PreparationBatchID batchID = 0;
  return batchID++;
}

@end
