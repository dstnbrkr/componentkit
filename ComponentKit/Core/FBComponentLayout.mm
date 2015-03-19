// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentLayout.h"

#import <stack>

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "ComponentUtilities.h"
#import "FBComponentInternal.h"

using namespace FB::Component;

void FBOffMainThreadDeleter::operator()(std::vector<FBComponentLayoutChild> *target)
{
  if ([NSThread isMainThread]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      delete target;
    });
  } else {
    delete target;
  }
}

static CGRect unionRects(CGRect rect, CGPoint position, const std::vector<FBComponentLayoutChild> &children)
{
  for (auto &child : children) {
    CGPoint childPosition = position + child.position;
    rect = CGRectUnion({childPosition, child.layout.size}, unionRects(rect, childPosition, *child.layout.children));
  }
  return rect;
}

BOOL FBComponentLayoutHasOverflow(const FBComponentLayout &layout)
{
  // This function could be optimized significantly by aborting early as soon as we detect overflow.
  return CGRectContainsRect({CGPointZero, layout.size}, unionRects(CGRectNull, CGPointZero, *layout.children)) ? NO : YES;
}

NSSet *FBMountComponentLayout(const FBComponentLayout &layout, UIView *view, FBComponent *supercomponent)
{
  struct MountItem {
    const FBComponentLayout &layout;
    MountContext mountContext;
    FBComponent *supercomponent;
    BOOL visited;
  };
  // Using a stack to mount ensures that the components are mounted
  // in a DFS fashion which is handy if you want to animate a subpart
  // of the tree
  std::stack<MountItem> stack;
  stack.push({layout, MountContext::RootContext(view), supercomponent, NO});
  NSMutableSet *mountedComponents = [NSMutableSet set];

  while (!stack.empty()) {
    MountItem &item = stack.top();
    if (item.visited) {
      [item.layout.component childrenDidMount];
      stack.pop();
    } else {
      item.visited = YES;
      if (item.layout.component == nil) {
        continue; // Nil components in a layout struct are invalid, but handle them gracefully
      }
      const MountResult mountResult = [item.layout.component mountInContext:item.mountContext
                                                                       size:item.layout.size
                                                                   children:item.layout.children
                                                             supercomponent:item.supercomponent];
      [mountedComponents addObject:item.layout.component];

      if (mountResult.mountChildren) {
        // Ordering of components should correspond to ordering of mount. Push components on backwards so the
        // bottom-most component is mounted first.
        for (auto riter = item.layout.children->rbegin(); riter != item.layout.children->rend(); riter ++) {
          stack.push({riter->layout, mountResult.contextForChildren.offset(riter->position, item.layout.size, riter->layout.size), item.layout.component, NO});
        }
      }
    }
  }
  return mountedComponents;
}
