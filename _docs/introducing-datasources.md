---
title: Introducing the datasources
layout: docs
permalink: /docs/introducing-datasources.html
---

ComponentKit really shines through when used along with a `UICollectionView` and a `UITableView` :

- Who hasn't had bugs with cell reuse ? In ComponentKit, the declarative nature of a Component makes it so you don't have to worry about reuse anymore! [Adam Ernst's article in objc.io](http://www.objc.io/issue-22/facebook.html) explains in great length how we achieve **automatic reuse and reconfiguration** with ComponentKit.
- **ComponentKit addresses common scroll performance issues holistically**. Putting cells on screen is usually very performance sensitive, cells are dequeued while scrolling happening so any frame drop will immediately visible. Automatic and optimized reuse is already great for performance. But also, because generating a component and laying it out is just a **succession of pure functions working with immutable data** it can be very **easily moved to the background**. The provided datasources will use this characteristic to only spend a minimal amount of time in the main thread. No more stutters due to complex hierarchies or expensive text layout.

ComponentKit comes with standard datasources that can power your `UICollectionView(s)` or `UITableView(s)`.

### CKComponentDataSource

`CKComponentDataSource` is the main class that :

- Takes in changesets which contains commands and models. *e.g: "Insert Item at index 0 in section 1 with ModelA", "Update Item at index 1 in section 0 with modelB"*.
- **Generate and Layout asynchronously and in the background** the components associated to those changes.
- Output a changeset along with handles to the generated components so that it can be easily used with a `UITableView` or a `UICollectionView`

### CKComponentCollectionViewDataSource

`CKComponentCollectionViewDataSource` is a thin wrapper around `CKComponentDataSource` that implements the `UICollectionViewDataSource` API.

It can be used to easily bootstrap a collection view displaying components. See [Display components in a collection view](build-collectionview-using-componentkit)
