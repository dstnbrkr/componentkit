// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentDataSourceTestDelegate.h"

#import <FBComponentKit/FBComponentDataSource.h>
#import <FBComponentKit/FBComponentDataSourceOutputItem.h>

using namespace CK::ArrayController;

@implementation FBComponentDataSourceTestDelegateChange

- (BOOL)isEqual:(id)object
{
  return FBCompareObjectEquality(self, object, ^BOOL (FBComponentDataSourceTestDelegateChange *change, FBComponentDataSourceTestDelegateChange *changeToCompare) {
    return (
            FBObjectIsEqual(change.dataSourcePair, changeToCompare.dataSourcePair) &&
            FBObjectIsEqual(change.oldDataSourcePair, changeToCompare.oldDataSourcePair) &&
            change.changeType == changeToCompare.changeType &&
            FBObjectIsEqual(change.beforeIndexPath, changeToCompare.beforeIndexPath) &&
            FBObjectIsEqual(change.afterIndexPath, changeToCompare.afterIndexPath)
    );
  });
}

@end

//TODO(#4048670): The delegate should have a block based API that the unit tests can then use.
@implementation FBComponentDataSourceTestDelegate {
  NSMutableArray *_changes;
}

- (id)init
{
  if (self = [super init]) {
    _changes = [[NSMutableArray alloc] init];
    _changeCount = 0;
  }
  return self;
}

- (void)reset
{
  [_changes removeAllObjects];
  _changeCount = 0;
}

- (NSArray *)changes
{
  return _changes;
}

- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
changesetIncludesSizeChange:(BOOL)changesetIncludesSizeChange
        changesetApplicator:(fb_changeset_applicator_t)changesetApplicator
                     ticker:(fb_ticker_block_t)ticker
{
  const auto &changeset = changesetApplicator();

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *indexes, CKArrayControllerChangeType type, BOOL *stop) {};

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {

    FBComponentDataSourceTestDelegateChange *delegateChange = [[FBComponentDataSourceTestDelegateChange alloc] init];
    delegateChange.dataSourcePair = change.after;
    delegateChange.oldDataSourcePair = change.before;
    delegateChange.beforeIndexPath = (type == CKArrayControllerChangeTypeInsert) ? nil : change.indexPath.toNSIndexPath();
    delegateChange.afterIndexPath = (type == CKArrayControllerChangeTypeDelete) ? nil : change.indexPath.toNSIndexPath();
    delegateChange.changeType = type;
    [_changes addObject:delegateChange];

  };

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  _changeCount++;
  if (_onChange) {
    _onChange(_changeCount);
  }

  ticker();
}

- (void)componentDataSource:(FBComponentDataSource *)componentDataSource
     didChangeSizeForObject:(FBComponentDataSourceOutputItem *)object
                atIndexPath:(NSIndexPath *)indexPath
                  animation:(const FBComponentBoundsAnimation &)animation
{
}

@end
