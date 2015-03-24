---
title: Scopes
layout: docs
permalink: /docs/scopes.html
---

In the following component tree, ComponentKit has no way to distinguish the three ListItem children:

<img src="/static/images/tree.png" width="367" height="124" alt="Component Tree">

We need a way to give each child a unique identifier:

<img src="/static/images/tree-ids.png" width="367" height="124" alt="Component Tree with IDs">

Scopes give components a persistent, unique identity. They're needed in three cases:

1. Components that have [state](state.html) must have a scope.
2. Components that have a [controller](component-controllers.html) must have a scope.
3. TODO describe sibling components with stateful component children

## Defining a Scope

```objc++
CKComponentScope scope(self);
```
