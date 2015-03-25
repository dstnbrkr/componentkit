---
title: Overview
layout: docs
permalink: /docs/datasource-overview.html
---

ComponentKit really shine when used along with a `UICollectionView`.

### Automatic reuse

Who hasn't had bugs with cell reuse ? In ComponentKit, the declarative nature of a Component makes it so you don't have to worry about reuse anymore! [This article in objc.io](http://www.objc.io/issue-22/facebook.html) explains in great length how we achieve **automatic reuse and reconfiguration** with ComponentKit.

### Scroll performance

**ComponentKit addresses common scroll performance issues holistically**. Putting cells on screen is usually very performance sensitive, cells are dequeued while scrolling is  happening so any frame drop will be immediately visible.

Automatic and optimized reuse is already great for performance. But also, because generating a component and laying it out is just a **succession of pure functions working with immutable data** this operation can be very **easily moved to the background**.

The provided list views infrastructure uses this characteristic of the system to only spend a minimal amount of time in the main thread. No more stutters due to complex hierarchies or expensive text layout !

## CKComponentDataSource

`CKComponentDataSource` is at the core of the list view infrastructure. Instances of this class are agnostic to the `UICollectionView` API and their role is to :

- Take in changesets containing commands and models.
*e.g: "Insert at index 0 in section 1 the item representing ModelA".
- **Generate and Layout in the background** the components associated to those changes.
- And output a changeset along with handles to the generated components so that it can used with a `UITableView` or a `UICollectionView`

## CKComponentCollectionViewDataSource

`CKComponentCollectionViewDataSource` is a thin wrapper around `CKComponentDataSource` that implements the `UICollectionViewDataSource` API.

It can be used to easily bootstrap a `UICollectionView` using components. See how to [display components in a collection view.](datasource-basics.html)

## What about UITableViews ?

To power a UITableView with components you can directly use `CKComponentDataSource`. [See this code sample.](datasource-dive-deeper.html\#example-use-it-in-your-viewcontroller-to-power-a-uitableview)
