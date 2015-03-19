// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

/** Exposed only for testing. Do not touch this directly. */
@interface FBComponentGestureActionForwarder : NSObject
+ (instancetype)sharedInstance;
- (void)handleGesture:(UIGestureRecognizer *)recognizer;
@end

/** Exposed only for testing. Do not touch this directly. */
@interface UIGestureRecognizer (FBComponent)
- (FBComponentAction)fb_componentAction;
- (void)fb_setComponentAction:(FBComponentAction)action;
@end
