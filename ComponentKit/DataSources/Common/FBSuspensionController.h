// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/CKArrayControllerChangeType.h>
#import <FBComponentKit/CKArrayControllerChangeset.h>

#import <FBComponentKit/CKMacros.h>

/** See -[FBSuspensionController setState:] */
typedef NS_ENUM(NSUInteger, FBSuspensionControllerState) {
  FBSuspensionControllerStateNotSuspended,
  FBSuspensionControllerStateMergeSuspended,
  FBSuspensionControllerStateFullySuspended,
};

@class FBSuspensionController;

typedef void (^fb_ticker_block_t)();

/**
 FBSuspensionController doesn't hold a reference to eithe the "input" or "output" array. Instead it's a very small
 adaptor that sits between them in a given pipeline. After applying changes to an input array, clients are expected
 to pass the changes through an instance of FBSuspensionController.

 The suspension controller's state determines what/when it should dequeue/emit changes and the client is responsible for
 applying them to the "output" array.
 */
@protocol FBSuspensionControllerOutputHandler<NSObject>

/**
 Called by FBSuspensionController prior to dequeueing when in the `FBSuspensionControllerStateMergeSuspended`
 state. When in this state the changeset will only contain contiguous inserted items at the tail end of the data set.

 This changeset was enqueued with indexes in the "input" array space. By implementing this, we can convert them
 into the "output" array space such that all calls to -suspensionController:didDequeueChangesetGroup: are correctly
 converted and can simply be applied.

 @returns An index path. When the changeset is dequeued, the zeroth element in the changeset will have this index path.
 In doing so the dequeued changeset can be appeneded to the "output" array without further changes to the index paths
 for the inserted items. i.e. For an output array with a trailing object with index path {.row = 3, section = 4} you may
 return {.row = 4, section = 4} or {.row = 0, section = 5}.
 */
- (NSIndexPath *)startingIndexPathForTailChangesetInSuspensionController:(FBSuspensionController *)controller;

/**
 Called whenever the suspension controller dequeues a changeset. Clients should apply the change to the "output" array.
 */
- (void)suspensionController:(FBSuspensionController *)controller
         didDequeueChangeset:(const CK::ArrayController::Input::Changeset &)changeset
                      ticker:(fb_ticker_block_t)ticker;

@end

/**
 Adaptor that allows us to regulate the order of changes that are applied to an array. Clients are expected to have
 own one "input" array and one "output" array, where the "output" array will eventually reflect the state of the input
 array.

 With the exception of tail insertions that may preempt all other enqueued changes, all changes are dequeued FIFO.

 See -state.
 */
@interface FBSuspensionController : NSObject

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 FBSuspensionController must be initialized with a non nil delegate and is initialy placed in
 an FBSuspensionControllerStateFullySuspended state.

 @param outputHandler Object receiving changesets from the suspension controller, held weakly by the suspension controller
 */
- (instancetype)initWithOutputHandler:(id<FBSuspensionControllerOutputHandler>)outputHandler NS_DESIGNATED_INITIALIZER;

/**
 Determines how the controller spits out (emits) any enqueued changes. When suspended, all changes are queued up. When
 not suspended, all queued changes are emitted and no further queuing takes place until the state is changed.

 When "merge suspended" we allow insertions at the tail of our dataset to be emitted while other changes remain queued.
 However once we have changes enqueued such that keeping a consistent state becomes hard to manage, we just enqueue
 everything until the receiver is no longer suspended.
 */
@property (readwrite, nonatomic, assign) FBSuspensionControllerState state;

@property (readwrite, nonatomic, assign) BOOL hasPendingChanges;

/**
 @param changeset The insertions, deletions and updates which should be enqueued for emission from the controller
 at a later date. If the group contains only insertions at the tail of your dataset they are not treaded as candiates
 for immediate emission when MergeSuspended. Those should be passed to -processTailInsertion instead. Without client
 code providing such a hint, we can't reliably inspect the group to determine how to treat a changeset.
 */
- (void)processChangeset:(const CK::ArrayController::Input::Changeset &)changeset;

/**
 @param The insertions that become candidates for immediate emission. The receiver still reserves the right to enqueue
 them when "merge suspended".
 */
- (void)processTailInsertion:(const CK::ArrayController::Input::Items &)tailInsertion;

@end
