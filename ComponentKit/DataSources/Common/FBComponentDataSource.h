// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKArrayControllerChangeType.h>
#import <FBComponentKit/CKArrayControllerChangeset.h>

#import <FBComponentKit/CKMacros.h>
#import <FBComponentKit/FBComponentPreparationQueueTypes.h>
#import <FBComponentKit/FBComponentSuspendable.h>
#import <FBComponentKit/FBDimension.h>
#import <FBComponentKit/FBSuspensionController.h>

@class FBComponentDataSourceOutputItem;
@class FBComponentLifecycleManager;

@protocol FBComponentDataSourceDelegate;
@protocol FBComponentPreparationQueueListener;
@protocol FBComponentProvider;
@protocol FBComponentDeciding;

class FBComponentBoundsAnimation;

/**
 Given an input of model objects, we transform them asynchronously into instances of FBComponentLifecycleManagers.
 Implementations of UITableViewDataSource/UITableViewDelegate should defer to methods such as
 -numberOfObjectsInSection and -objectAtIndexPath: to implement -tableView:numberOfRowsInSection: and
 -tableView:cellForRowAtIndexPath:.

 In response to the deleagte methods, the delegate should calll -[UITableView beingUpdates], -endUpdates and mutate the
 number of rows in said table view.
 */
@interface FBComponentDataSource : NSObject <
FBComponentSuspendable
>

typedef FBComponentLifecycleManager *(^FBComponentLifecycleManagerFactory)(void);

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

/**
 Designated initializer.
 @param componentProvider See @protocol(FBComponentProvider)
 @param context Passed to methods exposed by @protocol(FBComponentProvider).
 @param decider Allows for the data source to skip the creation of components. This is a compatibility hack while we
 progressively move things over to components.
 @returns An instance of FBComponentDataSource.
 */
- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<FBComponentDeciding>)decider;

/**
 See FBComponentDataSourceDelegate.
 */
@property (readwrite, nonatomic, weak) id<FBComponentDataSourceDelegate> delegate;

/**
 The same factory passed into the initializer.
 Used by `FBComponent{Table|Collection}ViewDataSource` to construct a lifecycle manager for placeholder components when
 component hierarchies are "borrowed" from the table or collection view.
 */
@property (readonly, nonatomic, copy) FBComponentLifecycleManagerFactory lifecycleManagerFactory;

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (FBComponentDataSourceOutputItem *)objectAtIndexPath:(NSIndexPath *)indexPath;

- (PreparationBatchID)enqueueChangeset:(const CK::ArrayController::Input::Changeset &)changeset constrainedSize:(const FBSizeRange &)constrainedSize;

/**
 Generates a changeset of update() commands for each object in the data source. The changeset is then enqueued and
 processed asynchronously as normal.

 This can be useful when responding to changes to global state (for example, changes to accessibility) so we can reflow
 all component hierarchies managed by the data source.
 */
- (void)enqueueReload;

typedef void(^FBComponentDataSourceEnumerator)(FBComponentDataSourceOutputItem *, NSIndexPath *, BOOL *);

- (void)enumerateObjectsUsingBlock:(FBComponentDataSourceEnumerator)block;

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)section usingBlock:(FBComponentDataSourceEnumerator)block;

typedef BOOL(^FBComponentDataSourcePredicate)(FBComponentDataSourceOutputItem *, NSIndexPath *, BOOL *);

/**
 @predicate Returning YES from the predicate will halt searching. Passing a nil predicate will return a {nil, nil} pair.
 @returns The object passing `predicate` and its corresponding index path. Nil in both fields indicates nothing passed.
 This will always return both fields as nil or non-nil.
 */
- (std::pair<FBComponentDataSourceOutputItem *, NSIndexPath *>)firstObjectPassingTest:(FBComponentDataSourcePredicate)predicate;

/**
 This is O(N).
 */
- (std::pair<FBComponentDataSourceOutputItem *, NSIndexPath *>)objectForUUID:(NSString *)UUID;

/**
 @return YES if the datasource has changesets currently enqueued.
 */
- (BOOL)isComputingChanges;

/**
 Allows adding/removing listeners to hear events on the FBComponentPreparationQueue, which is wrapped within FBComponentDataSource.
 */
- (void)addListener:(id<FBComponentPreparationQueueListener>)listener;
- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener;

@end

typedef CK::ArrayController::Output::Changeset(^fb_changeset_applicator_t)(void);

@protocol FBComponentDataSourceDelegate <NSObject>

/**
 Called when a new changeset is ready to be applied

 @param changesetApplicator A block that when executed returns the changeset. You can then map over this changeset to apply it to a TableView
 or CollectionView.
 @param ticker The ticker has to be called to signal the componentDataSource that the caller is ready to receive a new changeset. The ticker is here
 originally to work around a bug in UICollectionViews. Applying a new changeset to a collectionView while the previous one has not been completely applied
 could cause the collectionView to lose track of its internal state and have duplicate entries, for this reason and when a changeset is aplied to a
 collectionView the ticker should be called in the completion block of -(void)performBatchUpdates:Completion:
 */
- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
changesetIncludesSizeChange:(BOOL)changesetIncludesSizeChange
        changesetApplicator:(fb_changeset_applicator_t)changesetApplicator
                     ticker:(fb_ticker_block_t)ticker;

/**
 Sent when the size of a given component has changed due to a state update (versus a model change).
 The component's view (if any) has already been updated; you will need to signal the component's parent view to update
 its layout (e.g. calling -invalidateLayout on a UICollectionView's layout).
 */
- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
     didChangeSizeForObject:(FBComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const FBComponentBoundsAnimation &)animation;

@end
