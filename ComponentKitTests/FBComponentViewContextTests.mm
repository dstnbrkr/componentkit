// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentAnimation.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBCompositeComponent.h"
#import "FBStaticLayoutComponent.h"

@interface FBComponentViewContextTests : XCTestCase
@end

@interface FBSingleViewComponentProvider : NSObject <FBComponentProvider>
@end

/** Centers a 50x50 subcomponent inside self, which is 100x100. Neither has a view. */
@interface FBNestedComponent : FBCompositeComponent
@property (nonatomic, strong) FBComponent *subcomponent;
@end
@interface FBNestedComponentProvider : NSObject <FBComponentProvider>
@end

@implementation FBComponentViewContextTests

static const FBSizeRange size = {{0,0}, {100, 100}};

- (void)testMountingComponentWithViewExposesViewContextWithTheCreatedView
{
  FBComponentLifecycleManager *clm =
  [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBSingleViewComponentProvider class]
                                                         context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:size];
  [clm updateWithState:state];
  FBComponent *component = state.layout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [clm attachToView:rootView];

  UIImageView *createdView = [[rootView subviews] firstObject];
  XCTAssertTrue([createdView isKindOfClass:[UIImageView class]], @"Expected image view but got %@", createdView);

  FBComponentViewContext context = [component viewContext];
  XCTAssertTrue(context.view == createdView, @"Expected view context to be the created view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(0, 0, 100, 100)), @"Expected frame to match");
}

- (void)testMountingComponentWithViewAndNestedComponentWithoutViewExposesViewContextWithSubcomponentFrameInOuterView
{
  FBComponentLifecycleManager *clm =
  [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBNestedComponentProvider class]
                                                         context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:size];
  [clm updateWithState:state];
  FBNestedComponent *component = (FBNestedComponent *)state.layout.component;

  UIView *rootView = [[UIView alloc] initWithFrame:{{0,0}, size.max}];
  [clm attachToView:rootView];

  FBComponent *subcomponent = component.subcomponent;
  FBComponentViewContext context = [subcomponent viewContext];
  XCTAssertTrue(context.view == rootView, @"Expected view context to be the root view since neither component created a view");
  XCTAssertTrue(CGRectEqualToRect(context.frame, CGRectMake(25, 25, 50, 50)), @"Expected frame to match");
}

@end

@implementation FBSingleViewComponentProvider
+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBComponent newWithView:{[UIImageView class]} size:{}];
}
@end

@implementation FBNestedComponentProvider
+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBNestedComponent new];
}
@end

@implementation FBNestedComponent

+ (instancetype)new
{
  FBComponent *subcomponent = [FBComponent newWithView:{} size:{50, 50}];
  FBNestedComponent *c =
  [super newWithComponent:
   [FBStaticLayoutComponent
    newWithView:{}
    size:{100, 100}
    children:{
      {{25, 25}, subcomponent}
    }]];
  c->_subcomponent = subcomponent;
  return c;
}

@end
