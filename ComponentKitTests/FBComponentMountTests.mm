// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentInternal.h"
#import "FBComponentLayout.h"
#import "FBComponentSubclass.h"

@interface FBComponentMountTests : XCTestCase
@end

@interface FBDontMountChildrenComponent : FBComponent
+ (instancetype)newWithChild:(FBComponent *)child;
@end

@implementation FBComponentMountTests

- (void)testThatMountingComponentThatReturnsMountChildrenNoDoesNotMountItsChild
{
  FBComponent *viewComponent = [FBComponent newWithView:{[UIView class]} size:{}];
  FBComponent *c = [FBDontMountChildrenComponent newWithChild:viewComponent];

  FBComponentLayout layout = [c layoutThatFits:{} parentSize:{NAN, NAN}];

  XCTAssertTrue(layout.children->front().layout.component == viewComponent,
               @"Expected view component to exist in the layout tree");

  UIView *view = [UIView new];
  NSSet *mountedComponents = FBMountComponentLayout(layout, view);

  XCTAssertEqual([[view subviews] count], 0u,
                 @"FBDontMountChildrenComponent should have prevented view component from mounting");

  for (FBComponent *component in mountedComponents) {
    [component unmount];
  }
}

@end

@implementation FBDontMountChildrenComponent
{
  FBComponent *_child;
}

+ (instancetype)newWithChild:(FBComponent *)child
{
  FBDontMountChildrenComponent *c = [self newWithView:{} size:{}];
  c->_child = child;
  return c;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  return {
    self,
    constrainedSize.clamp({100, 100}),
    {{{0,0}, [_child layoutThatFits:{{100, 100}, {100, 100}} parentSize:{100, 100}]}}
  };
}

- (FB::Component::MountResult)mountInContext:(const FB::Component::MountContext &)context
size:(const CGSize)size
children:(std::shared_ptr<const std::vector<FBComponentLayoutChild>>)children
supercomponent:(FBComponent *)supercomponent
{
  FB::Component::MountResult r = [super mountInContext:context size:size children:children supercomponent:supercomponent];
  return {
    .mountChildren = NO,
    .contextForChildren = r.contextForChildren
  };
}

@end
