// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKit/FBComponent.h>

#import "FBComponentAccessibility.h"
#import "FBComponentAccessibility_Private.h"

using namespace FB::Component::Accessibility;

@interface FBComponentAccessibilityTests : XCTestCase
@end

@interface UIAccessibleView : UIView
@end

@implementation FBComponentAccessibilityTests

- (void)testAccessibilityContextItemsAreProperlyTransformedToViewAttributes
{
  FBComponentViewConfiguration viewConfiguration = {
    [UIView class],
    {{@selector(setBlah:), @"Blah"}},
    {
      .accessibilityIdentifier = @"batman", .isAccessibilityElement = @NO, .accessibilityLabel = ^{ return @"accessibleBatman"; }
    }};
  FBComponentViewConfiguration expectedViewConfiguration = {
    [UIView class],
    {{@selector(setBlah:), @"Blah"}, {@selector(setAccessibilityIdentifier:), @"batman"}, {@selector(setAccessibilityLabel:), @"accessibleBatman"}, {@selector(setIsAccessibilityElement:), @NO}},
    {
      .accessibilityIdentifier = @"batman", .isAccessibilityElement = @NO, .accessibilityLabel = @"accessibleBatman"
    }};
  XCTAssertTrue(AccessibleViewConfiguration(viewConfiguration) == expectedViewConfiguration, @"Accessibility attributes were applied incorrectly");
}

- (void)testEmptyAccessibilityContextLeavesTheViewConfigurationUnchanged
{
  FBComponentViewConfiguration viewConfiguration = {[UIView class], {{@selector(setBlah:), @"Blah"}}};
  XCTAssertTrue(AccessibleViewConfiguration(viewConfiguration) == viewConfiguration, @"Accessibility attributes were applied incorrectly");
}

- (void)testSetForceAccessibilityEnabledEnablesAccessibility
{
  SetForceAccessibilityEnabled(YES);
  XCTAssertTrue(IsAccessibilityEnabled());
}

- (void)testSetForceAccessibilityEnabledDisablesAccessibility
{
  SetForceAccessibilityEnabled(NO);
  XCTAssertFalse(IsAccessibilityEnabled());
}

@end

@implementation UIAccessibleView
@end
