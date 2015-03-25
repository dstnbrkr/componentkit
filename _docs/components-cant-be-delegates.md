---
title: Components Can't Be Delegates
layout: docs
permalink: /docs/components-cant-be-delegates.html
---

Remember the analogy made in [Philosophy](philosophy.html): components are like a stencil. They are an immutable snapshot of how a view should be configured at a given moment in time.

Every time something changes, an entirely new component is created and the old one is thrown away. This means components are **short-lived**, and their lifecycle is not under your control. Thus they should not be delegates or `NSNotification` observers.

An example: imagine you're showing a `UIAlertView`. You might be tempted to make the component the delegate:

{% highlight objc++ cssclass=redhighlight %}
@implementation CKAlertDisplayComponent <UIAlertViewDelegate>
{
  UIAlertView *_alertView;
}

- (void)didTapDisplayAlert
{
  _alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                          message:nil
                                         delegate:self ...];
  [_alertView show];
}

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self updateState:...];
}
@end
{% endhighlight %}

But if the component hierarchy is regenerated for any reason, the original component will deallocate and the alert view will be left with no delegate.

Instead, use `CKComponentController`. Component controllers are long-lived; they persist and keep track of each updated version of your component. You can [learn more about component controllers](component-controllers.html); here's an example of their use:

```objc++

@interface CKAlertDisplayComponentController : CKComponentController <UIAlertViewDelegate>
@end

@implementation CKAlertDisplayComponentController
{
  UIAlertView *_alertView;
}

- (void)didTapDisplayAlert
{
  _alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                          message:nil
                                         delegate:self ...];
  [_alertView show];
}

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  [self.component updateState:...];
}
@end
```

