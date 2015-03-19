// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentLifecycleManager.h"
#import "FBComponentLifecycleManagerInternal.h"
#import "FBComponentLifecycleManager_Private.h"

#import <stack>

#import <FBBase/fb-thread.h>

#import "FBComponent.h"
#import "FBComponentInternal.h"
#import "FBComponentLayout.h"
#import "FBComponentLifecycleManagerAsynchronousUpdateHandler.h"
#import "FBComponentProvider.h"
#import "FBComponentScope.h"
#import "FBComponentScopeInternal.h"
#import "FBComponentSizeRangeProviding.h"
#import "FBComponentSubclass.h"
#import "FBComponentViewInterface.h"
#import "FBDimension.h"

using FB::Component::MountContext;

const FBComponentLifecycleManagerState FBComponentLifecycleManagerStateEmpty = {
  .model = nil,
  .constrainedSize = {},
  .layout = {},
  .scopeFrame = nil,
};

@implementation FBComponentLifecycleManager
{
  UIView *_mountedView;
  NSSet *_mountedComponents;

  Class<FBComponentProvider> _componentProvider;
  id _context;
  id<FBComponentSizeRangeProviding> _sizeRangeProvider;

  FB::Mutex _previousScopeFrameMutex;
  FBComponentScopeFrame *_previouslyCalculatedScopeFrame;
  FBComponentLifecycleManagerState _state;
}

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id)context
{
  return [self initWithComponentProvider:componentProvider context:context sizeRangeProvider:nil];
}

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id)context
                        sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
{
  if (self = [super init]) {
    _componentProvider = componentProvider;
    _context = context;
    _sizeRangeProvider = sizeRangeProvider;
  }
  return self;
}

- (void)dealloc
{
  if (_mountedComponents) {
    NSSet *componentsToUnmount = _mountedComponents;
    dispatch_block_t unmountBlock = ^{
      for (FBComponent *c in componentsToUnmount) {
        [c unmount];
      }
    };

    if ([NSThread isMainThread]) {
      unmountBlock();
    } else {
      dispatch_async(dispatch_get_main_queue(), unmountBlock);
    }
  }
}

#pragma mark - Updates

- (FBComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(FBSizeRange)constrainedSize
{
  FB::MutexLocker locker(_previousScopeFrameMutex);

  FBBuildComponentResult result = FBBuildComponent(self, _previouslyCalculatedScopeFrame, ^{
    return [_componentProvider componentForModel:model context:_context];
  });

  const FBComponentLayout layout = [result.component layoutThatFits:constrainedSize parentSize:constrainedSize.max];

  _previouslyCalculatedScopeFrame = result.scopeFrame;
  return {
    .model = model,
    .constrainedSize = constrainedSize,
    .layout = layout,
    .scopeFrame = result.scopeFrame,
    .boundsAnimation = result.boundsAnimation,
  };
}

- (void)updateWithState:(const FBComponentLifecycleManagerState &)state
{
  BOOL sizeChanged = !CGSizeEqualToSize(_state.layout.size, state.layout.size);
  [self updateWithStateWithoutMounting:state];

  // Since the state has been updated, re-mount the view if it exists.
  if (_mountedView != nil) {
    [self _mountLayout];
  }

  if (sizeChanged) {
    [_delegate componentLifecycleManager:self sizeDidChangeWithAnimation:state.boundsAnimation];
  }
}

- (void)updateWithStateWithoutMounting:(const FBComponentLifecycleManagerState &)state
{
  _state = state;
}

#pragma mark - Mount/Unmount

- (void)_mountLayout
{
  NSSet *newMountedComponents = FBMountComponentLayout(_state.layout, _mountedView);
  _state.layout.component.rootComponentMountedView = _mountedView;

  // Unmount any components that were in _mountedComponents but are no longer in newMountedComponents.
  NSMutableSet *componentsToUnmount = [_mountedComponents mutableCopy];
  [componentsToUnmount minusSet:newMountedComponents];
  for (FBComponent *component in componentsToUnmount) {
    [component unmount];
  }
  _mountedComponents = [newMountedComponents copy];
}

- (void)attachToView:(UIView *)view
{
  if (view.fb_componentLifecycleManager != self) {
    /*
     It is possible that another lifecycleManager is already attached to the view
     on which we're trying to attach this lifecycleManager.
     If it is not the lifecycleManager we are trying to attach, we need to detach
     the other lifecycleManager first before attaching this one. We also need
     to detach this lifecycle manager from its current mounted view!
     */
    [self detachFromView];
    [view.fb_componentLifecycleManager detachFromView];
    _mountedView = view;
    view.fb_componentLifecycleManager = self;
  }
  [self _mountLayout];
}

- (void)detachFromView
{
  if (_mountedView) {
    CKAssert(_mountedView.fb_componentLifecycleManager == self, @"");
    for (FBComponent *component in _mountedComponents) {
      [component unmount];
    }
    _mountedComponents = nil;
    _mountedView.fb_componentLifecycleManager = nil;
    _mountedView = nil;
  }
}

- (BOOL)isAttachedToView
{
  return (_mountedView != nil);
}

#pragma mark - Miscellaneous

- (CGSize)size
{
  return _state.layout.size;
}

- (id)model
{
  return _state.model;
}

- (void)componentTreeWillAppear
{
  [_state.scopeFrame announceEventToControllers:@selector(componentTreeWillAppear)];
}

- (void)componentTreeDidDisappear
{
  [_state.scopeFrame announceEventToControllers:@selector(componentTreeDidDisappear)];
}

#pragma mark - FBComponentStateListener

- (void)componentStateDidEnqueueStateModificationWithTryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  if (tryAsynchronousUpdate && _asynchronousUpdateHandler) {
    [_asynchronousUpdateHandler handleAsynchronousUpdateForComponentLifecycleManager:self];
  } else {
    const FBSizeRange constrainedSize = _sizeRangeProvider ? [_sizeRangeProvider sizeRangeForBoundingSize:_state.constrainedSize.max] : _state.constrainedSize;
    [self updateWithState:[self prepareForUpdateWithModel:_state.model constrainedSize:constrainedSize]];
  }
}

#pragma mark - Debug

- (FBComponentLifecycleManagerState)state
{
  return _state;
}

@end
