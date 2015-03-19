// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBStaticLayoutComponent.h"

#import "ComponentUtilities.h"
#import "FBComponentLayout.h"
#import "FBComponentSubclass.h"

@implementation FBStaticLayoutComponent
{
  std::vector<FBStaticLayoutComponentChild> _children;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                       size:(const FBComponentSize &)size
                   children:(const std::vector<FBStaticLayoutComponentChild> &)children
{
  FBStaticLayoutComponent *c = [super newWithView:view size:size];
  if (c) {
    c->_children = children;
  }
  return c;
}

+ (instancetype)newWithChildren:(const std::vector<FBStaticLayoutComponentChild> &)children
{
  return [self newWithView:{} size:{} children:children];
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  CGSize size = {
    isinf(constrainedSize.max.width) ? kFBComponentParentDimensionUndefined : constrainedSize.max.width,
    isinf(constrainedSize.max.height) ? kFBComponentParentDimensionUndefined : constrainedSize.max.height
  };

  auto layoutChildren = FB::map(_children, [&constrainedSize, &size](FBStaticLayoutComponentChild child) {

    CGSize autoMaxSize = {
      constrainedSize.max.width - child.position.x,
      constrainedSize.max.height - child.position.y
    };
    FBSizeRange childConstraint = child.size.resolveSizeRange(size, {{0,0}, autoMaxSize});
    return FBComponentLayoutChild({child.position, [child.component layoutThatFits:childConstraint
                                                                        parentSize:size]});
  });

  if (isnan(size.width)) {
    size.width = constrainedSize.min.width;
    for (auto &child : layoutChildren) {
      size.width = MAX(size.width, child.position.x + child.layout.size.width);
    }
  }

  if (isnan(size.height)) {
    size.height = constrainedSize.min.height;
    for (auto &child : layoutChildren) {
      size.height = MAX(size.height, child.position.y + child.layout.size.height);
    }
  }

  return {self, constrainedSize.clamp(size), layoutChildren};
}

@end
