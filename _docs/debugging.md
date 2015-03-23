---
title: Debugging
layout: docs
permalink: /docs/debugging.html
---

ComponentKit generally uses generic views such as `UIButton`, `UIImageView`, etc. under the hood. Hence, when you run a command like `pviews` you're likely to get a very generic hierarchy that doesn't point you to the component you might want to know more about. The following is the output of running `pviews` for components.

TODO: Stack Trace
 
As you can see, this is very generic and it is almost impossible to get back to the component from this view output. Hence, we have created a set of debugging tools that help you achieve that simply.

## pcomponents 

`pcomponents` allows you to print the component hierarchy, including layout information like position and size. It is designed to be analogous to how `pviews` works. It is the easiest way to reason about where your layout might have gone wrong while looking at the component rendered on screen. It can generally be called just by saying `pco` in the debug console.

TODO: add a stack trace.

Optionally takes in a view from where to begin its search and the search can be upwards as well, as shown below... it traverses up to find the first view on which there's a component hierarchy attached.

  pcomponents -u 0x81901e30
  
TODO: add a stack trace

<div class="note">
  <p>
     Generally, if you run <code>pcomponents</code> you will be presented with multiple component hierarchies, one each for each visible cell. To get the component hierarchy for the cell you're interested in, type `taplog` on the console and click on a view in the cell you're interested in - <code>taplog</code> would give you the memory address of that view, which you can copy. Then you can use <code>pcomponents -u &lt;Address of View&gt;</code> to get the hierarchy for the cell you are interested in.
  </p>
</div>

## dcomponents 

`dcomponents` sets up debug views which are phantom views for components which originally don't have any views. Looking through the view hierarchy in Reveal gives a visual manifestation to layout and can be useful for debugging. `dcomponents` gives a sense of the component hierarchy in the view hierarchy itself, since the phantom views generated have the name of their backing components.

To set the mode, use `dc -s`. To unset, `dc -u`. Again, this is based on the prefix matching provided by LLDB.

TODO: pxlcld/lw09
