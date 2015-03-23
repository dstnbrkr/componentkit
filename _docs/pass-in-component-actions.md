---
title: Pass in Component Actions
layout: docs
permalink: /docs/pass-in-component-actions.html
---
Follow this simple rule: `CKComponentAction` selectors should be implemented in the same file they are referenced.

The following counterexample establishes a hidden coupling between the parent and child component. If another component tries to use `CKChildComponent` or if the method is renamed in `CKParentComponent`, it will crash at runtime.

{% highlight objc++ cssclass=redhighlight %}
@implementation CKParentComponent
+ (instancetype)new
{
  return [super newWithComponent:[CKChildComponent new]];
}

- (void)someAction:(CKComponent *)sender
{
  // Do something
}
@end

@implementation CKChildComponent
+ (instancetype)new
{
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:@selector(someAction:)]];
}
@end
{% endhighlight %}

Instead, always pass selectors from parents to children. In the following example, it is explicit that the child component needs a `CKComponentAction` selector. If the parent component renames the `someAction:` method, it's far easier to catch renaming the parameter.

```objc++

@implementation CKParentComponent
+ (instancetype)new
{
  return [super newWithComponent:
          [CKChildComponent
           newWithAction:@selector(someAction:)]];
}

- (void)someAction:(CKComponent *)sender
{
  // Do something
}
@end

@implementation CKChildComponent
+ (instancetype)newWithAction:(CKComponentAction)action
{
  return [super newWithComponent:
          [CKButtonComponent
           newWithAction:action]];
}
@end
```
