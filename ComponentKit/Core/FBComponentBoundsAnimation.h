// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FBComponentBoundsAnimationMode) {
  /** Wraps changes in a UIView animation block */
  FBComponentBoundsAnimationModeDefault = 0,
  /** Wraps changes in a UIView spring animation block */
  FBComponentBoundsAnimationModeSpring,
};

/**
 Specifies how to animate a change to the component tree.

 There are two ways to trigger a change to the component tree: a call to -updateState: within a component, or a change
 to the model (by enqueueing an update to the data source or calling [FBComponentHostingView -setModel:]).

 When the view hierarchy is updated to reflect the new component tree, -boundsAnimationFromPreviousComponent: is called
 on every component in the new tree that has an equivalent in the old tree. If any component returns a bounds animation
 with a duration that is non-zero, the change will be animated. If different components return conflicting animation
 settings, the result is undefined.

 Changes to components that are offscreen in a UICollectionView or UITableView are never animated.

 @warning UITableView does not support customizing its animation in any way. FBComponentTableViewDataSource animates
 the change using UITableView's defaults if duration is non-zero, ignoring all other parameters.

 @warning FBComponentHostingView does not yet support FBComponentBoundsAnimation.
 */
struct FBComponentBoundsAnimation {
  NSTimeInterval duration;
  NSTimeInterval delay;
  FBComponentBoundsAnimationMode mode;

  /** Ignored unless mode is Spring, in which case it specifies the damping ratio passed to UIKit. */
  CGFloat springDampingRatio;
  /** Ignored unless mode is Spring, in which case it specifies the initial velocity passed to UIKit. */
  CGFloat springInitialVelocity;
};
