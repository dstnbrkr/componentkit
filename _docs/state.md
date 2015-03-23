---
title: State
layout: docs
permalink: /docs/state.html
---

So far we've been loosely inspired by [React](http://facebook.github.io/react/). If you're familiar with React, you'll know that React components have two elements:

- **props**: passed from the parent. These roughly correspond to our parameters passed to the `+new` method.
- **state**: internal to the component, this holds implementation details that the parent should not have to know about. The canonical example is whether the article should be rendered fully, or truncated with a "Continue Reading…" link. This is a detail the parent component should not have to manually manage.

Figuring out the difference between these two can be tricky at first. [Thinking in React](http://facebook.github.io/react/blog/2013/11/05/thinking-in-react.html) is a really helpful blog post on this topic.

Just like React, `CKComponent` has state.

```objc++
@interface CKComponent
- (void)updateState:(id (^)(id))updateBlock
  animationDuration:(CGFloat)animationDuration;
@end
```

Let's make a simple example of using state for the "Continue Reading…" link.

```objc++
@implementation CKFeedMessageComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)newWithMessage:(NSAttributedString *)message
{
  CKComponentScope scope(self);
  NSNumber *state = scope.state();
  return [super newWithComponent:
          [CKRichTextComponent
           newWithAttributedString:message
           style:{
             // 0 means unlimited
             .maximumNumberOfLines = [state boolValue] ? 0 : 5
           }]];
}

- (void)didTapContinueReading:(id)sender
{
  [self updateState:^(id oldState){
    return @YES;
  } animationDuration:kCKComponentAnimationDurationNone];
}

@end
```
That's all there is to it. Some nice attributes:

- Continue Reading state is completely hidden from parent components and controllers. They don't need to know about it or manage it.
- State changes can be coalesced or arbitrarily delayed for performance reasons. We can easily compute the updated component off the main thread when possible/desired.

# But this violates MVC!

Some might argue this violates MVC. A view knows about state and knows how to respond to a user action!

This is not entirely true. The component does not know how to update its actual associated view; updating a view piecemeal is not allowed. The component *does* know how to inform its parent controller that a change has occurred via `CKComponentScope`.

If the parent controller were not monitoring the state object for updates, then the Continue Reading link would do nothing.

*State is just a generalized way of hiding implementation details from top-level controllers.* Controllers still manage the flow of re-rendering a view.
