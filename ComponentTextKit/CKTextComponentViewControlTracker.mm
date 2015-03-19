// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTextComponentViewControlTracker.h"

#import <FBComponentKit/CKTextKitRenderer+Positioning.h>
#import <FBComponentKit/CKTextKitRenderer+TextChecking.h>

#import "CKTextComponentLayer.h"
#import "CKTextComponentLayerHighlighter.h"
#import "CKTextComponentViewInternal.h"

@implementation CKTextComponentViewControlTracker
{
  NSTextCheckingResult *_trackingTextCheckingResult;
}

/**
 sendActionsForControlEvents: calls sendAction:to:forEvent: with a nil event, so provide this alternate method to supply
 the event to the targets
 */
- (void)_sendActionsToControl:(UIControl *)control forControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent *)event
{
  for (id target in control.allTargets) {
    id realTarget = (target == [NSNull null]) ? nil : target;
    for (NSString *actionName in [control actionsForTarget:realTarget forControlEvent:controlEvents]) {
      [control sendAction:NSSelectorFromString(actionName) to:realTarget forEvent:event];
    }
  }
}

- (BOOL)beginTrackingForTextComponentView:(CKTextComponentView *)view
                                withTouch:(UITouch *)touch
                                withEvent:(UIEvent *)event
{
  CGPoint point = [touch locationInView:view];
  NSTextCheckingResult *trackingTextCheckingResult = [view.renderer textCheckingResultAtPoint:point];
  if (trackingTextCheckingResult != nil) {
    view.textLayer.highlighter.highlightedRange = trackingTextCheckingResult.range;
    [self _sendActionsToControl:view forControlEvents:CKUIControlEventTextViewDidBeginHighlightingText withEvent:event];
    _trackingTextCheckingResult = trackingTextCheckingResult;
  }
  return YES;
}

- (BOOL)continueTrackingForTextComponentView:(CKTextComponentView *)view
                                   withTouch:(UITouch *)touch
                                   withEvent:(UIEvent *)event
{
  if (_trackingTextCheckingResult) {
    CGPoint point = [touch locationInView:view];
    NSUInteger index = [view.renderer nearestTextIndexAtPosition:point];
    NSRange range = _trackingTextCheckingResult.range;
    if (!NSLocationInRange(index, range)) {
      [view cancelTrackingWithEvent:event];
      return NO;
    }
  }

  return YES;
}

- (void)endTrackingForTextComponentView:(CKTextComponentView *)view
                              withTouch:(UITouch *)touch
                              withEvent:(UIEvent *)event
{
  if (_trackingTextCheckingResult != nil) {
    _trackingTextCheckingResult = nil;
    if (touch != nil) {
      [self _sendActionsToControl:view forControlEvents:CKUIControlEventTextViewDidEndHighlightingText withEvent:event];
    }
    view.textLayer.highlighter.highlightedRange = CKTextComponentLayerInvalidHighlightRange;
  }
}

- (void)cancelTrackingForTextComponentView:(CKTextComponentView *)view
                                 withEvent:(UIEvent *)event
{
  if (_trackingTextCheckingResult != nil) {
    _trackingTextCheckingResult = nil;
    [self _sendActionsToControl:view forControlEvents:CKUIControlEventTextViewDidCancelHighlightingText withEvent:event];
    view.textLayer.highlighter.highlightedRange = CKTextComponentLayerInvalidHighlightRange;
  }
}

@end
