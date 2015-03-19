// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentHostingView.h"
#import "FBComponentHostingViewInternal.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "FBComponentAnimation.h"
#import "FBComponentHostingViewDelegate.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentLifecycleManager_Private.h"
#import "FBComponentSizeRangeProviding.h"

@interface FBComponentHostingView () <FBComponentLifecycleManagerDelegate>
{
  FBComponentLifecycleManager *_lifecycleManager;
  id<FBComponentSizeRangeProviding> _sizeRangeProvider;
  UIView *_containerView;
  BOOL _isUpdating;
}
@end

@implementation FBComponentHostingView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                   model:(id<NSObject>)model
                           containerView:(UIView *)containerView
{
  if (self = [super initWithFrame:CGRectZero]) {
    // Injected dependencies
    _sizeRangeProvider = sizeRangeProvider;
    _model = model;

    // Internal dependencies
    _lifecycleManager = manager;
    _lifecycleManager.delegate = self;

    _containerView = containerView;
    [self addSubview:_containerView];
  }
  return self;
}

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                   model:(id<NSObject>)model
{
  return [self initWithLifecycleManager:manager
                      sizeRangeProvider:sizeRangeProvider
                                  model:model
                          containerView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                        sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                  context:(id<NSObject>)context
{
  FBComponentLifecycleManager *manager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:componentProvider context:context sizeRangeProvider:sizeRangeProvider];
  return [self initWithLifecycleManager:manager sizeRangeProvider:sizeRangeProvider model:nil];
}

- (void)dealloc
{
  [_lifecycleManager detachFromView];
}

#pragma mark - Layout

- (void)layoutSubviews
{
  [super layoutSubviews];
  _containerView.frame = self.bounds;

  if (_model && !CGRectIsEmpty(self.bounds)) {
    [self _update];

    if (![_lifecycleManager isAttachedToView]) {
      [_lifecycleManager attachToView:_containerView];
    }
  }
}

- (CGSize)sizeThatFits:(CGSize)size
{
  FBSizeRange constrainedSize = [_sizeRangeProvider sizeRangeForBoundingSize:size];
  FBComponentLifecycleManagerState state = [_lifecycleManager prepareForUpdateWithModel:_model constrainedSize:constrainedSize];
  return state.layout.size;
}

#pragma mark - Accessors

- (void)setModel:(id)model
{
  if (_model != model) {
    _model = model;
    CKAssertNotNil(_model, @"Model can not be nil.");

    [self setNeedsLayout];
  }
}

- (UIView *)containerView
{
  return _containerView;
}

#pragma mark - FBComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(FBComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const FBComponentBoundsAnimation &)animation
{
  [_delegate componentHostingViewDidInvalidateSize:self];
}

#pragma mark - Private

- (void)_update
{
  if (_isUpdating) {
    CKFailAssert(@"FBComponentHostingView -_update is not re-entrant. This is called by -layoutSubviews, so ensure that there is nothing that is triggering a nested call to -layoutSubviews. This call will be a no-op in production.");
    return;
  } else {
    _isUpdating = YES;
  }

  const CGRect bounds = self.bounds;
  FBComponentLifecycleManagerState state = [_lifecycleManager prepareForUpdateWithModel:_model constrainedSize:FBSizeRange(bounds.size, bounds.size)];
  [_lifecycleManager updateWithState:state];

  _isUpdating = NO;
}

@end
