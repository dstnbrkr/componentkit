---
title: Gotchas
layout: docs
permalink: /docs/datasource-gotchas.html
---


## Lifecycle

The lifecycle of the datasource should match the life-cyle of the collection view or table view it is used with. You might otherwise end up with the content of your list view being out of sync with the internal state of the datasource and this most probably will cause a crash eventually.

## The datasource involves asynchronous operations

**Each changeset is computed asynchronously** by `CKComponentDatasource`, therefore the corresponding changes are not reflected immediately on the corresponding `UITableView` or `UICollectionView` and it is important to be careful about sources of data being out of sync.

### Always ask the datasource for the model corresponding to an index path

The datasource maintains an internal data-structure which is the only source of truth for the corresponding `UICollectionView` or `UITableView`. For this reason you should query the datasource to get information associated to a certain indexPath, any other source of data may be out of sync with the current state of the list view.

For instance to access the model associated to a certain index path using a `CKCollectionViewDataSource` you can use :

```objc++
[datasource objectAtindexPath:indexPath];
```

Now let's look at what could go wrong if we query another source of data.

{% highlight objc++ cssclass=redhighlight %}  
{% raw  %}
@implementation MyAwesomeController {
    CKComponentCollectionViewDataSource *_datasource;
    NSMutableArray *_listOfModels;
}

- (void)insertAtHead:(id)model {
// We first add the new model (B) at the beginning of _listOfModels which already contained (A)
    // [A] -> [B, A]
  [_listOfModels insertObject:model atIndex:0];
  CKArrayControllerInputItems items;
  Items.insert({0, 0});
  // Enqueue the changeset asynchronously in the datasource
  [_datasource enqueueChangeset:{{}, items}];
}

- (void)didSelectitemAtIndexPath:(NSIndexPath *)indexPath {
// At the same time the user taps on the cell that represents A, and that is still located at the indexPath (0,0)
// as the changeset has not finished computing yet.
// Ouch we actually get B, list of models and the collection view are out of sync
[_listOfModels objectAtIndex:indexPath.row];
// [_datasource modelForItemAtIndexPath:indexPath] would have properly returned A
}
{% endraw  %}
{% endhighlight %}

### Don't ask the the list view for the position of the next insertion

The list view gives you the current state of what is displayed on the screen, but it doesn't include what is potentially currently being computed in the background. To get this information you need to maintain state that is updated at the same time as a changeset is enqueued.

Let's look at this buggy code.

{% highlight objc++ cssclass=redhighlight %}
{% raw  %}
@implementation MyAwesomeController {
    CKComponentCollectionViewDataSource *_datasource;
    NSMutableArray *_listOfModels;
}

- (void)insertAtTail:(id)model {
// We first add the new model (C) at the end of _listOfModels which already contains (A) et (B)
    // [A, B] -> [A, B, C]
  [_listOfModels addObject:model];
  CKArrayControllerInputItems items;
  // Only A is in the tableView, the components for B are still computed in the background
  // so numberOfItemsInSection returns 1, C will be inserted at index 1 and we will end up
  // with a list view displaying [A, C, B]
  Items.insert({0, _datasource.collectionView numberOfItemsInSection});
  // Items.insert({0, [_listOfModels count] ? [_listOfModels count] -1 : 0}); would have inserted properly C at index 2
  // Enqueue the changeset asynchronously in the datasource
  [_datasource enqueueChangeset:{{}, items}];
}
{% endraw  %}
{% endhighlight %}