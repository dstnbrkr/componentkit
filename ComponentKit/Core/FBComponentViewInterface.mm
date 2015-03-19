// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentViewInterface.h"

#import <objc/runtime.h>

#import "CKWeakObjectContainer.h"

static char const kViewComponentKey = ' ';
static char const kViewComponentLifecycleManagerKey = ' ';

@implementation UIView (FBComponent)

- (FBComponent *)fb_component
{
  return objc_getAssociatedObject(self, &kViewComponentKey);
}

- (void)fb_setComponent:(FBComponent *)component
{
  objc_setAssociatedObject(self, &kViewComponentKey, component, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FBComponentLifecycleManager *)fb_componentLifecycleManager
{
  return ck_objc_getAssociatedWeakObject(self, (void *)&kViewComponentLifecycleManagerKey);
}

- (void)fb_setComponentLifecycleManager:(FBComponentLifecycleManager *)clm
{
  ck_objc_setAssociatedWeakObject(self, (void *)&kViewComponentLifecycleManagerKey, clm);
}

@end
