// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentSubclass.h"

@interface FBComponentViewAttributeTests : XCTestCase
@end

@interface FBSetterCounterView : UIView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSUInteger numberOfTimesSetTitleWasCalled;
@end

@interface FBHidingCounterView : UIView
@property (nonatomic, readonly) NSUInteger numberOfTimesViewWasHidden;
@end

@implementation FBComponentViewAttributeTests

- (void)testThatMountingViewWithNSValueAttributeActuallyAppliesAttributeToView
{
  FBComponent *testComponent = [FBComponent newWithView:{[UIControl class], {{@selector(setSelected:), @YES}}} size:{}];
  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{
    .layout = [testComponent layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];
  UIControl *c = [[container subviews] firstObject];
  XCTAssertTrue([c isSelected], @"Expected selected to be applied to view");
}

- (void)testThatRecyclingViewWithSameAttributeValueDoesNotReApplyAttributeToView
{
  FBComponent *testComponent1 = [FBComponent newWithView:{[FBSetterCounterView class], {
    {@selector(setTitle:), @"Test"},
    {@selector(setBackgroundColor:), [UIColor blueColor]},
  }} size:{}];
  FBComponentLifecycleManager *m1 = [[FBComponentLifecycleManager alloc] init];
  [m1 updateWithState:{
    .layout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m1 attachToView:container];

  FBComponent *testComponent2 = [FBComponent newWithView:{
    [FBSetterCounterView class], {
      {@selector(setTitle:), @"Test"},
      {@selector(setBackgroundColor:), [UIColor redColor]},
    }} size:{}];
  FBComponentLifecycleManager *m2 = [[FBComponentLifecycleManager alloc] init];
  [m2 updateWithState:{
    .layout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];
  [m2 attachToView:container];

  FBSetterCounterView *c = [[container subviews] firstObject];
  XCTAssertEqual([c numberOfTimesSetTitleWasCalled], 1u, @"Expected setTitle: to called only once since it didn't change");
  XCTAssertEqualObjects([c backgroundColor], [UIColor redColor], @"Expected background color to be updated by m2");
}

- (void)testThatRecyclingViewWithDistinctAttributeValueDoesNotHideAndReShowView
{
  FBComponent *testComponent1 = [FBComponent newWithView:{[FBHidingCounterView class], {
    {@selector(setBackgroundColor:), [UIColor blueColor]},
  }} size:{}];
  FBComponentLifecycleManager *m1 = [[FBComponentLifecycleManager alloc] init];
  [m1 updateWithState:{
    .layout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m1 attachToView:container];

  FBComponent *testComponent2 = [FBComponent newWithView:{[FBHidingCounterView class], {
      {@selector(setBackgroundColor:), [UIColor redColor]},
    }} size:{}];
  FBComponentLifecycleManager *m2 = [[FBComponentLifecycleManager alloc] init];
  [m2 updateWithState:{
    .layout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];
  [m2 attachToView:container];

  FBHidingCounterView *c = [[container subviews] firstObject];
  XCTAssertEqual([c numberOfTimesViewWasHidden], 0u, @"Expected view never to be hidden if it didn't need to be");
}

- (void)testThatRecyclingViewWithAttributeRequiringUnapplicationCallsUnapplicator
{
  NSMutableSet *appliedValues = [NSMutableSet set];
  NSMutableSet *unappliedValues = [NSMutableSet set];
  FBComponentViewAttribute attrWithUnapplicator("test", ^(id view, id val){
    [appliedValues addObject:val];
  }, ^(id view, id val){
    [unappliedValues addObject:val];
  });

  FBComponent *testComponent1 = [FBComponent newWithView:{[UIView class], {{attrWithUnapplicator, @1}}} size:{}];

  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{
    .layout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];

  XCTAssertEqualObjects(appliedValues, [NSSet setWithObject:@1], @"Expected @1 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet set], @"Expected nothing to be unapplied");

  FBComponent *testComponent2 = [FBComponent newWithView:{[UIView class], {{attrWithUnapplicator, @2}}} size:{}];
  [m updateWithState:{
    .layout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  NSSet *expectedApplied = [NSSet setWithObjects:@1, @2, nil]; // stupid STAssert macros
  XCTAssertEqualObjects(appliedValues, expectedApplied, @"Expected @1, @2 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet setWithObject:@1], @"Expected @1 to be unapplied");
}

- (void)testThatRecyclingViewWithAttributeOfferingUpdaterInvokesUpdaterInsteadOfApplicator
{
  __block std::vector<id> appliedValues;
  __block std::vector<std::pair<id, id>> updatedValues;
  FBComponentViewAttribute attrWithUpdater =
  {
    "test",
    ^(id view, id val){
      appliedValues.push_back(val);
    },
    nil,
    ^(id view, id oldVal, id newVal){
      updatedValues.push_back({oldVal, newVal});
    }
  };

  FBComponent *testComponent1 = [FBComponent newWithView:{[UIView class], {{attrWithUpdater, @1}}} size:{}];

  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{
    .layout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];

  XCTAssertTrue(appliedValues.size() == 1 && [appliedValues[0] isEqual:@1], @"Expected @1 to be applied");
  XCTAssertEqual(updatedValues.size(), (size_t)0, @"Expected no updates yet");

  FBComponent *testComponent2 = [FBComponent newWithView:{[UIView class], {{attrWithUpdater, @2}}} size:{}];
  [m updateWithState:{
    .layout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  XCTAssertTrue(appliedValues.size() == 1, @"applicator should not have been called again");
  XCTAssertTrue(updatedValues.size() == 1, @"updater should have been called");
  std::pair<id, id> updateValue = updatedValues[0];
  XCTAssertTrue([updateValue.first isEqual:@1] && [updateValue.second isEqual:@2],
               @"updater should have been called with old and new values");
}

/**
 Tests that if:
 - If your attribute has BOTH an updater AND an unapplicator;
 - The view is initially configured to show a component WITH the attribute;
 - And the view is recycled to show a component WITHOUT the attribute;
 - And then the view is recycled to show a component WITH the attribute again;
 Then we should call the unapplicator followed by the applicator, not the updater.
 */
- (void)testThatRecyclingViewWithAttributeWithBothUpdaterAndUnapplicatorCallsUnapplicatorToRemoveThenApplicatorToReapply
{
  NSMutableSet *appliedValues = [NSMutableSet set];
  NSMutableSet *unappliedValues = [NSMutableSet set];
  __block NSUInteger updateCount = 0;
  FBComponentViewAttribute attr =
  {
    "test",
    ^(id view, id val){
      [appliedValues addObject:val];
    },
    ^(id view, id val) {
      [unappliedValues addObject:val];
    },
    ^(id view, id oldVal, id newVal){
      updateCount++;
    }
  };

  FBComponent *testComponent1 = [FBComponent newWithView:{[UIView class], {{attr, @1}}} size:{}];

  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:{
    .layout = [testComponent1 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  UIView *container = [[UIView alloc] init];
  [m attachToView:container];

  NSSet *expectedAppliedValues = [NSSet setWithObject:@1];
  XCTAssertEqualObjects(appliedValues, expectedAppliedValues, @"Expected @1 to be applied");
  XCTAssertEqualObjects(unappliedValues, [NSSet set], @"Nothing should be unapplied yet");
  XCTAssertEqual(updateCount, 0u, @"Nothing should be updated");

  FBComponent *testComponent2 = [FBComponent newWithView:{[UIView class], {}} size:{}];
  [m updateWithState:{
    .layout = [testComponent2 layoutThatFits:{{0, 0}, {10, 10}} parentSize:kFBComponentParentSizeUndefined]
  }];

  NSSet *expectedUnappliedValues = [NSSet setWithObject:@1];
  XCTAssertEqualObjects(unappliedValues, expectedUnappliedValues, @"@1 should be unapplied");
  XCTAssertEqual(updateCount, 0u, @"Nothing should be updated");
}

@end

@implementation FBSetterCounterView

- (void)setTitle:(NSString *)title
{
  _numberOfTimesSetTitleWasCalled++;
  _title = [title copy];
}

@end

@implementation FBHidingCounterView

- (void)setHidden:(BOOL)hidden
{
  if (hidden) {
    _numberOfTimesViewWasHidden++;
  }
  [super setHidden:hidden];
}

@end
