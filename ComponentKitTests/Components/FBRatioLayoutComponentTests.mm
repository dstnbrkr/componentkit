// Copyright 2004-present Facebook. All Rights Reserved.


#import <FBComponentKit/FBBackgroundLayoutComponent.h>
#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBComponentSubclass.h>
#import <FBComponentKit/FBRatioLayoutComponent.h>

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

@interface FBRatioLayoutComponentTests : FBComponentSnapshotTestCase

@end

@implementation FBRatioLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static FBRatioLayoutComponent *ratioLayoutComponent(float ratio, const FBComponentSize &size)
{
  return [FBRatioLayoutComponent newWithRatio:ratio component:[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:size]];
}

- (void)testRatioLayout
{
  FBSizeRange kFixedSize = {{0, 0}, {100, 100}};
  FBSnapshotVerifyComponent(ratioLayoutComponent(0.5, {}), kFixedSize, @"HalfRatio");
  FBSnapshotVerifyComponent(ratioLayoutComponent(2.0, {}), kFixedSize, @"DoubleRatio");
  FBSnapshotVerifyComponent(ratioLayoutComponent(7.0, {}), kFixedSize, @"SevenTimesRatio");

  FBComponentSize tallSize = {20, 200};
  FBSnapshotVerifyComponent(ratioLayoutComponent(10.0, tallSize), kFixedSize, @"TenTimesRatioWithItemTooBig");
}

@end
