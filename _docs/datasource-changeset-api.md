---
title: Changeset API
layout: docs
permalink: /docs/datasource-changeset-api.html
---

Changesets are how you interact with the datasource, they allow you to "enqueue" sets of commands and have them processed by the datasource.


These commands can be seen as a sentence with three parts :

1. **action** (insert/delete/udpate for items, insert/delete for sections)
2. **position specifier** (indexPath for items, index for sections)
3. **model** (that will be used to compute the components)

Here is some sample code, showing how to create a changeset - As you can see changesets are a c++ structure.

```objc++
CKArrayControllerInputItems items;
// Insert an item at index 0 in section 0 and compute for @"Hello"
items.insert({0, 0}, @"Hello");
// Update the item at index 1 in section 0 and update it with the component computed for @"World"
items.update({0, 1}, @"World");
// Delete the itm at index 2 in section 0, no need for a model here :)
Items.delete({0, 2});

Sections sections;
sections.insert(0);
sections.insert(2);
sections.insert(3);

[datasource enqueueChangeset:{sections, items}];
```

## Order in which changes are applied.

The order in which commands are added to the changeset doesn't define the order in which they will internally be applied to the `CKComponentDataSource` and then to a `UITableView` or `UICollectionView`. The order of application follow the same rules as for batch updates on UITableView or UICollectionView :

- **Deletions and Updates are applied first using the current index space.**
- **Insertions are then applied in the index post deletions and updates (updates obviously won't modify the index space though).**

You can consult the [following section](https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html) in the apple documentation to get more information.
