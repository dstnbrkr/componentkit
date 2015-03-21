---
title: Layout
layout: docs
permalink: /docs/layout.html
---

`UIView` instances store position and size in their `center` and `bounds` properties. As constraints change, Core Animation performs a layout pass to call `layoutSubviews`, asking views to update these properties on their subviews.

`CKComponent` instances do not have any size or position information. Instead, the infrastructure calls the `layoutThatFits:` method with a given size constraint and the component must *return* a structure describing both its size, and the position and sizes of its children.

```objc++
struct CKComponentLayout {
  CKComponent *component;
  CGSize size;
  std::vector<CKComponentLayoutChild> children;
};

struct CKComponentLayoutChild {
  CGPoint position;
  CKComponentLayout layout;
};
```

You can implement `computeLayoutThatFits:` manually if needed, but generally it's easier to use "layout components". These provide common layouts like stack, overlay, inset, center, and so on.

# Stack Layouts 

`CKStackLayoutComponent` is important enough to cover in some detail. Its semantics are based on the [CSS flexbox](http://www.w3.org/TR/css3-flexbox/) specification, though simplified in some areas.

This provides a great deal of power. While iOS Feed has many complicated layouts, almost all of them are implemented as stack layouts. This means there is almost no layout math required.

It also means that if you're struggling to figure out how to configure a `CKStackLayoutComponent`, you might want to consult a CSS expert!
