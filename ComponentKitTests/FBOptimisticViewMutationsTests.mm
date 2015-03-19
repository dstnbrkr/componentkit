// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentAnimation.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentSubclass.h"
#import "FBOptimisticViewMutations.h"

@interface FBOptimisticViewMutationsTests : XCTestCase
@end

@implementation FBOptimisticViewMutationsTests

- (void)testOptimisticViewMutationIsTornDown
{
  FBComponent *blueComponent = [FBComponent newWithView:{[UIView class], {
    {@selector(setBackgroundColor:), [UIColor blueColor]},
  }} size:{}];
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] init];
  [clm updateWithState:{
    .layout = [blueComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [clm attachToView:container];

  UIView *view = [blueComponent viewContext].view;
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue view");

  FBPerformOptimisticViewMutation(view, @"backgroundColor", [UIColor redColor]);
  XCTAssertEqualObjects(view.backgroundColor, [UIColor redColor], @"Expected optimistic red mutation");

  // detaching and reattaching to the view should reset it back to blue.
  [clm detachFromView];
  [clm attachToView:container];
  XCTAssertEqualObjects(view.backgroundColor, [UIColor blueColor], @"Expected blue to be reset by OptimisticViewMutation");
}

@end
