---
title: Collection Views
layout: docs
permalink: /docs/build-collectionview-using-componentkit.html
---

We will assume a simple setup with a `UIViewController` using a `UICollectionView` using a regular `UICollectionViewFlowLayout`.
## Setup
### Component Provider
The datasource is responsible for creating a component corresponding to each model. This transformation should be defined as a method on a class conforming to `CKComponentProviding` that we will then be passed as the component provider.

Let's make our UIViewController be the component provider here.

	@interface MyController <CKComponentProviding>
	...
	@end

	@implementation MyController
	...
	+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context {
		return [MyComponent newWithModel:model context:context];
	}
	...

- **Why use a class Method and not a block?** The transform model->component should be pure, but blocks makes it very easy to capture mutable state that could introduce side effects in the system. Using a class method allows us to better enforce the constraint of purity from an API standpoint.
- **What is this context ?** The context, as its name implies, contains immutable contextual data. It is setup during the initialization of the datasource and can be used to pass in: action handlers, display state, dependencies such as an image cache or an image downloader.

{% highlight objc++ cssclass=redhighlight %}
Don't access global state inside a Component. Use the context to pass this information instead.
{% endhighlight %}

### Create your datasource

Ok, so now we have our UIViewController as the component provider, let's create our `CKComponentCollectionViewDataSource` and attach the collection view to it.

	- (void)viewDidLoad {
	...
	self.dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView componentProvider:[self class] componentProvider:[self class] context:context cellConfigurationFunction:...];
	}


Note that we pass the context in the initializer, it is the same context that you will then get passed into `+ (CKComponent *)componentForModel:context:` every time a component needs to get computed.

## Add/Modify content in the collection view

### Changeset API
Using CKCollectionViewDataSource you never modify the collection view directly but send commands to the datasource that will then compute the components and apply the corresponding changes to the collection view.

Let's add a section at index 0 and two items in this section at index 0 and 1.
{% raw  %}
	- (void)viewDidAppear {
		...
		CKComponentDataSourceChangeset changeset;
		// Don't forget the insertion of section 0
		changeset.sections.insert(0);
		changeset.items.insert({0,0}, firstModel);
		changeset.items.insert({0,1}, secondModel);
		[self.dataSource enqueueChangeset:changeset constrainedSize:{{0,0}, {50, 50}}];
	}
{% endraw %}

Later on (for instance when we receive udpated data from the server), we can update our first item with an updated model.
{% raw  %}
	...
	CKComponentDataSourceChangeset changeset;
	changeset.items.update({0,0}, udpatedFirstModel);
	[self.dataSource enqueueChangeset:changeset constrainedSize:{{50,0}, {50, INF}}];
	...
{% endraw %}

You can also remove items and sections through this changeset API, more details in the [Changeset API](changeset-api.html) section.

### Layout

As you can see above we pass a constrained size every time a changeset is enqueued, this constrained size is used internally to layout the components and compute their final size. The form of the constrained size is: {% raw  %}`{{minWidth, minHeight},{maxWidth, maxHeight}}`{% endraw %}.
In the above code the width of the component layout will have to be 50pt while the height will depend on the content.

Let's see how we can use the computed component sizes with our `UICollectionViewFlowLayout`, assuming that our view controller is the delegate of the flow layout.

We will size each item so that it matches the size of their computed component.

```objc++
	- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
                  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  		return [self.dataSource sizeForItemAtIndexPath:indexPath];
	}
```

Pretty simple right ? And this logic can apply to any `UICollectionViewLayout`, size your components within the top level constraint. Then in your `UICollectionViewLayout` position your items and size them using the computed component sizes.

## Handle actions

Time to interact with those items now; nothing special here you can use the regular selection APIs. Let's say our models sometimes have a URL that we want to open every time the user taps on an item.

```objc++
	- (void)dataSource:(CKComponentCollectionViewDataSource *)dataSource didSelectItemAtIndexPath:(NSIndexPath *)indexPath
	{
  		MyModel *model = (MyModel *)[self.dataSource modelForItemAtIndexPath:indexPath];
  		NSURL *navURL = model.url;
  		if (navURL) {
  			[[UIApplication sharedApplication] openURL:navURL];
  		}
  	}
```

Note: The datasource is the source of truth for the collection view, if you have to retrieve a model corresponding to an indexPath always use `-modelForItemAtIndexPath`. See the [Good practices](good-practices-datasources.html) for more details.
