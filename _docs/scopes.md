---
title: Scopes
layout: docs
permalink: /docs/scopes.html
---

# What is a scope 

Declaring a scope in a component means "this component has some state". There are 2 ways to have state in components: either by having state or by having a controller.

Similar to components, component-states are composed in a tree structure. It is essentially the same tree, except for components which don't have state which are skipped.

Now while components are short-lived and get trashed every time the cell is updated, states are long-lived. So states need a way to be preserved before and after an update. Hence the scope: the scope is a way to define how the state should be preserved through an update.

# How to define a scope 

```objc++
CKComponentScope scope(self);
```

Wow. That was easy. But what does that mean? This means :

- My component has state
- My component's class name is enough to track the state

During an update, a completely new tree of components will be created. If a component with the same class appears, then the state will be passed from the old component to the new component. 

But what happened if they are multiple component with the same class? Well it is not going to work. You need to define additional information to pass on the state from the old component to the new component.

# How to define a scope poorly 

Here is a bad way to do it:

{% highlight objc++ cssclass=redhighlight %}
CKComponentScope scope(self, rand());
{% endhighlight %}

This means that the scope will be more or less trashed every time you update the component because the integer will never match. 

Here is another bad way to do it:

{% highlight objc++ cssclass=redhighlight %}
CKComponentScope scope(self, dataModel.url);
{% endhighlight %}

This will attempt to match the URLs related to your model. But if the URL changes for any reason, you will lose your state and your controller.

# How to define a scope properly 

You can define the component relative to its position in the tree. This makes sure that if the datamodel changes, your controller will be maintained from one model to another. The drawback is that the position has usually to be passed from the parent to the child, which means that the child is somehow aware of where it is, which is not great.

```objc++
CKComponentScope scope(self, @"Footer");
```

or 

```objc++
CKComponentScope scope(self, @4);
```


You can define the component relative to its datamodel. Now the problem here is that if your component gets updated with a slightly different datamodel, the state and the controller might get dropped.

```objc++
CKComponentScope scope(self, datamodel.uniqueID);
```
