// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponent.h"
#import "FBComponentControllerInternal.h"
#import "FBComponentInternal.h"
#import "FBComponentScopeInternal.h"
#import "FBComponentSubclass.h"

#import <FBComponentKit/CKArgumentPrecondition.h>
#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "CKInternalHelpers.h"
#import "CKWeakObjectContainer.h"
#import "ComponentLayoutContext.h"
#import "FBComponentAccessibility.h"
#import "FBComponentAnimation.h"
#import "FBComponentController.h"
#import "FBComponentDebugController.h"
#import "FBComponentLayout.h"
#import "FBComponentScopeFrame.h"
#import "FBComponentViewConfiguration.h"
#import "FBComponentViewInterface.h"

#import <FBBase/FBAssert.h>

CGFloat const kFBComponentParentDimensionUndefined = NAN;
CGSize const kFBComponentParentSizeUndefined = {kFBComponentParentDimensionUndefined, kFBComponentParentDimensionUndefined};

struct FBComponentMountInfo {
  FBComponent *supercomponent;
  UIView *view;
  FBComponentViewContext viewContext;
};

@implementation FBComponent
{
  FBComponentScopeFrame *_scopeFrame;
  FBComponentViewConfiguration _viewConfiguration;
  FBComponentSize _size;

  /** Only non-null while mounted. */
  std::unique_ptr<FBComponentMountInfo> _mountInfo;
}

#if DEBUG
+ (void)initialize
{
  FBConditionalAssert(self != [FBComponent class],
                      !CKSubclassOverridesSelector([FBComponent class], self, @selector(layoutThatFits:parentSize:)),
                      @"%@ overrides -layoutThatFits:parentSize: which is not allowed. Override -computeLayoutThatFits: "
                      "or -computeLayoutThatFits:restrictedToSize:relativeToParentSize: instead.",
                      self);
}
#endif

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view size:(const FBComponentSize &)size
{
  return [[self alloc] initWithView:view size:size];
}

+ (instancetype)new
{
  return [self newWithView:{} size:{}];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithView:(const FBComponentViewConfiguration &)view
                        size:(const FBComponentSize &)size
{
  if (self = [super init]) {
    _scopeFrame = FBComponentScopeFrameForComponent(self);
    _viewConfiguration = view;
    _size = size;
  }
  return self;
}

- (void)dealloc
{
  // Since the component and its view hold strong references to each other, this should never happen!
  CKAssert(_mountInfo == nullptr, @"%@ must be unmounted before dealloc", [self class]);
}

- (const FBComponentViewConfiguration &)viewConfiguration
{
  return _viewConfiguration;
}

- (FBComponentViewContext)viewContext
{
  return _mountInfo ? _mountInfo->viewContext : FBComponentViewContext();
}

#pragma mark - Mounting and Unmounting

- (FB::Component::MountResult)mountInContext:(const FB::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<FBComponentLayoutChild>>)children
                              supercomponent:(FBComponent *)supercomponent
{
  // Taking a const ref to a temporary extends the lifetime of the temporary to the lifetime of the const ref
  const FBComponentViewConfiguration &viewConfiguration = FB::Component::Accessibility::IsAccessibilityEnabled() ? FB::Component::Accessibility::AccessibleViewConfiguration(_viewConfiguration) : _viewConfiguration;

  if (_mountInfo == nullptr) {
    _mountInfo.reset(new FBComponentMountInfo());
  }
  _mountInfo->supercomponent = supercomponent;

  FBComponentController *controller = _scopeFrame.controller;
  [controller componentWillMount:self];

  const FB::Component::MountContext &effectiveContext = [FBComponentDebugController debugMode]
  ? FBDebugMountContext([self class], context, _viewConfiguration, size) : context;

  UIView *v = effectiveContext.viewManager->viewForConfiguration([self class], viewConfiguration);
  if (v) {
    if (_mountInfo->view != v) {
      [self _relinquishMountedView]; // First release our old view
      [v.fb_component unmount];      // Then unmount old component (if any) from the new view
      v.fb_component = self;
      FB::Component::AttributeApplicator::apply(v, viewConfiguration);
      [controller component:self didAcquireView:v];
      _mountInfo->view = v;
    } else {
      CKAssert(v.fb_component == self, @"");
    }

    const CGPoint anchorPoint = v.layer.anchorPoint;
    [v setCenter:effectiveContext.position + CGPoint({size.width * anchorPoint.x, size.height * anchorPoint.y})];
    [v setBounds:{v.bounds.origin, size}];

    _mountInfo->viewContext = {v, {{0,0}, v.bounds.size}};
    return {.mountChildren = YES, .contextForChildren = effectiveContext.childContextForSubview(v)};
  } else {
    CKAssertNil(_mountInfo->view, @"Didn't expect to sometimes have a view and sometimes not have a view");
    _mountInfo->viewContext = {effectiveContext.viewManager->view, {effectiveContext.position, size}};
    return {.mountChildren = YES, .contextForChildren = effectiveContext};
  }
}

- (void)unmount
{
  if (_mountInfo != nullptr) {
    [_scopeFrame.controller componentWillUnmount:self];
    [self _relinquishMountedView];
    _mountInfo.reset();
    [_scopeFrame.controller componentDidUnmount:self];
  }
}

- (void)_relinquishMountedView
{
  UIView *view = _mountInfo->view;
  if (view) {
    CKAssert(view.fb_component == self, @"");
    [_scopeFrame.controller component:self willRelinquishView:view];
    view.fb_component = nil;
    _mountInfo->view = nil;
  }
}

- (void)childrenDidMount
{
  [_scopeFrame.controller componentDidMount:self];
}

#pragma mark - Animation

- (std::vector<FBComponentAnimation>)animationsFromPreviousComponent:(FBComponent *)previousComponent
{
  return {};
}

- (FBComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(FBComponent *)previousComponent
{
  return {};
}

- (UIView *)viewForAnimation
{
  return _mountInfo ? _mountInfo->view : nil;
}

#pragma mark - Layout

- (FBComponentLayout)layoutThatFits:(FBSizeRange)constrainedSize parentSize:(CGSize)parentSize
{
  FB::Component::LayoutContext context(self, constrainedSize);
  FBComponentLayout layout = [self computeLayoutThatFits:constrainedSize
                                        restrictedToSize:_size
                                    relativeToParentSize:parentSize];
  CKAssert(layout.component == self, @"Layout computed by %@ should return self as component, but returned %@",
           [self class], [layout.component class]);
  FBSizeRange resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  CKAssert(layout.size.width <= resolvedRange.max.width
           && layout.size.width >= resolvedRange.min.width
           && layout.size.height <= resolvedRange.max.height
           && layout.size.height >= resolvedRange.min.height,
           @"Computed size %@ for %@ does not fall within constrained size %@\n%@",
           NSStringFromCGSize(layout.size), [self class], resolvedRange.description(),
           FB::Component::LayoutContext::currentStackDescription());
  return layout;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
                          restrictedToSize:(const FBComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  FBSizeRange resolvedRange = constrainedSize.intersect(_size.resolve(parentSize));
  return [self computeLayoutThatFits:resolvedRange];
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  CKAssert(!isinf(constrainedSize.max.width) && !isinf(constrainedSize.max.height),
           @"%@ may not be passed an infinite max size (%@)\n%@",
           NSStringFromClass([self class]),
           NSStringFromCGSize(constrainedSize.max),
           FB::Component::LayoutContext::currentStackDescription());
  return {self, constrainedSize.max};
}

- (id)nextResponder
{
  return _scopeFrame.controller ?: [self nextResponderAfterController];
}

- (id)nextResponderAfterController
{
  return (_mountInfo ? _mountInfo->supercomponent : nil) ?: [self rootComponentMountedView];
}

- (id)targetForAction:(SEL)action withSender:(id)sender
{
  return [self respondsToSelector:action] ? self : [[self nextResponder] targetForAction:action withSender:sender];
}

// Because only the root component in each mounted tree will have a non-nil rootComponentMountedView, we use Obj-C
// associated objects to save the memory overhead of storing such a pointer on every single FBComponent instance in
// the app. With tens of thousands of component instances, this adds up to several KB.
static void *kRootComponentMountedViewKey = &kRootComponentMountedViewKey;

- (void)setRootComponentMountedView:(UIView *)rootComponentMountedView
{
  ck_objc_setNonatomicAssociatedWeakObject(self, kRootComponentMountedViewKey, rootComponentMountedView);
}

- (UIView *)rootComponentMountedView
{
  return ck_objc_getAssociatedWeakObject(self, kRootComponentMountedViewKey);
}

#pragma mark - State

+ (id)initialState
{
  return nil;
}

- (void)updateState:(id (^)(id))updateBlock
{
  [self _updateState:updateBlock tryAsynchronousUpdate:NO];
}

- (void)updateStateWithExpensiveReflow:(id (^)(id))updateBlock
{
  [self _updateState:updateBlock tryAsynchronousUpdate:YES];
}

- (void)_updateState:(id (^)(id))updateBlock tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  CKAssert(_scopeFrame != nullptr, @"A component without state cannot update its state.");
  CKAssert(updateBlock != nil, @"Cannot enqueue component state modification with a nil block.");
  [_scopeFrame updateState:updateBlock tryAsynchronousUpdate:tryAsynchronousUpdate];
}

- (FBComponentController *)controller
{
  return _scopeFrame.controller;
}

- (id)scopeFrameToken
{
  return _scopeFrame;
}

@end
