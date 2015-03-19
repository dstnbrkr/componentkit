// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentAnimationHooks.h>

@class CAAnimation;
@class FBComponent;

struct FBComponentAnimation {

  /**
   Creates a FBComponentAnimation that applies a CAAnimation to a FBComponent.

   @note The FBComponent must create a UIView via its view configuration; or, it must be a FBCompositeComponent that
   renders to a component that creates a view.

   @example {myComponent, [CABasicAnimation animationWithKeypath:@"position"]}
   */
  FBComponentAnimation(FBComponent *component, CAAnimation *animation);

  /** Creates a completely custom animation with arbitrary hooks. */
  FBComponentAnimation(const FBComponentAnimationHooks &hooks);

  id willRemount() const;
  id didRemount(id context) const;
  void cleanup(id context) const;

private:
  FBComponentAnimationHooks hooks;
};
