---
title: Component API
layout: docs
permalink: /docs/component-api.html
---
The base `CKComponent` class is quite simple. Leaving out a few methods, it looks like this:

```objc++
@interface CKComponent : UIResponder

/// Returns a new component.
+ (instancetype)newWithView:(CKComponentViewConfiguration)view
                       size:(CKComponentSize)size;

/// Returns a layout for the component and its children.
- (CKComponentLayout)layoutThatFits:(CKSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize;

@end
```

We'll get to these two methods in a moment. For now, note:

- Components are totally immutable. For example, there is no `addSubcomponent:` method.
- Components can be created on any thread. This keeps all sizing and construction operations off the main thread.
- The Objective-C idiom `+newWith...` is used for instantiation instead of the more typical `+alloc/-initWith..`. This is mainly for brevity. Getting rid of noise is important to keep components code readable.
