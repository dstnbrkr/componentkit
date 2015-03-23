---
title: Use CKComponentDataSource directly
layout: docs
permalink: /docs/use-ckcomponendatasource-directly.html
---

`CKCollectionViewDataSource` should be sufficient for most uses of ComponentKit with a collection view. If you need more control or want to use a components datasource with a different type of views you can still use `CKComponentDataSource` directly.

Here is an example of usage of `CKComponentDataSource` directly with a UIViewController. You can also go inspect the source code of `CKCollectionViewDataSource` and see how it's done.

## Example: Use it in your controller to power a TableView

`ComponentsTableViewController.h`

```objc++
{% raw  %}
#import <UIKit/UIKit.h>

@interface  ComponentsTableViewController : UIViewController
@end
{% endraw  %}
```

`ComponentTableViewController.mm`

```objc++
{% raw  %}
#import "ComponentTableViewController.h"

using namespace CK::ArrayController;

@interface SimpleTableViewController () <
CKComponentProvider,
CKComponentDataSourceDelegate,
UITableViewDataSource,
UITableViewDelegate
>
@end

@implementation ComponentTableViewController
{
  UITableView *_tableView;
  CKComponentDataSource *_componentDataSource;
  CKSizeRange _constrainedSize;
}

- (void)loadView
{
  _tableView = [[UITableView alloc] init];
  [self setView:_tableView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kReuseIdentifier];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _componentDataSource = [[CKComponentDataSource alloc] initWithComponentProvider:[self class]
                                                                          context:nil
                                                                          decider:[[CKComponentConstantDecider alloc] initWithEnabled:@YES]];
  _componentDataSource.delegate = self;
  _componentDataSource.state = CKSuspensionControllerStateNotSuspended;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

#pragma mark - UITableViewDatasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Grab the output item
  CKComponentDataSourceOutputItem *outputItem = [_componentDataSource objectAtIndexPath:indexPath];
	// Dequeue a table view cell
  UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:kReuseIdentifier];
	// Get the lifecycle manager out of the output item
  CKComponentLifecycleManager *lifecycleManager = [outputItem lifecycleManager];
	// Mount the corresponding component tree in the container view
  [lifecycleManager attachToView:[cell componentContainerView]];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [[[_componentDataSource objectAtIndexPath:indexPath] lifecycleManager] size].height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [_componentDataSource numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [_componentDataSource numberOfObjectsInSection:section];
}

#pragma mark - CKComponentDatasourceDelegate

- (void)componentDataSource:(CKComponentDataSource *)componentDataSource
changesetIncludesSizeChange:(BOOL)changesetIncludesSizeChange
        changesetApplicator:(ck_changeset_applicator_t)changesetApplicator
                     ticker:(ck_ticker_block_t)ticker
{
  [_tableView beginUpdates];
  const auto &changeset = changesetApplicator();
  applyChangesetToTableView(changeset, _tableView);
  [_tableView endUpdates];
  ticker();
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(NSString *)model context:(id<NSObject>)context
{
  //TODO according to your model
}

static void applyChangesetToTableView(const Output::Changeset &changeset, UITableView *tableView)
{
  Sections::Enumerator sectionsEnumerator = ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      [tableView deleteSections:sectionIndexes withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [tableView insertSections:sectionIndexes withRowAnimation:UITableViewRowAnimationFade];
    }
  };

  Output::Items::Enumerator itemEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    NSIndexPath *indexPath = change.indexPath.toNSIndexPath();
    if (type == CKArrayControllerChangeTypeDelete) {
      [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
  };

  changeset.enumerate(sectionsEnumerator, itemEnumerator);
}

@end
{% endraw  %}
```
