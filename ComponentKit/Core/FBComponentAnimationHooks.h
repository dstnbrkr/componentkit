// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

typedef id (^FBComponentWillRemountAnimationBlock)(void);
typedef id (^FBComponentDidRemountAnimationBlock)(id context);
typedef void (^FBComponentCleanupAnimationBlock)(id context);

struct FBComponentAnimationHooks {
  /**
   Corresponds to [FBComponentController -willRemountComponent]. The old component and its children are still mounted.
   Example uses of this hook include computing a fromValue for use in didRemount or creating a snapshotView from a
   component that will be unmounted.
   @return A context object that will be passed to didRemount.
   */
  FBComponentWillRemountAnimationBlock willRemount;

  /**
   Corresponds to [FBComponentController -didRemountComponent]. The new component and its children are now mounted.
   Old components may or may not still be mounted; if they are mounted, they will be unmounted shortly.
   @param context The context returned by the willRemount block.
   @return A context object that will be passed to cleanup.
   */
  FBComponentDidRemountAnimationBlock didRemount;

  /**
   Corresponds to [FBComponentController -willUnmount] *and* [FBComponentController -componentWillRelinquishView].
   Perform any cleanup, e.g. removing animations from layers. Note that any number of remounting and view
   recycling operations may have occurred since didRemount was called, including subsequent animations that may even be
   animating the same property! You should pass any views in as part of the context object instead of accessing them
   via a component instance.
   @param context The context returned by the didRemount block.
   */
  FBComponentCleanupAnimationBlock cleanup;
};
