---
title: Avoid Local Variables 
layout: docs
permalink: /docs/avoid-local-variables.html
---
In your `+new` method, avoid creating temporary local variables when possible.

- **It makes code harder to read and modify** since dependencies between local variables are hard to visualize.
- **It encourages mutating local variables after assignment** which hides surprising side-effects and changes.

Here is a really tangled-up `+new` method that is hard to read, understand, or modify:

{% highlight objc++ cssclass=redhighlight %}
+ (instancetype)newWithArticle:(CKArticle *)article options:(CKArticleOptions)options
{
  NSAttributedString *timestamp = [CKDateFormatter stringFromDate:article.creationTime];
  CKHeaderComponent *header =
  [CKHeaderComponent
   newWithTitle:article.title
   subtitle:timestamp];

  // LOGIC ERROR! timestamp has already been used by header, but no one warns us.
  if (options & CKArticleOptionHideTimestamp) {
    timestamp = nil;
  }

  CKMessageOptions messageOptions = 0;
  if (options & CKArticleOptionShortMessage) {
    messageOptions |= CKMessageOptionShort;
  }
  CKMessageComponent *message =
  [CKMessageComponent
   newWithArticle:article
   options:messageOptions];

  CKFooterComponent *footer = [CKFooterComponent newWithArticle:article];

  // SUBOPTIMAL: why did we create the header only to throw it away?
  // Also, notice how far this is from where we created the header.
  if (options & CKArticleOptionOmitHeader) {
    header = nil;
  }

  return [self newWithComponent:
          [CKStackLayoutComponent
           newWithChildren:{
             header,
             message,
             footer
           }]];
}
{% endhighlight %}

Instead, split out logic into separate components:

```objc++
+ (instancetype)newWithArticle:(CKArticle *)article options:(CKArticleOptions)options
{
  // Note how there are NO local variables here at all.
  return [self newWithComponent:
          [CKStackLayoutComponent
           newWithChildren:{
             [CKArticleHeaderComponent
              newWithArticle:article
              options:headerOptions(options)],
             [CKArticleMessageComponent
              newWithArticle:article
              options:messageOptions(options)],
             [CKFooterComponent newWithArticle:article]
           }]];
}

// Note how this is a pure function mapping from one options bitmask to another.
static CKArticleHeaderComponentOptions headerOptions(CKArticleOptions options)
{
  CKArticleHeaderComponentOptions options;
  if (options & CKArticleOptionOmitHeader) {
    options |= CKArticleHeaderComponentOptionOmit;
  }
  if (options & CKArticleOptionHideTimestamp) {
    options |= CKArticleHeaderComponentOptionHideTimestamp;
  }
  return options;
}
```
