// Copyright 2004-present Facebook. All Rights Reserved.

#import <memory>

#import <Foundation/Foundation.h>

#import <FBComponentKit/CKArrayControllerChangeset.h>

/**
 Manages an array of objects bucketed into sections. Suitable for using to manage the backing data for a UITableView
 or UICollectionView.

 The array controller is mutated by constructing a list of commands: insert, remove, update, which are then applied in
 a single "transaction" to the array controller. In response to a mutation, the array controller reutrns a list of
 changes that can be used to mutate a UITableView or UICollectionView.

 We make only minimal attempts to ensure that the indexes (index paths) passed are at all "valid", duplicate commands
 will throw NSInvalidArgumentExceptions. Out-of-bounds access, even with commands passed to -applyChangeset: will also
 throw.

 We've wholesale copied the contract of UITableView mutations (because it's simple to implement and you might already
 know it). See -applyChangeset:

 See also CKArrayControllerChangeset.h.
*/
@interface FBSectionedArrayController : NSObject

- (NSInteger)numberOfSections;

- (NSInteger)numberOfObjectsInSection:(NSInteger)section;

- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath;

typedef void (^FBSectionedArrayControllerEnumerator)(id<NSObject> object, NSIndexPath *indexPath, BOOL *stop);

/**
 Enumerates over all items in ascending order of index path.
 @param enumerator A block invoked for each item in the receiver.
 */
- (void)enumerateObjectsUsingBlock:(FBSectionedArrayControllerEnumerator)enumerator;

/**
 Enumerates over all items in the given section in ascending order of index path.
 @param enumerator A block invoked for each item in the section in the receiver.
 */
- (void)enumerateObjectsInSectionAtIndex:(NSInteger)sectionIndex usingBlock:(FBSectionedArrayControllerEnumerator)enumerator;

typedef BOOL(^FBSectionedArrayControllerPredicate)(id<NSObject>, NSIndexPath *, BOOL *);

- (std::pair<id<NSObject>, NSIndexPath *>)firstObjectPassingTest:(FBSectionedArrayControllerPredicate)predicate;

/**
 We seem to be in the habit of hiding C++ behind things that make it look more C-like to clients.
 */
typedef const CK::ArrayController::Input::Changeset& CKArrayControllerInputChangeset;
typedef CK::ArrayController::Output::Changeset CKArrayControllerOutputChangeset;

/**
 Iterates over the input commands and changes our internal sections array accordingly.

 The indexes in the input changeset are applied to the reciever in the following order:

 1) item updates
 2) item removals
 3) section removals
 4) section insertions
 5) item insertions

 To do so:
 1) index paths for updates and removals MUST be relative to the initial state of the array controller.
 2) index paths for insertions MUST be relative post-application of removal operations.

 The obvious side-effect of this:
 1) Updating an item and subsequently removing the section in which the item resides is wasteful.

 @param changeset The commands (create, update, delete) to apply to our array controller.
 @returns A changeset that describes operations that we can directly apply to a UITableView or UICollectionView.
 */
- (CKArrayControllerOutputChangeset)applyChangeset:(CKArrayControllerInputChangeset)changeset;

@end
