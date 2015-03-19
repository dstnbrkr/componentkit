// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBCompositeComponent.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "CKInternalHelpers.h"
#import "FBComponentInternal.h"
#import "FBComponentLayout.h"
#import "FBComponentSubclass.h"

@interface FBCompositeComponent ()
{
  FBComponent *_component;
}
@end

@implementation FBCompositeComponent

#if DEBUG
+ (void)initialize
{
  FBConditionalAssert(self != [FBCompositeComponent class],
                      !CKSubclassOverridesSelector([FBCompositeComponent class], self, @selector(computeLayoutThatFits:)),
                      @"%@ overrides -computeLayoutThatFits: which is not allowed. "
                      "Consider subclassing FBComponent directly if you need to perform custom layout.",
                      self);
  FBConditionalAssert(self != [FBCompositeComponent class],
                      !CKSubclassOverridesSelector([FBCompositeComponent class], self, @selector(layoutThatFits:parentSize:)),
                      @"%@ overrides -layoutThatFits:parentSize: which is not allowed. "
                      "Consider subclassing FBComponent directly if you need to perform custom layout.",
                      self);
}
#endif

+ (instancetype)newWithComponent:(FBComponent *)component
{
  return [self newWithView:{} component:component];
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view component:(FBComponent *)component
{
  if (!component) {
    return nil;
  }

  FBCompositeComponent *c = [super newWithView:view size:{}];
  if (c) {
    c->_component = component;
  }
  return c;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view size:(const FBComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
                          restrictedToSize:(const FBComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == FBComponentSize(),
           @"FBCompositeComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@)", size.description(), _component);

  FBComponentLayout l = [_component layoutThatFits:constrainedSize parentSize:parentSize];
  return {self, l.size, {{{0,0}, l}}};
}

- (UIView *)viewForAnimation
{
  // Delegate to the wrapped component's viewForAnimation if we don't have one.
  return [super viewForAnimation] ?: [_component viewForAnimation];
}

@end
