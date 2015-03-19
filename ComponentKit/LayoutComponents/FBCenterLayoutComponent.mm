// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBCenterLayoutComponent.h"

#import "CKInternalHelpers.h"
#import "ComponentUtilities.h"
#import "FBComponentSubclass.h"

@implementation FBCenterLayoutComponent
{
  FBCenterLayoutComponentCenteringOptions _centeringOptions;
  FBCenterLayoutComponentSizingOptions _sizingOptions;
  FBComponent *_child;
}

+ (instancetype)newWithCenteringOptions:(FBCenterLayoutComponentCenteringOptions)centeringOptions
                          sizingOptions:(FBCenterLayoutComponentSizingOptions)sizingOptions
                                  child:(FBComponent *)child
                                   size:(const FBComponentSize &)size
{
  FBCenterLayoutComponent *c = [super newWithView:{} size:size];
  if (c) {
    c->_centeringOptions = centeringOptions;
    c->_sizingOptions = sizingOptions;
    c->_child = child;
  }
  return c;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  // If we have a finite size in any direction, pass this so that the child can
  // resolve percentages agains it. Otherwise pass kFBComponentParentDimensionUndefined
  // as the size will depend on the content
  CGSize size = {
    isinf(constrainedSize.max.width) ? kFBComponentParentDimensionUndefined : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? kFBComponentParentDimensionUndefined : constrainedSize.max.height
  };

  // Layout the child
  const CGSize minChildSize = {
    (_centeringOptions & FBCenterLayoutComponentCenteringX) != 0 ? 0 : constrainedSize.min.width,
    (_centeringOptions & FBCenterLayoutComponentCenteringY) != 0 ? 0 : constrainedSize.min.height,
  };
  const FBComponentLayout childLayout = [_child layoutThatFits:{minChildSize, {constrainedSize.max}} parentSize:size];

  // If we have an undetermined height or width, use the child size to define the layout
  // size
  size = constrainedSize.clamp({
    isnan(size.width) ? childLayout.size.width : size.width,
    isnan(size.height) ? childLayout.size.height : size.height
  });

  // If minimum size options are set, attempt to shrink the size to the size of the child
  size = constrainedSize.clamp({
    MIN(size.width, (_sizingOptions & FBCenterLayoutComponentSizingOptionMinimumX) != 0 ? childLayout.size.width : size.width),
    MIN(size.height, (_sizingOptions & FBCenterLayoutComponentSizingOptionMinimumY) != 0 ? childLayout.size.height : size.height)
  });

  // Compute the centered postion for the child
  BOOL shouldCenterAlongX = (_centeringOptions & FBCenterLayoutComponentCenteringX);
  BOOL shouldCenterAlongY = (_centeringOptions & FBCenterLayoutComponentCenteringY);
  const CGPoint childPosition = {
    CKRoundPixelValue(shouldCenterAlongX ? (size.width - childLayout.size.width) * 0.5f : 0),
    CKRoundPixelValue(shouldCenterAlongY ? (size.height - childLayout.size.height) * 0.5f : 0)
  };

  return {self, size, {{childPosition, childLayout}}};
}

@end
