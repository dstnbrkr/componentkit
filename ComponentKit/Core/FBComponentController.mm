// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentController.h"
#import "FBComponentControllerInternal.h"

#import <FBComponentKit/CKAssert.h>

#import "FBComponentInternal.h"
#import "FBComponentSubclass.h"

struct FBPendingComponentAnimation {
  FBComponentAnimation animation;
  id context; // The context returned by the animation's willRemount block.
};

struct FBAppliedComponentAnimation {
  FBComponentAnimation animation;
  id context; // The context returned by the animation's didRemount block.
};

typedef NS_ENUM(NSUInteger, FBComponentControllerState) {
  FBComponentControllerStateUnmounted = 0,
  FBComponentControllerStateMounting,
  FBComponentControllerStateMounted,
  FBComponentControllerStateRemounting,
  FBComponentControllerStateUnmounting,
};

@implementation FBComponentController
{
  FBComponentControllerState _state;
  BOOL _updatingComponent;
  FBComponent *_previousComponent;
  std::vector<FBPendingComponentAnimation> _pendingAnimations;
  std::vector<FBAppliedComponentAnimation> _appliedAnimations;
}

- (void)willMount {}
- (void)didMount {}
- (void)willRemount {}
- (void)didRemount {}
- (void)willUnmount {}
- (void)didUnmount {}
- (void)willUpdateComponent {}
- (void)didUpdateComponent {}
- (void)componentWillRelinquishView {}
- (void)componentDidAcquireView {}
- (void)componentTreeWillAppear {}
- (void)componentTreeDidDisappear {}

#pragma mark - Hooks

- (void)componentWillMount:(FBComponent *)component
{
  if (component != _component) {
    [self willUpdateComponent];
    _previousComponent = _component;
    _component = component;
    _updatingComponent = YES;
  }

  switch (_state) {
    case FBComponentControllerStateUnmounted:
      _state = FBComponentControllerStateMounting;
      [self willMount];
      break;
    case FBComponentControllerStateMounted:
      _state = FBComponentControllerStateRemounting;
      [self willRemount];
      if (_previousComponent) { // Only animate if updating from an old component to a new one, and previously mounted
        for (const auto &animation : [component animationsFromPreviousComponent:_previousComponent]) {
          _pendingAnimations.push_back({animation, animation.willRemount()});
        }
      }
      break;
    default:
      CKFailAssert(@"Unexpected state %d in %@ (%@)", _state, [self class], _component);
  }
}

- (void)componentDidMount:(FBComponent *)component
{
  switch (_state) {
    case FBComponentControllerStateMounting:
      _state = FBComponentControllerStateMounted;
      [self didMount];
      break;
    case FBComponentControllerStateRemounting:
      _state = FBComponentControllerStateMounted;
      [self didRemount];
      for (const auto &pendingAnimation : _pendingAnimations) {
        const FBComponentAnimation &anim = pendingAnimation.animation;
        _appliedAnimations.push_back({anim, anim.didRemount(pendingAnimation.context)});
      }
      _pendingAnimations.clear();
      break;
    default:
      CKFailAssert(@"Unexpected state %d in %@ (%@)", _state, [self class], _component);
  }

  if (_updatingComponent) {
    [self didUpdateComponent];
    _previousComponent = nil;
    _updatingComponent = NO;
  }
}

- (void)componentWillUnmount:(FBComponent *)component
{
  switch (_state) {
    case FBComponentControllerStateMounted:
      // The "old" version of a component may be unmounted after the new version has finished remounting.
      if (component == _component) {
        _state = FBComponentControllerStateUnmounting;
        [self willUnmount];
        [self _cleanupAppliedAnimations];
      }
      break;
    case FBComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounting during remount");
      break;
    default:
      CKFailAssert(@"Unexpected state %d in %@ (%@)", _state, [self class], _component);
  }
}

- (void)componentDidUnmount:(FBComponent *)component
{
  switch (_state) {
    case FBComponentControllerStateUnmounting:
      CKAssert(component == _component, @"Unexpected component mismatch during unmount from unmounting");
      _state = FBComponentControllerStateUnmounted;
      [self didUnmount];
      break;
    case FBComponentControllerStateRemounting:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounted during remount");
      break;
    case FBComponentControllerStateMounted:
      CKAssert(component != _component, @"Didn't expect the new component to be unmounted while mounted");
      break;
    default:
      CKFailAssert(@"Unexpected state %d in %@ (%@)", _state, [self class], _component);
  }
}

- (void)_relinquishView
{
  [self componentWillRelinquishView];
  [self _cleanupAppliedAnimations];
  _view = nil;
}

- (void)_cleanupAppliedAnimations
{
  for (const auto &appliedAnimation : _appliedAnimations) {
    appliedAnimation.animation.cleanup(appliedAnimation.context);
  }
  _appliedAnimations.clear();
}

- (void)component:(FBComponent *)component willRelinquishView:(UIView *)view
{
  if (component == _component) {
    CKAssert(view == _view, @"Didn't expect to be relinquishing view %@ when _view is %@", view, _view);
    [self _relinquishView];
  }
}

- (void)component:(FBComponent *)component didAcquireView:(UIView *)view
{
  if (component == _component) {
    if (view != _view) {
      if (_view) {
        CKAssertNotNil(_previousComponent, @"Only expect to acquire a new view before relinquishing old if updating");
        [self _relinquishView];
      }
      _view = view;
      [self componentDidAcquireView];
    }
  }
}

- (id)nextResponder
{
  return [_component nextResponderAfterController];
}

- (id)targetForAction:(SEL)action withSender:(id)sender
{
  return [self respondsToSelector:action] ? self : [[self nextResponder] targetForAction:action withSender:sender];
}

@end
