// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentDebugController.h"

#import <UIKit/UIKit.h>

#import <FBBase/fb-thread.h>

#import "FBComponent.h"
#import "FBComponentAnimation.h"
#import "FBComponentInternal.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentLifecycleManagerInternal.h"
#import "FBComponentViewInterface.h"

/** Posted on the main thread when debug mode changes. Currently not exposed publicly. */
static NSString *const FBComponentDebugModeDidChangeNotification = @"FBComponentDebugModeDidChangeNotification";

@interface FBComponentDebugView : UIView
@end

@implementation FBComponentDebugView
{
  BOOL _selfDestructOnHiding;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:0.1];
    self.layer.borderColor = [UIColor colorWithRed:0.2 green:0.7 blue: 0.6 alpha: 0.5].CGColor;
    if ([UIScreen mainScreen].scale > 1) {
      self.layer.borderWidth = 0.5f;
    } else {
      self.layer.borderWidth = 1.0f;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(debugModeDidChange) name:FBComponentDebugModeDidChangeNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)debugModeDidChange
{
  if ([FBComponentDebugController debugMode]) {
    _selfDestructOnHiding = NO;
  } else {
    if ([self isHidden]) {
      [self removeFromSuperview];
    } else {
      // We make a best-effort to "reflow" all visible components when toggling debug mode, but this doesn't affect
      // off-window components. Wait to self-destruct until the debug view is hidden for reuse.
      _selfDestructOnHiding = YES;
    }
  }
}

- (void)setHidden:(BOOL)hidden
{
  [super setHidden:hidden];
  if (_selfDestructOnHiding && hidden) {
    [self removeFromSuperview];
  }
}

@end

@implementation FBComponentDebugController

static BOOL _debugMode;

#pragma mark - dcomponents / Debug Views For Components

+ (void)setDebugMode:(BOOL)debugMode
{
  _debugMode = debugMode;
  [self reflowComponents];
  [[NSNotificationCenter defaultCenter] postNotificationName:FBComponentDebugModeDidChangeNotification object:self];
}

+ (BOOL)debugMode
{
  return _debugMode;
}

FB::Component::MountContext FBDebugMountContext(Class componentClass,
                                                const FB::Component::MountContext &context,
                                                const FBComponentViewConfiguration &viewConfiguration,
                                                const CGSize size)
{
  if (viewConfiguration.viewClass().hasView()) {
    return context; // no need for a debug view if the component has a view.
  }

  static FB::StaticMutex l = FB_MUTEX_INITIALIZER;
  FB::StaticMutexLocker lock(l);

  // This is a pointer because of https://our.intern.facebook.com/intern/dex/qa/657083164365634/
  static std::unordered_map<Class, FBComponentViewConfiguration> *debugViewConfigurations =
  new std::unordered_map<Class, FBComponentViewConfiguration>();

  auto it = debugViewConfigurations->find(componentClass);
  if (it == debugViewConfigurations->end()) {
    NSString *debugViewClassName = [NSStringFromClass(componentClass) stringByAppendingString:@"View_Debug"];
    CKCAssertNil(NSClassFromString(debugViewClassName), @"Didn't expect class to already exist");
    Class debugViewClass = objc_allocateClassPair([FBComponentDebugView class], [debugViewClassName UTF8String], 0);
    CKCAssertNotNil(debugViewClass, @"Expected class to be created");
    objc_registerClassPair(debugViewClass);
    debugViewConfigurations->insert({componentClass, FBComponentViewConfiguration(debugViewClass)});
  }

  UIView *debugView = context.viewManager->viewForConfiguration(componentClass, debugViewConfigurations->at(componentClass));
  debugView.frame = {context.position, size};
  return context.childContextForSubview(debugView);
}

#pragma mark - Synchronous Reflow

+ (void)reflowComponents
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{ [self reflowComponents]; });
  } else {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    FBRecursiveComponentReflow(window);
  }
}

+ (void)reflowComponentsForView:(UIView *)view searchUpwards:(BOOL)upwards
{
  if (upwards) {
    while (view && !view.fb_componentLifecycleManager) {
      view = view.superview;
    }
    if (!view) {
      return;
    }
  }
  FBRecursiveComponentReflow(view);
}

static void FBRecursiveComponentReflow(UIView *view)
{
  if (view.fb_componentLifecycleManager) {
    FBComponentLifecycleManager *lifecycleManager = view.fb_componentLifecycleManager;
    FBComponentLifecycleManagerState oldState = [lifecycleManager state];
    FBComponentLifecycleManagerState state =
    [lifecycleManager prepareForUpdateWithModel:oldState.model
                                constrainedSize:oldState.constrainedSize];
    [lifecycleManager updateWithState:state];
  } else {
    for (UIView *subview in view.subviews) {
      FBRecursiveComponentReflow(subview);
    }
  }
}

@end
