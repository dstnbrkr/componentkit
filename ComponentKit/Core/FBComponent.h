// Copyright 2004-present Facebook. All Rights Reserved.

#ifndef __cplusplus
#error This file must be compiled as Obj-C++. If you're importing it, you must change your file extension to .mm.
#endif

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentSize.h>
#import <FBComponentKit/FBComponentViewConfiguration.h>

struct FBComponentViewContext {
  UIView *view;
  CGRect frame;
};

/** A component is an immutable object that specifies how to configure a view, loosely inspired by the React. */
@interface FBComponent : NSObject

/**
 @param view A struct describing the view for this component. Pass {} to specify that no view should be created.
 @param size A size constraint that should apply to this component. Pass {} to specify no size constraint.

 @example A component that renders a red square:
 [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100, 100}]
 */
+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                       size:(const FBComponentSize &)size;

/**
 While the component is mounted, returns information about the component's manifestation in the view hierarchy.

 If this component creates a view, this method returns the view it created (or recycled) and a frame with origin 0,0
 and size equal to the view's bounds, since the component's size is the view's size.

 If this component does not create a view, returns the view this component is mounted within and the logical frame
 of the component's content. In this case, you should **not** make any assumptions about what class the view is.
 */
- (FBComponentViewContext)viewContext;

/**
 While the component is mounted, returns its next responder. This is the first of:
 - Its component controller, if it has one;
 - Its supercomponent;
 - The view the component is mounted within, if it is the root component.
 */
- (id)nextResponder;

@end
