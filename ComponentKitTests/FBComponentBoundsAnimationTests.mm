// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBComponentScope.h"
#import "FBCompositeComponent.h"

@interface FBBoundsAnimatingComponent : FBCompositeComponent
+ (instancetype)newWithHeight:(CGFloat)height;
@end

@implementation FBBoundsAnimatingComponent
+ (instancetype)newWithHeight:(CGFloat)height
{
  FBComponentScope scope(self);
  return [super newWithComponent:[FBComponent newWithView:{} size:{.height = height}]];
}
- (FBComponentBoundsAnimation)boundsAnimationFromPreviousComponent:(FBBoundsAnimatingComponent *)previous
{
  return {.duration = 5.0, .delay = 2.0};
}
@end

@interface FBComponentBoundsAnimationTests : XCTestCase <FBComponentProvider>
@end

@implementation FBComponentBoundsAnimationTests

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBBoundsAnimatingComponent newWithHeight:(CGFloat)[(NSNumber *)model doubleValue]];
}

- (void)testComputingUpdateForComponentLifecycleManagerReturnsBoundsAnimation
{
  static const FBSizeRange size = {{100, 0}, {100, INFINITY}};
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:@100 constrainedSize:size];
  FBComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:@200 constrainedSize:size];
  XCTAssertEqual(stateB.boundsAnimation.duration, (NSTimeInterval)5.0);
  XCTAssertEqual(stateB.boundsAnimation.delay, (NSTimeInterval)2.0);
}

@end
