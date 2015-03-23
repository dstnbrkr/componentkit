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
+ (instancetype)newWithStory:(CKStory *)story options:(CKStoryOptions)options
{
  NSAttributedString *timestamp = [CKDateFormatter stringFromDate:story.creationTime];
  CKHeaderComponent *header =
  [CKHeaderComponent
   newWithTitle:story.title
   subtitle:timestamp];

  // LOGIC ERROR! timestamp has already been used by header, but no one warns us.
  if (options & CKStoryOptionHideTimestamp) {
    timestamp = nil;
  }

  CKMessageOptions messageOptions = 0;
  if (options & CKStoryOptionShortMessage) {
    messageOptions |= CKMessageOptionShort;
  }
  CKMessageComponent *message =
  [CKMessageComponent
   newWithStory:story
   options:messageOptions];

  CKFooterComponent *footer = [CKFooterComponent newWithStory:story];

  // SUBOPTIMAL: why did we create the header only to throw it away?
  // Also, notice how far this is from where we created the header.
  if (options & CKStoryOptionOmitHeader) {
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
+ (instancetype)newWithStory:(CKStory *)story options:(CKStoryOptions)options
{
  // Note how there are NO local variables here at all.
  return [self newWithComponent:
          [CKStackLayoutComponent
           newWithChildren:{
             [CKStoryHeaderComponent
              newWithStory:story
              options:headerOptions(options)],
             [CKStoryMessageComponent
              newWithStory:story
              options:messageOptions(options)],
             [CKFooterComponent newWithStory:story]
           }]];
}

// Note how this is a pure function mapping from one options bitmask to another.
static CKStoryHeaderComponentOptions headerOptions(CKStoryOptions options)
{
  CKStoryHeaderComponentOptions options;
  if (options & CKStoryOptionOmitHeader) {
    options |= CKStoryHeaderComponentOptionOmit;
  }
  if (options & CKStoryOptionHideTimestamp) {
    options |= CKStoryHeaderComponentOptionHideTimestamp;
  }
  return options;
}
```
