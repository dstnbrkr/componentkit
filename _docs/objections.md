---
title: Objections
layout: docs
permalink: /docs/objections.html
---
## This means we can't use UIKit directly.

True. If we want to do asynchronous, off-main-thread sizing, we can't use UIKit directly.

Beyond performance, though, we believe the declarative style of React and ComponentKit is a superior programming model.

It's easy to create a component that simply wraps a `UIView`. (See [views](views.html) for an example.)

## New developers will face a learning curve.

React JS also has a learning curve, however declarative view layout has so many advantages that the benefits win out.

ComponentKit also places restrictions on developers which make layout more reliable. For example, a `UIView`'s `sizeThatFits:` may think it should be rendered at 200x100, but then someone adds a new separator view to `layoutSubviews` and forgets to update `sizeThatFits:`, so now there's a weird overlapping content bug. 

ComponentKit makes this kind of bug impossible. It's like bumper bowling for view layout!

## We'll have to reimplement each view as a component.

Not true; you don't need to add a new subclass of `CKComponent` to use a given `UIView`. For example:

```objc++
[CKComponent newWithView:{[UIButton class], {{@selector(setTitle:), @"Like"}}}]
```

However, there is *e.g.* `CKButtonComponent`, `CKImageComponent` and so forth, which provide syntactic sugar for common attributes (titles for buttons, targets for controls, and so forth). These are very thin wrappers that merely transform their inputs.

## This violates MVC.

A component may be the target of actions and update its state in response to those actions.

This objection is touched on briefly in the example in [state](state.html). I believe that because components are immutable and declarative, there is no danger to having them handle *limited* types of user actions.

MVC exists to tame the beast of mutable state. If your view is updating its state willy-nilly and the controller doesn't know about it, you're soon going to end up with a mess.

ComponentKit makes updating the view without the controller knowing about it impossible. So when components can intercept a user tap and announce "my state has changed in this way, please re-render me," they're not violating MVC; they're just encapsulating that state change logic. The controller is still the component that is re-rendering the view.
