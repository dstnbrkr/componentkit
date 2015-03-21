---
title: Avoid Width 100%
layout: docs
permalink: /docs/avoid-width-100-percent.html
---

Avoid doing this:

{% highlight objc++ cssclass=redhighlight %}
@implementation CKPersonComponent
+ (instancetype)newWithPerson:(CKMemPerson *)person
{
  return [super newWithComponent:
          [CKComponent
           newWithView:{[CKPersonView class], ...}
           size:{.width = Percent(1.0)}]];
}
@end
{% endhighlight %}

Instead, favor an approach using `size:{}` and requiring the parent of `CKPersonComponent` to specify its width. For example, if the parent is a `CKStackLayoutComponent`, use `CKStackLayoutAlignItemsStretch` to stretch the component to full width.

This keeps components reusable in situations where you don't want them to be 100% of the parent's width.
