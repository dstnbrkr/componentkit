// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentScopeFrame.h"

#import <unordered_map>
#import <vector>

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>
#import <FBComponentKit/FBComponentSubclass.h>

#import <FBHashKit/FBHash.h>

#import "CKInternalHelpers.h"
#import "FBComponentController.h"
#import "FBComponentInternal.h"
#import "FBComponentScopeInternal.h"
#import "FBCompositeComponent.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

typedef struct _FBStateScopeKey {
  Class __unsafe_unretained componentClass;
  id identifier;

  bool operator==(const _FBStateScopeKey &v) const {
    return (CKObjectIsEqual(this->componentClass, v.componentClass) && CKObjectIsEqual(this->identifier, v.identifier));
  }
} _FBStateScopeKey;

namespace std {
  template <>
  struct hash<_FBStateScopeKey> {
    size_t operator ()(_FBStateScopeKey k) const {
      return FBIntegerPairHash([k.componentClass hash], [k.identifier hash]);
    }
  };
}

static const std::vector<SEL> announceableEvents = {
  @selector(componentTreeWillAppear),
  @selector(componentTreeDidDisappear),
};

@interface FBComponentScopeFrame ()
@property (nonatomic, weak, readwrite) FBComponentScopeFrame *root;
@end

@implementation FBComponentScopeFrame {
  id _modifiedState;
  std::unordered_map<_FBStateScopeKey, FBComponentScopeFrame *> _children;
  std::unordered_multimap<SEL, FBComponentController *> _eventRegistration;
}

- (instancetype)initWithListener:(id<FBComponentStateListener>)listener
                           class:(Class __unsafe_unretained)aClass
                      identifier:(id)identifier
                           state:(id)state
                      controller:(FBComponentController *)controller
                            root:(FBComponentScopeFrame *)rootFrame
{
  if (self = [super init]) {
    _listener = listener;
    _componentClass = aClass;
    _identifier = identifier;
    _state = state;
    _controller = controller;
    _root = rootFrame ? rootFrame : self;

    for (const auto announceableEvent : announceableEvents) {
      if (CKSubclassOverridesSelector([FBComponentController class], [controller class], announceableEvent)) {
        [_root registerController:controller forSelector:announceableEvent];
      }
    }
  }
  return self;
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

+ (instancetype)rootFrameWithListener:(id<FBComponentStateListener>)listener
{
  return [[self alloc] initWithListener:listener class:Nil identifier:nil state:nil controller:nil root:nil];
}

- (instancetype)childFrameWithComponentClass:(Class __unsafe_unretained)aClass
                                  identifier:(id)identifier
                                       state:(id)state
                                  controller:(FBComponentController *)controller
{
  FBComponentScopeFrame *child = [[[self class] alloc] initWithListener:_listener
                                                                  class:aClass
                                                             identifier:identifier
                                                                  state:state
                                                             controller:controller
                                                                   root:_root];
  const auto result = _children.insert({{child.componentClass, child.identifier}, child});
  CKCAssert(result.second, @"Scope collision! Attempting to create scope %@::%@ when it already exists.",
            aClass, identifier);
  return child;
}

- (FBComponentScopeFrame *)existingChildFrameWithClass:(__unsafe_unretained Class)aClass identifier:(id)identifier
{
  const auto it = _children.find({aClass, identifier});
  return (it == _children.end()) ? nil : it->second;
}

- (FBComponentBoundsAnimation)boundsAnimationFromPreviousFrame:(FBComponentScopeFrame *)previousFrame
{
  if (previousFrame == nil) {
    return {};
  }

  // _owningComponent is __weak, so we must store into strong locals to prevent racing with it becoming nil.
  FBComponent *newComponent = _owningComponent;
  FBComponent *oldComponent = previousFrame->_owningComponent;
  if (newComponent && oldComponent) {
    const FBComponentBoundsAnimation anim = [newComponent boundsAnimationFromPreviousComponent:oldComponent];
    if (anim.duration != 0) {
      return anim;
    }
  }

  const auto &oldChildren = previousFrame->_children;
  for (const auto &newIt : _children) {
    const auto oldIt = oldChildren.find(newIt.first);
    if (oldIt != oldChildren.end()) {
      const FBComponentBoundsAnimation anim = [newIt.second boundsAnimationFromPreviousFrame:oldIt->second];
      if (anim.duration != 0) {
        return anim;
      }
    }
  }

  return {};
}

#pragma mark - State

- (id)updatedState
{
  return _modifiedState ?: _state;
}

- (void)updateState:(id (^)(id))updateFunction tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate
{
  CKAssertNotNil(updateFunction, @"The block for updating state cannot be nil. What would that even mean?");

  _modifiedState = updateFunction(_state);
  [_listener componentStateDidEnqueueStateModificationWithTryAsynchronousUpdate:tryAsynchronousUpdate];
}

#pragma mark - Component State Acquisition

- (void)markAcquiredByComponent:(FBComponent *)component
{
  CKAssert(_acquired == NO, @"To acquire state for this component you must declare a scope in the -init method with "
           "FBComponentScope([%@ class], identifier).", NSStringFromClass([component class]));

  /* We keep a separate boolean since _owningComponent is __weak and we want this to be write-once. */
  _acquired = YES;
  _owningComponent = component;
}

- (void)registerController:(FBComponentController *)controller forSelector:(SEL)selector
{
  _eventRegistration.insert({{selector, controller}});
}

- (void)announceEventToControllers:(SEL)selector
{
  CKAssert(std::find(announceableEvents.begin(), announceableEvents.end(), selector) != announceableEvents.end(),
           @"Can only announce a whitelisted events, and %@ is not on the list.", NSStringFromSelector(selector));
  auto range = _eventRegistration.equal_range(selector);
  for (auto it = range.first; it != range.second; ++it) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [it->second performSelector:selector];
#pragma clang diagnostic pop
  }
}

@end
