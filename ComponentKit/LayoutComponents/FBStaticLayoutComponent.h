// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBDimension.h>

struct FBStaticLayoutComponentChild {
  CGPoint position;
  FBComponent *component;

  /**
   If specified, the component's size is restricted according to this size. Percentages are resolved relative to the
   static layout component.

   The default is Auto in both dimensions, which sets the child's min size to zero and max size to the maximum available
   space it can consume without overflowing the component's bounds.
   */
  FBRelativeSizeRange size;
};

/*
 A component that positions children at fixed positions.

 Computes a size that is the union of all childrens' frames.
 */
@interface FBStaticLayoutComponent : FBComponent

/**
 @param view Passed to the super class initializer.
 @param children Children to be positioned at fixed positions.
 */
+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                       size:(const FBComponentSize &)size
                   children:(const std::vector<FBStaticLayoutComponentChild> &)children;

/**
 Convenience that does not have a view or size.
 */
+ (instancetype)newWithChildren:(const std::vector<FBStaticLayoutComponentChild> &)children;

@end
