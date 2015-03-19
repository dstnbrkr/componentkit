// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBRatioLayoutComponent.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/FBComponentSubclass.h>

#import "CKInternalHelpers.h"

@implementation FBRatioLayoutComponent
{
  float _ratio;
  FBComponent *_component;
}

+ (instancetype)newWithRatio:(float)ratio
                   component:(FBComponent *)component
{
  CKAssert(ratio > 0, @"Ratio should be strictly positive. Let's stay classy.");
  if (ratio <= 0) {
    return nil;
  }

  FBRatioLayoutComponent *c = [self newWithView:{} size:{}];
  if (c) {
    c->_ratio = ratio;
    c->_component = component;
  }
  return c;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
                          restrictedToSize:(const FBComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  float constrainedHeight = constrainedSize.max.height;
  float constrainedWidth = constrainedSize.max.width;

  // Don't do anything if one of the constraints is zero
  if (constrainedSize.max.height > 0 && constrainedSize.max.width > 0) {
    if (constrainedSize.max.height > _ratio * constrainedSize.max.width) {
      constrainedHeight = _ratio * constrainedSize.max.width ;
      constrainedWidth = constrainedSize.max.width;
    } else {
      constrainedHeight = constrainedSize.max.height;
      constrainedWidth = constrainedSize.max.height / _ratio;
    }
  }

  // Always crop to the current size
  CGSize maxSize = constrainedSize.clamp({CKFloorPixelValue(constrainedWidth), CKFloorPixelValue(constrainedHeight)});

  FBComponentLayout childLayout = [_component layoutThatFits:{constrainedSize.min, maxSize} parentSize:parentSize];
  return {self, childLayout.size, {{{0,0}, childLayout}}};
}

@end
