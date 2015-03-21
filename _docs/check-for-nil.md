---
title: Check for nil
layout: docs
permalink: /docs/check-for-nil.html
---

Remember: **`+new` can always return nil**. This is particularly important when you're dealing with ivars.

Components has adopted the convention that a component may return nil from `+new` to signal that it has no data to render. For example, `CKUFIComponent` returns nil if there are no buttons in the UFI.

This is important when you are implementing `+new` because you must be prepared to deal with `[super +new...]` returning nil.

{% highlight objc++ cssclass=redhighlight %}
@implementation CKMyComponent
{
  NSString *_name;
}

+ (instancetype)newWithName:(NSString *)name
{
  CKMyComponent *c = [super newWithComponent:...];
  c->_name = [name copy]; // Crashes if c is nil
  return c;
}
{% endhighlight %}

Instead:

```objc++

+ (instancetype)newWithName:(NSString *)name
{
  CKMyComponent *c = [super newWithComponent:...];
  if (c) {
    c->_name = [name copy];
  }
  return c;
}
```

(This is somewhat analogous to the usual pattern for implementing `-init`, where you check if `[super init...]` returns nil.)
