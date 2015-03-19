// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponentFlexibleSizeRangeProvider.h"

@interface FBComponentFlexibleSizeRangeProviderTests : XCTestCase

@end

static CGSize const kBoundingSize = {50, 100};

@implementation FBComponentFlexibleSizeRangeProviderTests

- (void)testNoFlexibility
{
  FBComponentFlexibleSizeRangeProvider *provider = [FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibilityNone];
  FBSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, kBoundingSize), @"Expect minimum size to be equal to bounding size with no flexibility.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, kBoundingSize), @"Expect maximum size to be equal to bounding size with no flexibility.");
}

- (void)testFlexibleWidth
{
  FBComponentFlexibleSizeRangeProvider *provider = [FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibleWidth];
  FBSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeMake(0, kBoundingSize.height)), @"Expect minimum size to be {0, boundingSize.height} with flexible width.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(INFINITY, kBoundingSize.height)), @"Expect maximum size to be {INFINITY, boundingSize.height} with flexible width.");
}

- (void)testFlexibleHeight
{
  FBComponentFlexibleSizeRangeProvider *provider = [FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibleHeight];
  FBSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeMake(kBoundingSize.width, 0)), @"Expect minimum size to be {boundingSize.width, 0} with flexible width.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(kBoundingSize.width, INFINITY)), @"Expect maximum size to be {boundingSize.width, INFINITY} with flexible width.");
}

- (void)testFlexibleWidthAndHeight
{
  FBComponentFlexibleSizeRangeProvider *provider = [FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibleWidthAndHeight];
  FBSizeRange range = [provider sizeRangeForBoundingSize:kBoundingSize];

  XCTAssertTrue(CGSizeEqualToSize(range.min, CGSizeZero), @"Expect minimum size to be {0, 0} with flexible width and height.");
  XCTAssertTrue(CGSizeEqualToSize(range.max, CGSizeMake(INFINITY, INFINITY)), @"Expect maximum size to be {INFINITY, INFINITY} with flexible width and height.");
}

@end
