// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentInternal.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentSubclass.h"
#import "FBStaticLayoutComponent.h"

@interface FBComponentMountContextLayoutGuideTests : XCTestCase
@end

@interface FBLayoutGuideTestComponent : FBComponent
@property (nonatomic, readonly) UIEdgeInsets layoutGuideUsedAtMountTime;
@end

@implementation FBComponentMountContextLayoutGuideTests

- (void)testThatComponentIsPassedLayoutGuideDuringMountThatIndicatesItsDistanceFromRootComponentEdges
{
  FBLayoutGuideTestComponent *c = [FBLayoutGuideTestComponent new];
  FBStaticLayoutComponent *layoutComponent =
  [FBStaticLayoutComponent
   newWithView:{}
   size:{200, 200}
   children:{
     {{50, 50}, c, {100, 100}},
   }];
  FBComponentLayout spec = [layoutComponent layoutThatFits:{} parentSize:{NAN, NAN}];
  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{.layout = spec}];

  UIView *v = [[UIView alloc] init];
  [m attachToView:v];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(50, 50, 50, 50)));
}

- (void)testNestedComponentReceivesCombinedLayoutGuide
{
  FBLayoutGuideTestComponent *c = [FBLayoutGuideTestComponent new];
  FBStaticLayoutComponent *layoutComponent =
  [FBStaticLayoutComponent
   newWithView:{}
   size:{100, 100}
   children:{
     {{20, 20}, c, {60, 60}},
   }];
  FBStaticLayoutComponent *wrappingLayoutComponent =
  [FBStaticLayoutComponent
   newWithView:{}
   size:{200, 200}
   children:{
     {{100, 100}, layoutComponent, {100, 100}},
   }];
  FBComponentLayout spec = [wrappingLayoutComponent layoutThatFits:{} parentSize:{NAN, NAN}];
  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{.layout = spec}];

  UIView *v = [[UIView alloc] init];
  [m attachToView:v];

  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(c.layoutGuideUsedAtMountTime, UIEdgeInsetsMake(120, 120, 20, 20)));
}

@end

@implementation FBLayoutGuideTestComponent

- (FB::Component::MountResult)mountInContext:(const FB::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<FBComponentLayoutChild>>)children
                              supercomponent:(FBComponent *)supercomponent
{
  FB::Component::MountResult r = [super mountInContext:context size:size children:children supercomponent:supercomponent];
  _layoutGuideUsedAtMountTime = context.layoutGuide;
  return r;
}

@end
