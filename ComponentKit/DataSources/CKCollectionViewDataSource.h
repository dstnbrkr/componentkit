// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKArrayControllerChangeset.h>

#import <FBComponentKit/CKMacros.h>
#import <FBComponentKit/FBComponentHostingCell.h>
#import <FBComponentKit/FBDimension.h>
#import <FBComponentKit/FBSuspensionController.h>

@protocol FBComponentProvider;
@protocol CKSupplementaryViewDataSource;

typedef void(*CKCellConfigurationFunction)(UICollectionViewCell *cell, NSIndexPath *indexPath, id<NSObject> model);

/**
 This class is an implementation of a `UICollectionViewDataSource` that can be used along with components. For each set of changes (i.e insertion/deletion/update
 of items and/or insertion/deletion of sections) the datasource will compute asynchronously on a background thread the corresponding component trees and then
 apply the corresponding UI changes to the collection view leveraging automatically view reuse.

 Doing so this reverses the traditional approach for a `UICollectionViewDataSource`. Usually the controller layer will *tell* the `UICollectionView` to update and
 the  will then *ask* the datasource for the data. Here the model is reversed and more Reactive, from an external prospective, the datasource is *told* what
 changes to apply and then *tell* the collection view to apply the corresponding changes :
 - This datasource first takes in a set of commands. e.g: "Insert a row at index 1 in section 0 representing the model X", "Update row at index 2 in section 2 with
 model Y", "Insert section at index 2"
 - The component trees and layouts corresponding to each of the models are then computed asynchronously on a background thread to avoid consuming unnecessarily
 cycles on the main thread. Which is particularly important to preserve scroll performances.
 - Finally, the collection view is mutated - using `performBatchUpdates:` - and each of the component trees are mounted (i.e the UI corresponding to the
 component tree is displayed) on their respective cells. Due to the declarative nature of components, not only the system can automatically handle reuse
 but it also can do it at a finer grained level. No more cumbersome implementations of `prepareForReuse` !
 */
@interface CKCollectionViewDataSource : NSObject

/**
 Designated initializer

 @param componentProvider Class implementing the pure function turning a model into components.@see FBComponentProvider.
 @param context Will be passed to your componentProvider. @see FBComponentProvider.
 @param cellConfigurationFunction Pointer to a function applying custom configuration to the UICollectionViewCell where the component
 tree is mounted. We use a function pointer and not a block to enforce the purity of said function.
 @warning Reuse won't be handled for you when modifying view parameters through this function, reserve it for small configurations. Cells
 are just a thin container for your UI defined using components so heavy configuration of the cell shouldn't be needed.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     componentProvider:(Class<FBComponentProvider>)componentProvider
                               context:(id)context
             cellConfigurationFunction:(CKCellConfigurationFunction)cellConfigurationFunction;

/**
 Method to enqueue commands in the datasource.

 @param changeset The set of commands to apply to the collection view, e.g :
 `
 ArrayController::Sections sections;
 ArrayController::Input::Items items;
 sections.insert(1); // Insert section at index 1
 items.insert({0,1}, modelX); // Insert a row at index 0 in section 1 containing the UI corresponding to modelX
 item.udpate({0,0}, modelY); // Update row at index 0 in section 0 using modelY
 [_dataSource enqueueChangeset:{sections, items} constrainedSize:{{0,0},{50,50}}];

 @warning In a batch update:
 - deletes are applied first relatively to the index space before the batch update
 - inserts are then applied relatively to the "post deletion" index space:
 https://developer.apple.com/library/ios/documentation/UIKit/Reference/UICollectionView_class/#//apple_ref/occ/instm/UICollectionView/performBatchUpdates:completion:
 `
 @param constrainedSize The constrained size {{minWidth, minHeight},{maxWidth, maxHeight}} that will be used to compute
 your component tree.
 */
- (void)enqueueChangeset:(const CK::ArrayController::Input::Changeset &)changeset
         constrainedSize:(const FBSizeRange &)constrainedSize;

/**
 @return The model associated with a certain index path in the collectionView.

 As stated above components are generated asynchronously and on a backgorund thread. This means that a changeset is enqueued
 and applied asynchronously when the corresponding component tree is generated. For this reason always use this method when you
 want to retrieve the model associated to a certain index path in the table view (e.g in didSelectRowAtIndexPath: )
 */
- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 @return The layout size of the component tree at a certain indexPath. Use this to access the component sizes for instance in a
 `UICollectionViewLayout(s)` or in a `UICollectionViewDelegateFlowLayout`.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

@property (readonly, nonatomic, strong) UICollectionView *collectionView;
/**
 Supplementary views are not handled with components; the datasource will forward any call to
 `collectionView:viewForSupplementaryElementOfKind:atIndexPath` to this object.
 */
@property (readwrite, nonatomic, weak) id<CKSupplementaryViewDataSource> supplementaryViewDataSource;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end

/**
 The supplementaryViewDataSource can't just conform to @see UICollectionViewDataSource as this protocol includes required
 methods that are already implemented by this class. Hence we duplicate the part of the protocol related to supplementary views
 and wrap it in our internal one.
 */
@protocol CKSupplementaryViewDataSource<NSObject>

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath;

@end
