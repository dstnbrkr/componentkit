---
title: Scopes
layout: docs
permalink: /docs/scopes.html
---

Scopes give components a persistent identity. They're needed in three cases:

1. Components that have [state](state.html) must have a scope.
2. Components that have a [controller](component-controllers.html) must have a scope.
3. TODO describe sibling components with stateful component children

## Defining a Scope

```objc++
CKComponentScope scope(self);
```
