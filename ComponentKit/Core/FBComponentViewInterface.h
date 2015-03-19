// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <UIKit/UIKit.h>

@class FBComponent;
@class FBComponentLifecycleManager;

@interface UIView (FBComponent)

/** Strong reference back to the associated component while the component is mounted. */
@property (nonatomic, strong, setter=fb_setComponent:) FBComponent *fb_component;

/** Weak reference to the associated lifecycle manager. Only set on the root view. */
@property (nonatomic, weak, setter=fb_setComponentLifecycleManager:) FBComponentLifecycleManager *fb_componentLifecycleManager;

@end
