// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentGestureActions.h"
#import "FBComponentGestureActionsInternal.h"

#import <vector>
#import <objc/runtime.h>

#import "CKAssert.h"
#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "FBComponentViewInterface.h"

/** Find a UIGestureRecognizer attached to a view that has a given fb_componentAction. */
static UIGestureRecognizer *recognizerForAction(UIView *view, FBComponentAction action)
{
  for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
    if (sel_isEqual([recognizer fb_componentAction], action)) {
      return recognizer;
    }
  }
  return nil;
}

/** A simple little object that serves as a reuse pool for gesture recognizers. */
class FBGestureRecognizerReusePool {
public:
  /** Pass in a property block if you need to initialize the gesture recognizer **/
  FBGestureRecognizerReusePool(Class gestureRecognizerClass, FBComponentGestureRecognizerSetupFunction setupFunction)
  : _gestureRecognizerClass(gestureRecognizerClass), _setupFunction(setupFunction) {}
  UIGestureRecognizer *get() {
    if (_reusePool.empty()) {
      UIGestureRecognizer *ret =
      [[_gestureRecognizerClass alloc] initWithTarget:[FBComponentGestureActionForwarder sharedInstance]
                                               action:@selector(handleGesture:)];
      if (_setupFunction) {
        _setupFunction(ret);
      }
      return ret;
    } else {
      UIGestureRecognizer *value = _reusePool.back();
      _reusePool.pop_back();
      return value;
    }
  }
  void recycle(UIGestureRecognizer *recognizer) {
    static const size_t kLimit = 5;
    if (_reusePool.size() < kLimit) {
      _reusePool.push_back(recognizer);
    }
  }
private:
  Class _gestureRecognizerClass;
  FBComponentGestureRecognizerSetupFunction _setupFunction;
  std::vector<UIGestureRecognizer *> _reusePool;
};

FBComponentViewAttributeValue FBComponentTapGestureAttribute(FBComponentAction action)
{
  return FBComponentGestureAttribute([UITapGestureRecognizer class], nullptr, action);
}

FBComponentViewAttributeValue FBComponentPanGestureAttribute(FBComponentAction action)
{
  return FBComponentGestureAttribute([UIPanGestureRecognizer class], nullptr, action);
}

FBComponentViewAttributeValue FBComponentLongPressGestureAttribute(FBComponentAction action)
{
  return FBComponentGestureAttribute([UILongPressGestureRecognizer class], nullptr, action);
}

struct FBGestureRecognizerReusePoolMapKey {
  __unsafe_unretained Class gestureRecognizerClass;
  FBComponentGestureRecognizerSetupFunction setupFunction;

  bool operator==(const FBGestureRecognizerReusePoolMapKey &other) const
  {
    return other.gestureRecognizerClass == gestureRecognizerClass && other.setupFunction == setupFunction;
  }
};

namespace std {
  template<> struct hash<FBGestureRecognizerReusePoolMapKey>
  {
    size_t operator()(const FBGestureRecognizerReusePoolMapKey &k) const
    {
      return [k.gestureRecognizerClass hash] ^ std::hash<FBComponentGestureRecognizerSetupFunction>()(k.setupFunction);
    }
  };
}

FBComponentViewAttributeValue FBComponentGestureAttribute(Class gestureRecognizerClass,
                                                          FBComponentGestureRecognizerSetupFunction setupFunction,
                                                          FBComponentAction action)
{
  static auto *reusePoolMap = new std::unordered_map<FBGestureRecognizerReusePoolMapKey, FBGestureRecognizerReusePool *>();
  static CK::StaticMutex reusePoolMapMutex = CK_MUTEX_INITIALIZER;
  CK::StaticMutexLocker l(reusePoolMapMutex);
  auto &reusePool = (*reusePoolMap)[{gestureRecognizerClass, setupFunction}];
  if (reusePool == nullptr) {
    reusePool = new FBGestureRecognizerReusePool(gestureRecognizerClass, setupFunction);
  }
  return {
    {
      std::string(class_getName(gestureRecognizerClass))
      + "-" + CKStringFromPointer((const void *)setupFunction)
      + "-" + std::string(sel_getName(action)),
      ^(UIView *view, id value){
        CKCAssertNil(recognizerForAction(view, action),
                     @"Registered two gesture recognizers with the same action %@", NSStringFromSelector(action));
        UIGestureRecognizer *gestureRecognizer = reusePool->get();
        [gestureRecognizer fb_setComponentAction:action];
        [view addGestureRecognizer:gestureRecognizer];
      },
      ^(UIView *view, id value){
        UIGestureRecognizer *recognizer = recognizerForAction(view, action);
        CKCAssertNotNil(recognizer, @"Expected to find recognizer for %@ on teardown", NSStringFromSelector(action));
        [view removeGestureRecognizer:recognizer];
        [recognizer fb_setComponentAction:NULL];
        reusePool->recycle(recognizer);
      }
    },
    @YES // Bogus value, we don't use it.
  };
}

@implementation FBComponentGestureActionForwarder

+ (instancetype)sharedInstance
{
  static FBComponentGestureActionForwarder *forwarder;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    forwarder = [[FBComponentGestureActionForwarder alloc] init];
  });
  return forwarder;
}

- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
  // If the action can be handled by the sender itself, send it there instead of looking up the chain.
  FBComponentActionSend([recognizer fb_componentAction], recognizer.view.fb_component, recognizer,
                        FBComponentActionSendBehaviorStartAtSender);
}

@end

@implementation UIGestureRecognizer (FBComponent)

static const char kFBComponentActionGestureRecognizerKey = ' ';

- (FBComponentAction)fb_componentAction
{
  NSString *action = objc_getAssociatedObject(self, &kFBComponentActionGestureRecognizerKey);
  if (action) {
    return NSSelectorFromString(action);
  } else {
    return NULL;
  }
}

- (void)fb_setComponentAction:(FBComponentAction)action
{
  NSString *actionString = (action == NULL) ? nil : NSStringFromSelector(action);
  objc_setAssociatedObject(self, &kFBComponentActionGestureRecognizerKey, actionString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
