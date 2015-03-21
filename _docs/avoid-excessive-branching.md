---
title: Avoid Excessive Branching 
layout: docs
permalink: /docs/avoid-excessive-branching.html
---

Avoid excessive branching in component code. Components are best read top-down and any branching introduces complications in understanding the layout. If you find yourself branching too much, consider separating your component into smaller components and composing them. 

TODO: Examples of code smell

# Branching Strategy for iPad 

There are generally two situations for iPad: either the component is going to render similarly on both iPhone or iPad, or render completely differently.

## Similar 

TODO: Add example

In this case you should generally share the overall layout and introduce `[CKDevice isPad]` checks in the 1-2 places that it is needed. Generally these end up being inline checks using a ternary operator. For example

```objc++
[CKInsetComponent
 newWithInsets:[CKDevice isPad] ? UIEdgeInsetsMake(0, 0, 8.0, 9.0) : UIEdgeInsetsMake(0, 0, 3.0, 4.0)
 component: ...]
```

## Different 

TODO: Add example

If you're using `[CKDevice isPad]` checks in more than 2-3 places, it's preferable to completely separate the iPhone and iPad implementations of the component structure and branch **only once**. Avoid branching on `[CKDevice isPad]` checks in helper functions.

```objc++
if ([CKDevice isPad]) {
  // iPad rendering
} else {
  // iPhone rendering
}
```

# Reasoning 

Code tends to accumulate a lot of these device based checks over time. Having a lot of iPad checks in various places makes the code paths difficult to reason about between iPhone and iPad. There's much more value in being able to read code top down for the iPhone case and separately for the iPad case. Legacy attachment controllers (such as `CKLinkShareAttachmentController`) are proof of the bad situation that results when we use too many device based checks.
