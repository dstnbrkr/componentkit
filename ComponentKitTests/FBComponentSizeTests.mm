// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"


@interface FBComponentSizeTests : XCTestCase
@end

@implementation FBComponentSizeTests

- (void)testResolvingSizeWithAutoInAllFieldsReturnsUnconstrainedRange
{
  FBComponentSize s;
  FBSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 0.f, @"Expected no min width");
  XCTAssertEqual(r.max.width, INFINITY, @"Expected no max width");
  XCTAssertEqual(r.min.height, 0.f, @"Expected no min height");
  XCTAssertEqual(r.max.height, INFINITY, @"Expected no max height");
}

- (void)testPercentageWidthIsResolvedAgainstParentDimension
{
  FBComponentSize s = {.width = FBRelativeDimension::Percent(1.0)};
  FBSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 500.0f, @"Expected min of resolved range to match");
  XCTAssertEqual(r.max.width, 500.0f, @"Expected max of resolved range to match");
}

- (void)testMaxSizeClampsComponentSize
{
  FBComponentSize s = {.width = FBRelativeDimension::Percent(1.0), .maxWidth = 300};
  FBSizeRange r = s.resolve({500, 300});
  XCTAssertEqual(r.min.width, 300.0f, @"Expected max-size to clamp the width to exactly 300 pts");
  XCTAssertEqual(r.max.width, 300.0f, @"Expected max-size to clamp the width to exactly 300 pts");
}

- (void)testMinSizeOverridesMaxSizeWhenTheyConflict
{
  // Min-size overriding max-size matches CSS.
  FBComponentSize s = {.minWidth = FBRelativeDimension::Percent(0.5), .maxWidth = 300};
  FBSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 400.0f, @"Expected min-size to override max-size");
  XCTAssertEqual(r.max.width, 400.0f, @"Expected min-size to override max-size");
}

- (void)testMinSizeAloneResultsInRangeUnconstrainedToInfinity
{
  FBComponentSize s = {.minWidth = 100};
  FBSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 100.0f, @"Expected min width to be passed through");
  XCTAssertEqual(r.max.width, INFINITY, @"Expected max width to be infinity since no maxWidth was specified");
}

- (void)testMaxSizeAloneResultsInRangeUnconstrainedFromZero
{
  FBComponentSize s = {.maxWidth = 100};
  FBSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 0.0f, @"Expected min width to be zero");
  XCTAssertEqual(r.max.width, 100.0f, @"Expected max width to be passed through");
}

- (void)testMinSizeAndMaxSizeResolveToARangeWhenTheyAreNotInConflict
{
  FBComponentSize s = {.minWidth = 100, .maxWidth = 300};
  FBSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 100.0f, @"Expected min-size to be passed to size range");
  XCTAssertEqual(r.max.width, 300.0f, @"Expected max-size to be passed to size range");
}

- (void)testWhenWidthFallsBetweenMinAndMaxWidthsItReturnsARangeWithExactlyThatWidth
{
  FBComponentSize s = {.minWidth = 100, .width = 200, .maxWidth = 300};
  FBSizeRange r = s.resolve({800, 300});
  XCTAssertEqual(r.min.width, 200.0f, @"Expected min-size to be width");
  XCTAssertEqual(r.max.width, 200.0f, @"Expected max-size to be width");
}

@end
