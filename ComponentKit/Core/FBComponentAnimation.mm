// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentAnimation.h"

#import "FBComponentInternal.h"

@interface FBAppliedAnimationContext : NSObject
- (instancetype)initWithTargetLayer:(CALayer *)layer key:(NSString *)key;
@property (nonatomic, strong, readonly) CALayer *targetLayer;
@property (nonatomic, copy, readonly) NSString *key;
@end

static FBComponentAnimationHooks hooksForCAAnimation(FBComponent *component, CAAnimation *originalAnimation)
{
  // Don't mutate the animation the component returned, in case it is a static or otherwise reused. (Also copy
  // immediately to protect against the *caller* mutating the animation after this point but before it's used.)
  CAAnimation *copiedAnimation = [originalAnimation copy];
  return {
    .didRemount = ^(id context){
      CALayer *layer = component.viewForAnimation.layer;
      CKCAssertNotNil(layer, @"%@ has no mounted view, so it cannot be animated", [component class]);
      NSString *key = [[NSUUID UUID] UUIDString];

      // CAMediaTiming beginTime is specified in the time space of the superlayer. Since the component has no way to
      // access the superlayer when constructing the animation, we document that beginTime should be specified in
      // absolute time and perform the adjustment here.
      if (copiedAnimation.beginTime != 0.0) {
        copiedAnimation.beginTime = [layer.superlayer convertTime:copiedAnimation.beginTime fromLayer:nil];
      }
      [layer addAnimation:copiedAnimation forKey:key];
      return [[FBAppliedAnimationContext alloc] initWithTargetLayer:layer key:key];
    },
    .cleanup = ^(FBAppliedAnimationContext *context){
      [context.targetLayer removeAnimationForKey:context.key];
    }
  };
}

FBComponentAnimation::FBComponentAnimation(FBComponent *component, CAAnimation *animation)
: hooks(hooksForCAAnimation(component, animation)) {}

FBComponentAnimation::FBComponentAnimation(const FBComponentAnimationHooks &h) : hooks(h) {}

id FBComponentAnimation::willRemount() const
{
  return hooks.willRemount ? hooks.willRemount() : nil;
}

id FBComponentAnimation::didRemount(id context) const
{
  return hooks.didRemount ? hooks.didRemount(context) : nil;
}

void FBComponentAnimation::cleanup(id context) const
{
  if (hooks.cleanup) {
    hooks.cleanup(context);
  }
}

@implementation FBAppliedAnimationContext

- (instancetype)initWithTargetLayer:(CALayer *)targetLayer key:(NSString *)key
{
  if (self = [super init]) {
    _targetLayer = targetLayer;
    _key = [key copy];
  }
  return self;
}

@end
