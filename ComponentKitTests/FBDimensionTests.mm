// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBDimension.h"


@interface FBDimensionTests : XCTestCase
@end

@implementation FBDimensionTests

- (void)testIntersectingOverlappingSizeRangesReturnsTheirIntersection
{
  //  range: |---------|
  //  other:      |----------|
  // result:      |----|

  FBSizeRange range = {{0,0}, {10,10}};
  FBSizeRange other = {{7,7}, {15,15}};
  FBSizeRange result = range.intersect(other);
  FBSizeRange expected = {{7,7}, {10,10}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithRangeThatContainsItReturnsSameRange
{
  //  range:    |-----|
  //  other:  |---------|
  // result:    |-----|

  FBSizeRange range = {{2,2}, {8,8}};
  FBSizeRange other = {{0,0}, {10,10}};
  FBSizeRange result = range.intersect(other);
  FBSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithRangeContainedWithinItReturnsContainedRange
{
  //  range:  |---------|
  //  other:    |-----|
  // result:    |-----|

  FBSizeRange range = {{0,0}, {10,10}};
  FBSizeRange other = {{2,2}, {8,8}};
  FBSizeRange result = range.intersect(other);
  FBSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToRightReturnsSinglePointNearestOtherRange
{
  //  range: |-----|
  //  other:          |---|
  // result:       *

  FBSizeRange range = {{0,0}, {5,5}};
  FBSizeRange other = {{10,10}, {15,15}};
  FBSizeRange result = range.intersect(other);
  FBSizeRange expected = {{5,5}, {5,5}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToLeftReturnsSinglePointNearestOtherRange
{
  //  range:          |---|
  //  other: |-----|
  // result:          *

  FBSizeRange range = {{10,10}, {15,15}};
  FBSizeRange other = {{0,0}, {5,5}};
  FBSizeRange result = range.intersect(other);
  FBSizeRange expected = {{10,10}, {10,10}};
  XCTAssertTrue(result == expected, @"Expected %@ but got %@", expected.description(), result.description());
}

@end
