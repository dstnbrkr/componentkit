// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponent.h>

/**
 A component that wraps another component, applying insets around it.

 If the child component has a size specified as a percentage, the percentage is resolved against this component's parent
 size **after** applying insets.

 @example FBOuterComponent contains an FBInsetComponent with an FBInnerComponent. Suppose that:
 - FBOuterComponent is 200pt wide.
 - FBInnerComponent specifies its width as 100%.
 - The FBInsetComponent has insets of 10pt on every side.
 FBInnerComponent will have size 180pt, not 200pt, because it receives a parent size that has been adjusted for insets.

 If you're familiar with CSS: FBInsetComponent's child behaves similarly to "box-sizing: border-box".

 An infinite inset is resolved as an inset equal to all remaining space after applying the other insets and child size.
 @example An FBInsetComponent with an infinite left inset and 10px for all other edges will position it's child 10px from the right edge.
 */
@interface FBInsetComponent : FBComponent

/** Convenience that calls +newWithView:insets:component: with {} for view. */
+ (instancetype)newWithInsets:(UIEdgeInsets)insets component:(FBComponent *)child;

/**
 @param view Passed to FBComponent +newWithView:size:. The view, if any, will extend outside the insets.
 @param insets The amount of space to inset on each side.
 @param component The wrapped child component to inset. If nil, this method returns nil.
 */
+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                     insets:(UIEdgeInsets)insets
                  component:(FBComponent *)component;

@end
