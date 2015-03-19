// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTextComponentViewInternal.h"

/**
 A default control tracking implementation.
 */
@interface CKTextComponentViewControlTracker : NSObject

- (BOOL)beginTrackingForTextComponentView:(CKTextComponentView *)view
                                withTouch:(UITouch *)touch
                                withEvent:(UIEvent *)event;

- (BOOL)continueTrackingForTextComponentView:(CKTextComponentView *)view
                                   withTouch:(UITouch *)touch
                                   withEvent:(UIEvent *)event;

- (void)endTrackingForTextComponentView:(CKTextComponentView *)view
                              withTouch:(UITouch *)touch
                              withEvent:(UIEvent *)event;

- (void)cancelTrackingForTextComponentView:(CKTextComponentView *)view
                                 withEvent:(UIEvent *)event;

@end
