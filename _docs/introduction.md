---
title: Introduction
layout: docs
permalink: /docs/introduction.html
---

Components are immutable objects that specify how to configure views.

A simple analogy is to think of a component as a stencil: a fixed description that can be used to *paint* a view but that is not a view itself. A component is often composed of other components, building up a component hierarchy that *describes* a user interface.

Let's dive in with some sample code for describing a simplistic article in an article feed:

```objc++
@implementation CKArticleComponent

+ (instancetype)newWithArticle:(CKArticleModel *)article
{
  return [super newWithComponent:
          [CKStackLayoutComponent
           newWithStyle:{
             .direction = CKStackLayoutDirectionVertical,
           }
           children:{
             {[CKHeaderComponent newWithArticle:article]},
             {[CKMessageComponent newWithMessage:article.message]},
             {[CKFooterComponent newWithFooter:article.footer]},
           }];
}

@end
```

Components have three characteristics:

- **Declarative**: Instead of implementing `-sizeThatFits:` and `-layoutSubviews` and positioning subviews manually, you declare the subcomponents of your component (here, we say "stack them vertically").

- **Functional**: Data flows in one direction. Methods take data models and return totally immutable components. When state changes, the infrastructure re-renders from the root and reconciles the two component trees from the top with as few changes to the view hierarchy as possible.

- **Composable**: Here `CKFooterComponent` is used in a article, but it could be reused for other UI with a similar footer. Reusing it is a one-liner. `CKStackLayoutComponent` is inspired by the [flexbox model](http://www.w3.org/TR/css3-flexbox) of the web and can easily be used to implement many layouts.
