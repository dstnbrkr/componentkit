---
title: Dive Deeper
layout: docs
permalink: /docs/ckcomponentdatasource-explained.html
---

<img src="/static/images/datasource.png" alt="Overwiew of the datasource" width ="583" height="672">

<div class="note">
  <p>
    We will use "list view" to refer to either a <code>UICollectionView</code> or a <code>UITableView</code>
  </p>
</div>

1. A changeset is enqueued in `CKComponentDataSource` (maybe proxied by CKCollectionViewDataSource or another adapter), the CKComponentDataSource updates its internal input state.
2. Changes are asynchronously enqueued in the preparation queue and processed in the background. Each model in the changeset will get it's component tree generated and laid out by calling the `componentForModel:` function on the componentProvider.
3. Once the components are computed the output changeset is processed :
    1. The output changeset is applied to the internal output state of `CKComponentDataSource`
    2. The delegate of the `CKComponentDataSource` is signaled with the changeset.
    3. From this changeset it triggers a batch update corresponding to the list view it has a reference to. This is the way `CKComponentCollectionViewDataSource` is setup, when the output changeset is received it will call `- performBatchUpdates:completion:` on the collection view with the right mutation calls.
4. The list view will then request updated content, either immediately if some updated content is visible or later when the updated content will become visible while scrolling :
    1. Either `-cellForRowAtIndexPath:` or `cellForItemAtIndexPath:` will be called by the list view on its datasource.
    2. The datasource calls the `CKComponentDataSource` to get an handle (a `CKComponentLifeCycleManager` in this case) on the most up to date component tree.
    3. The `CKComponentLifeCycleManager` is then returned to the list view datasource that will mount the component tree on the cell.
    4. Which is then returned to the list view that will display it.
