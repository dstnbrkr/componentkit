// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBSuspensionController.h"

#import <deque>

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKArgumentPrecondition.h>
#import <FBComponentKit/CKAssert.h>

using namespace CK::ArrayController;

struct FBSuspensionControllerChangesetContainer {
  std::shared_ptr<Input::Changeset> changeset;
  BOOL isTailInsertion;
};

@implementation FBSuspensionController
{
  id<FBSuspensionControllerOutputHandler> __weak _outputHandler;
  /**
   When a changeset comes in we always put it at the tail of the inputBuffer.
   We then depending on the state send to the delegate the changeset at the
   front of the buffer (might be the one we just added), the next tail insertion
   or nothing.
   */
  std::deque<FBSuspensionControllerChangesetContainer> _inputBuffer;
  /* YES when a changeset has been sent to the delegate and the delegate didn't signal that it has finished processing it */
  BOOL _changeInProgress;
  FBSuspensionControllerState _state;
}

#pragma mark - Lifecycle

- (instancetype)initWithOutputHandler:(id<FBSuspensionControllerOutputHandler>)outputHandler
{
  CKArgumentPreconditionCheckIf(outputHandler != nil, ([NSString stringWithFormat:@"A delegate must be provided to the suspension controller %@", self]));
  if (self = [super init]) {
    _outputHandler = outputHandler;
    _state = FBSuspensionControllerStateFullySuspended;
    _changeInProgress = NO;
  }
  return self;
}


#pragma mark - Public API

- (void)setState:(FBSuspensionControllerState)state
{
  CKAssertMainThread();
  if (_state != state) {
    _state = state;
    [self _emitNextChange];
  }
}

- (void)processChangeset:(const Input::Changeset &)changeset
{
  CKAssertMainThread();
  _inputBuffer.push_back({std::make_shared<Input::Changeset>(changeset), NO});
  [self _emitNextChange];
}

- (void)processTailInsertion:(const Input::Items &)tailInsertion
{
  CKAssertMainThread();
  _inputBuffer.push_back({std::make_shared<Input::Changeset>(tailInsertion), YES});
  [self _emitNextChange];
}

- (BOOL)hasPendingChanges
{
  CKAssertMainThread();
  return _inputBuffer.empty() ? NO : YES;
}

#pragma mark - Output

- (void)_emitNextChange
{
  if (_changeInProgress) {
    return;
  }

  [self _popNextChangeset:^(const Input::Changeset &changeset, BOOL isOutOfOrderTailInsertion) {
    // Munge the index path for a tail insertion only if it's out of order (i.e not at the front of the buffer).
    // If it is in front of the buffer then it means that the output part of the pipeline should be in a consitent
    // so that we can just apply this change. If it's not then it is an error and we shouldn't hide it by always
    // munging.
    const Input::Changeset &adjustedChangeset = (isOutOfOrderTailInsertion ? _mungeTailInsertion(self, changeset) : changeset);

    _changeInProgress = YES;
    __weak FBSuspensionController *weakSelf = self;
    [_outputHandler suspensionController:self
                     didDequeueChangeset:adjustedChangeset
                                  ticker:^{
                                    CKCAssertMainThread();
                                    [weakSelf _resetChangeInProgressAndEmitChange];
                                  }];
  }];
}

- (void)_resetChangeInProgressAndEmitChange
{
  _changeInProgress = NO;
  [self _emitNextChange];
}

/** Erase the next valid changeset from the buffer and pass it to the processing block */
- (void)_popNextChangeset:(void(^)(const Input::Changeset &changeset, BOOL isOutOfOrderTailInsertion))processingBlock
{
  // Get the iterator to the next valid changeset according to the state
  auto it = nextChangesetForState(_state, _inputBuffer);
  if (it != _inputBuffer.end()) {
    // Grab some state and erage the changeset from the buffer
    std::shared_ptr<Input::Changeset> changeset = it->changeset;
    // If the changeset is a tail insertion and is not at the front of the buffer
    BOOL isOutOfOrderTailInsertion = it->isTailInsertion && it != _inputBuffer.begin();
    _inputBuffer.erase(it);

    if (processingBlock) {
      processingBlock(*changeset, isOutOfOrderTailInsertion);
    }
  }
}

/** Returns an iterator to the next valid changeset according to the current suspension state */
static std::deque<FBSuspensionControllerChangesetContainer>::const_iterator nextChangesetForState(FBSuspensionControllerState state, const std::deque<FBSuspensionControllerChangesetContainer> &inputBuffer)
{
  if (inputBuffer.empty()) {
    return inputBuffer.end();
  }

  switch (state) {
    case FBSuspensionControllerStateNotSuspended: {
      // not suspended we just return the changeset at the front of the buffer
      return inputBuffer.begin();
    }
    case FBSuspensionControllerStateMergeSuspended: {
      // find the first tail insertion traversing the buffer in order
      for (auto it = inputBuffer.begin(); it != inputBuffer.end(); ++it) {
        if (it->changeset->sections.size() > 0) {
          // Section changes are considered unsafe, if we encounter one in the queue
          // then it is unsafe to try and dequeue further changes, even if it is a
          // tail insertion.
          return inputBuffer.end();
        } else if (it->isTailInsertion) {
          return it;
        }
      }
      return inputBuffer.end();
    }
    case FBSuspensionControllerStateFullySuspended: {
      return inputBuffer.end();
    }
  }
}

#pragma mark - Tail insertion munging

/** See `- (NSIndexPath *)startingIndexPathForTailChangesetInSuspensionController:(FBSuspensionController *)controller` */
static Input::Changeset _mungeTailInsertion(FBSuspensionController *self, const Input::Changeset &tailInsertion) {
  __block Input::Items mungedTailInsertion;
  NSIndexPath *startingIndexPath = nil;
  @autoreleasepool {
    startingIndexPath = [self->_outputHandler startingIndexPathForTailChangesetInSuspensionController:self];
  }
  _enumerateInputChangesetForStartingIndexPath(tailInsertion, startingIndexPath, ^(NSIndexPath *adjustedIndexPath, id<NSObject> object) {
    mungedTailInsertion.insert(adjustedIndexPath, object);
  });
  return mungedTailInsertion;
}

/**
 Assumes that -[CKArrayControllerChangeset enumerateUsingBlock:] enumerates in ascending indexPath order.
 creates new indexPaths from startingIndexPath onwards, and accounts for section changes.
 */
static void _enumerateInputChangesetForStartingIndexPath(const Input::Changeset &changeset,
                                                         NSIndexPath *startingIndexPath,
                                                         void(^adjustingBlock)(NSIndexPath *, id<NSObject>))
{
  __block NSInteger section = [startingIndexPath section];
  __block NSInteger item = [startingIndexPath item];
  __block NSInteger s = NSNotFound;

  changeset.enumerate(nil,
                      ^(NSInteger oldSection, NSIndexSet *oldIndexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {
                        __block NSUInteger objectIndex = 0;
                        [oldIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *innerStop) {

                          if (s == NSNotFound) {
                            s = oldSection;
                          } else {
                            if (s != oldSection) {
                              s = oldSection;
                              section++;
                              item = 0;
                            }
                          }

                          NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:item++ inSection:section];
                          id<NSObject> object = objects[objectIndex++];
                          adjustingBlock(newIndexPath, object);
                        }];
                      });
}

@end
