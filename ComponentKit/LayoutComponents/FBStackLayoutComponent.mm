// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBStackLayoutComponent.h"

#import <numeric>

#import <FBComponentKit/CKMacros.h>

#import "ComponentUtilities.h"
#import "FBComponentSubclass.h"
#import "FBStackLayoutComponentUtilities.h"
#import "FBStackPositionedLayout.h"
#import "FBStackUnpositionedLayout.h"

@implementation FBStackLayoutComponent
{
  FBStackLayoutComponentStyle _style;
  std::vector<FBStackLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                       size:(const FBComponentSize &)size
                      style:(FBStackLayoutComponentStyle)style
                   children:(const std::vector<FBStackLayoutComponentChild> &)children
{
  FBStackLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_style = style;
    c->_children = children;
  }
  return c;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view size:(const FBComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  const auto children = FB::filter(_children, [](const FBStackLayoutComponentChild &child){
    return child.component != nil;
  });

  const auto unpositionedLayout = FBStackUnpositionedLayout::compute(children, _style, constrainedSize);
  const auto positionedLayout = FBStackPositionedLayout::compute(unpositionedLayout, _style, constrainedSize);
  const CGSize finalSize = directionSize(_style.direction, unpositionedLayout.stackDimensionSum, positionedLayout.crossSize);
  return {self, constrainedSize.clamp(finalSize), positionedLayout.children};
}

@end
