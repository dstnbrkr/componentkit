// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

/**
 FBCompositeComponent allows you to hide your implementation details and avoid subclassing layout components like
 FBStackLayoutComponent. In almost all cases, you should subclass FBCompositeComponent instead of subclassing any other
 class directly.

 For example, suppose you create a component that should lay out some children in a vertical stack.
 Incorrect: subclass FBStackLayoutComponent and call `self newWithChildren:`.
 Correct: subclass FBCompositeComponent and call `super newWithComponent:[FBStackLayoutComponent newWithChildren...`

 This hides your layout implementation details from the outside world.

 @warning Overriding -layoutThatFits:parentSize: or -computeLayoutThatFits: is **not allowed** for any subclass.
 */
@interface FBCompositeComponent : FBComponent

/** Calls the initializer with {} for view. */
+ (instancetype)newWithComponent:(FBComponent *)component;

/**
 @param view Passed to FBComponent's initializer. This should be used sparingly for FBCompositeComponent. Prefer
 delegating view configuration completely to the child component to hide implementation details.
 @param component The component the composite component uses for layout and sizing.
 */
+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view component:(FBComponent *)component;

@end
