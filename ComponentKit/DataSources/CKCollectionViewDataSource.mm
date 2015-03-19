// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKCollectionViewDataSource.h"

#import <objc/runtime.h>

#import <FBComponentKit/CKArgumentPrecondition.h>
#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "FBComponent.h"
#import "FBComponentConstantDecider.h"
#import "FBComponentDataSource.h"
#import "FBComponentDataSourceOutputItem.h"
#import "FBComponentLifecycleManager.h"

using namespace CK::ArrayController;

@interface CKCollectionViewDataSource () <
UICollectionViewDataSource,
UICollectionViewDelegate,
FBComponentDataSourceDelegate
>
@end

@implementation CKCollectionViewDataSource
{
  FBComponentDataSource *_componentDataSource;
  CKCellConfigurationFunction _cellConfigurationFunction;
}

CK_FINAL_CLASS([CKCollectionViewDataSource class]);

#pragma mark - Lifecycle

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                     componentProvider:(Class<FBComponentProvider>)componentProvider
                               context:(id)context
             cellConfigurationFunction:(CKCellConfigurationFunction)cellConfigurationFunction;
{
  self = [super init];
  if (self) {
    _componentDataSource = [[FBComponentDataSource alloc] initWithComponentProvider:componentProvider
                                                                            context:context
                                                                            decider:[[FBComponentConstantDecider alloc] initWithEnabled:YES]];
    _cellConfigurationFunction = cellConfigurationFunction;
    _componentDataSource.delegate = self;
    _componentDataSource.state = FBSuspensionControllerStateNotSuspended;
    _collectionView = collectionView;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifier];
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

#pragma mark - Changesets

- (void)enqueueChangeset:(const CK::ArrayController::Input::Changeset &)changeset constrainedSize:(const FBSizeRange &)constrainedSize
{
  [_componentDataSource enqueueChangeset:changeset constrainedSize:constrainedSize];
}

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[_componentDataSource objectAtIndexPath:indexPath] model];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[[_componentDataSource objectAtIndexPath:indexPath] lifecycleManager] size];
}

#pragma mark - UICollectionViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.collection_view_data_source.cell";

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  FBComponentDataSourceOutputItem *outputItem = [_componentDataSource objectAtIndexPath:indexPath];
  UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  if (_cellConfigurationFunction) {
    _cellConfigurationFunction(cell, indexPath, [outputItem model]);
  }
  FBComponentLifecycleManager *lifecycleManager = [outputItem lifecycleManager];
  [lifecycleManager attachToView:[cell contentView]];
  return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return [_componentDataSource numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [_componentDataSource numberOfObjectsInSection:section];
}

#pragma mark - Supplementary views datasource

- (void)setSupplementaryViewDataSource:(id<CKSupplementaryViewDataSource>)supplementaryViewDataSource
{
  if (supplementaryViewDataSource != _supplementaryViewDataSource) {
    _supplementaryViewDataSource = supplementaryViewDataSource;
    // Reset the datasource so that the collection view internal caches are purged
    _collectionView.dataSource = nil;
    _collectionView.dataSource = self;
  }
}

/** `collectionView:viewForSupplementaryElementOfKind:atIndexPath:` is manually forwarded to an optional supplementaryTableViewDataSource. */
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
  return [_supplementaryViewDataSource collectionView:collectionView
                    viewForSupplementaryElementOfKind:kind
                                          atIndexPath:indexPath];
}

/**
 Also override respondsToSelector so that from the collection view point of view talking directly to its datasource (as it would normally),
 is entirely isomorphic than talking to the `supplementaryViewDataSource`.
 This is important because the default behavior of the collection view could be impacted by the fact that wether or not its datasource responds
 to a certain selector.
 */
- (BOOL)respondsToSelector:(SEL)aSelector
{
  if (aSelector == @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)) {
    // In our protocol `collectionView:viewForSupplementaryElementOfKind:atIndexPath:` is required so we can just check for the
    // presence of the _supplementaryViewDataSource.
    return _supplementaryViewDataSource != nil;
  }
  return [super respondsToSelector:aSelector];
}

#pragma mark - FBComponentDatasourceDelegate

- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
changesetIncludesSizeChange:(BOOL)changesetIncludesSizeChange
        changesetApplicator:(fb_changeset_applicator_t)changesetApplicator
                     ticker:(fb_ticker_block_t)ticker
{
  [_collectionView performBatchUpdates:^{
    const auto &changeset = changesetApplicator();
    applyChangesetToCollectionView(changeset, _collectionView);
  } completion:^(BOOL finished) {
    // Doing a batch updates before the previous one is entirely processed could mess up
    // the internal state of the collection view. The ticker signals that the datasource
    // is ready to receive a new changeset.
    ticker();
  }];
}

- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
     didChangeSizeForObject:(FBComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const FBComponentBoundsAnimation &)animationDuration
{
  [[_collectionView collectionViewLayout] invalidateLayout];
}

#pragma mark - Private

static void applyChangesetToCollectionView(const Output::Changeset &changeset, UICollectionView *collectionView)
{
  NSMutableArray *itemRemovalIndexPaths = [[NSMutableArray alloc] init];
  NSMutableArray *itemInsertionIndexPaths = [[NSMutableArray alloc] init];
  NSMutableArray *itemUpdateIndexPaths = [[NSMutableArray alloc] init];
  Output::Items::Enumerator itemEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    NSIndexPath *indexPath = change.indexPath.toNSIndexPath();
    switch (type) {
      case CKArrayControllerChangeTypeDelete:
        [itemRemovalIndexPaths addObject:indexPath];
        break;
      case CKArrayControllerChangeTypeInsert:
        [itemInsertionIndexPaths addObject:indexPath];
        break;
      case CKArrayControllerChangeTypeUpdate:
        [itemUpdateIndexPaths addObject:indexPath];
        break;
      default:
        FBCFailAssert(@"Unsupported change type for items: %d", type);
        break;
    }
  };

  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (sectionIndexes.count > 0) {
      switch (type) {
        case CKArrayControllerChangeTypeDelete:
          [collectionView deleteSections:sectionIndexes];
          break;
        case CKArrayControllerChangeTypeInsert:
          [collectionView insertSections:sectionIndexes];
          break;
        default:
          FBCFailAssert(@"Unsuported change type for sections %d", type);
          break;
      }
    }
  };

  changeset.enumerate(sectionsEnumerator, itemEnumerator);
  if (itemRemovalIndexPaths.count > 0) {
    [collectionView deleteItemsAtIndexPaths:itemRemovalIndexPaths];
  }
  if (itemUpdateIndexPaths.count > 0) {
    [collectionView reloadItemsAtIndexPaths:itemUpdateIndexPaths];
  }
  if (itemInsertionIndexPaths.count > 0) {
    [collectionView insertItemsAtIndexPaths:itemInsertionIndexPaths];
  }
}

@end
