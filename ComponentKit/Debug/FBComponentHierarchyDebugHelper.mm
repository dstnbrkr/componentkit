// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentHierarchyDebugHelper.h"

#import <UIKit/UIKit.h>

#import "FBComponent.h"
#import "FBComponentInternal.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentLifecycleManagerInternal.h"
#import "FBComponentViewInterface.h"

@implementation FBComponentHierarchyDebugHelper

+ (NSString *)componentHierarchyDescription
{
  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  return [[self class] componentHierarchyDescriptionForView:window searchUpwards:NO];
}

+ (NSString *)componentHierarchyDescriptionForView:(UIView *)view searchUpwards:(BOOL)upwards
{
  if (upwards) {
    while (view && !view.fb_componentLifecycleManager) {
      view = view.superview;
    }

    if (!view) {
      return @"Didn't find any components";
    }
  }
  return (FBRecursiveComponentHierarchyDescription(view) ?: @"Didn't find any components");
}

static NSString *FBRecursiveComponentHierarchyDescription(UIView *view)
{
  if (view.fb_componentLifecycleManager) {
    return [NSString stringWithFormat:@"For View: %@\n%@", view, FBComponentHierarchyDescription(view)];
  } else {
    NSMutableArray *array = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
      NSString *subviewDescription = FBRecursiveComponentHierarchyDescription(subview);
      if (subviewDescription) {
        [array addObject:subviewDescription];
      }
    }
    return array.count ? [array componentsJoinedByString:@"\n\n"] : nil;
  }
}

static NSString *FBComponentHierarchyDescription(UIView *view)
{
  FBComponentLayout layout = [view.fb_componentLifecycleManager state].layout;
  NSMutableArray *description = [[NSMutableArray alloc] init];
  FBBuildComponentHierarchyDescription(description, layout, {0, 0}, @"");
  return [description componentsJoinedByString:@"\n"];
}

static void FBBuildComponentHierarchyDescription(NSMutableArray *result, const FBComponentLayout &layout, CGPoint position, NSString *prefix)
{
  [result addObject:[NSString stringWithFormat:@"%@%@, Position: %@, Size: %@",
                     prefix,
                     layout.component,
                     NSStringFromCGPoint(position),
                     NSStringFromCGSize(layout.size)]];

  for (const auto &child : *layout.children) {
    FBBuildComponentHierarchyDescription(result,
                                         child.layout,
                                         child.position,
                                         [NSString stringWithFormat:@"| %@", prefix]);
  }
}

@end
