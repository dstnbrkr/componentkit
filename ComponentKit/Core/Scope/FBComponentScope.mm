  // Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentScope.h"
#import "FBComponentScopeInternal.h"

#import <FBBase/FBTestEnvironmentCheck.h>

#import <unordered_map>
#import <vector>

#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "FBComponentController.h"
#import "FBComponentInternal.h"
#import "FBComponentScopeFrame.h"
#import "FBComponentSubclass.h"
#import "FBCompositeComponent.h"
#import "FBThreadLocalComponentScope.h"

#pragma mark - State Scope

FBBuildComponentResult FBBuildComponent(id<FBComponentStateListener> listener,
                                        FBComponentScopeFrame *previousRootFrame,
                                        FBComponent *(^function)(void))
{
  FBThreadLocalComponentScope threadScope(listener, previousRootFrame);
  // Order of operations matters, so first store into locals and then return a struct.
  FBComponent *component = function();
  FBComponentScopeFrame *newRootFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  return {
    .component = component,
    .scopeFrame = newRootFrame,
    .boundsAnimation = [newRootFrame boundsAnimationFromPreviousFrame:previousRootFrame],
  };
}

FBComponentScope::~FBComponentScope()
{
  FBThreadLocalComponentScope::cursor()->popFrame();
}

static Class FBComponentControllerClassForComponentClass(Class componentClass)
{
  static CK::StaticMutex mutex = CK_MUTEX_INITIALIZER; // protects cache
  CK::StaticMutexLocker l(mutex);

  static std::unordered_map<Class, Class> *cache = new std::unordered_map<Class, Class>();
  const auto &it = cache->find(componentClass);
  if (it == cache->end()) {
    Class c = NSClassFromString([NSStringFromClass(componentClass) stringByAppendingString:@"Controller"]);
    cache->insert({componentClass, c});
    return c;
  }
  return it->second;
}

static FBComponentController *_newController(Class componentClass)
{
  if (componentClass == [FBComponent class]) {
    return nil; // Don't create root FBComponentControllers as it does nothing interesting.
  }

  Class controllerClass = FBComponentControllerClassForComponentClass(componentClass);
  if (controllerClass) {
    CKCAssert([controllerClass isSubclassOfClass:[FBComponentController class]],
              @"%@ must inherit from FBComponentController", controllerClass);
    return [[controllerClass alloc] init];
  }

  // This is kinda hacky: if you override animationsFromPreviousComponent: then we need a controller.
  if (CKSubclassOverridesSelector([FBComponent class], componentClass, @selector(animationsFromPreviousComponent:))) {
    return [[FBComponentController alloc] init];
  }

  return nil;
}

FBComponentScope::FBComponentScope(Class __unsafe_unretained componentClass, id identifier, id (^initialStateCreator)(void))
{
  CKCAssert([componentClass isSubclassOfClass:[FBComponent class]],
            @"The componentClass must be a component but it is %@.", NSStringFromClass(componentClass));

  auto cursor = FBThreadLocalComponentScope::cursor();
  FBComponentScopeFrame *currentFrame = cursor->currentFrame();
  FBComponentScopeFrame *equivalentFrame = cursor->equivalentPreviousFrame();

  // Look for an equivalent scope in the previous scope tree matching the input identifiers.
  FBComponentScopeFrame *equivalentPreviousFrame =
  equivalentFrame ? [equivalentFrame existingChildFrameWithClass:componentClass identifier:identifier] : nil;

  id state = equivalentPreviousFrame ? equivalentPreviousFrame.updatedState : (initialStateCreator ? initialStateCreator() : [componentClass initialState]);
  FBComponentController *controller = equivalentPreviousFrame ? equivalentPreviousFrame.controller : _newController(componentClass);

  // Create the new scope.
  FBComponentScopeFrame *scopeFrame = [currentFrame childFrameWithComponentClass:componentClass
                                                                      identifier:identifier
                                                                           state:state
                                                                      controller:controller];

  // Set the new scope to be the "current", top-level scope.
  FBThreadLocalComponentScope::cursor()->pushFrameAndEquivalentPreviousFrame(scopeFrame, equivalentPreviousFrame);

  _scopeFrame = scopeFrame;
}

#pragma mark - State

id FBComponentScope::state() const
{
  return _scopeFrame.state;
}

FBComponentScopeFrame *FBComponentScopeFrameForComponent(FBComponent *component)
{
  FBComponentScopeFrame *currentFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  if (currentFrame.componentClass == [component class]) {
    if (!currentFrame.acquired) {
      [currentFrame markAcquiredByComponent:component];
      return currentFrame;
    }
  }

  CKCAssert([component class] == [FBComponent class] || FBComponentControllerClassForComponentClass([component class]) == Nil,
            @"%@ has a controller but no scope! Use %@ before constructing the component.",
            [component class],
            FBIsRunningInTestEnvironment() ? @"FBComponentTestRootScope at the start of the test" : @"FBComponentScope(self)");
  CKCAssert(!CKSubclassOverridesSelector([FBComponent class], [component class], @selector(animationsFromPreviousComponent:)),
            @"%@ has a controller but no scope! Use %@ before constructing the component.",
            [component class],
            FBIsRunningInTestEnvironment() ? @"FBComponentTestRootScope at the start of the test" : @"FBComponentScope(self)");
  return nil;
}
