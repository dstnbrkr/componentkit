// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

#import "FBBackgroundLayoutComponent.h"
#import "FBCompositeComponent.h"
#import "FBInsetComponent.h"
#import "FBStaticLayoutComponent.h"


typedef NS_OPTIONS(NSUInteger, FBInsetComponentTestEdge) {
  FBInsetComponentTestEdgeTop    = 1 << 0,
  FBInsetComponentTestEdgeLeft   = 1 << 1,
  FBInsetComponentTestEdgeBottom = 1 << 2,
  FBInsetComponentTestEdgeRight  = 1 << 3,
};

static CGFloat insetForEdge(NSUInteger combination, FBInsetComponentTestEdge edge, CGFloat insetValue)
{
  return combination & edge ? INFINITY : insetValue;
}

static UIEdgeInsets insetsForCombination(NSUInteger combination, CGFloat insetValue)
{
  return {
    .top = insetForEdge(combination, FBInsetComponentTestEdgeTop, insetValue),
    .left = insetForEdge(combination, FBInsetComponentTestEdgeLeft, insetValue),
    .bottom = insetForEdge(combination, FBInsetComponentTestEdgeBottom, insetValue),
    .right = insetForEdge(combination, FBInsetComponentTestEdgeRight, insetValue),
  };
}

static NSString *nameForInsets(UIEdgeInsets insets)
{
  return [NSString stringWithFormat:@"%.f-%.f-%.f-%.f", insets.top, insets.left, insets.bottom, insets.right];
}

@interface FBInsetTestBlockComponent : FBCompositeComponent
+ (instancetype)newWithColor:(UIColor *)color size:(const FBComponentSize &)size;
@end

@interface FBInsetTestBackgroundComponent : FBCompositeComponent
@end

@interface FBInsetComponentTests : FBComponentSnapshotTestCase
@end

@implementation FBInsetComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testInsetsWithVariableSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    FBComponent *component = [FBInsetTestBackgroundComponent
                              newWithComponent:
                              [FBInsetComponent
                               newWithInsets:insets
                               component:[FBInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static FBSizeRange kVariableSize = {{0, 0}, {300, 300}};
    FBSnapshotVerifyComponent(component, kVariableSize, nameForInsets(insets));
  }
}

- (void)testInsetsWithFixedSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    FBComponent *component = [FBInsetTestBackgroundComponent
                              newWithComponent:
                              [FBInsetComponent
                               newWithInsets:insets
                               component:[FBInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static FBSizeRange kFixedSize = {{300, 300}, {300, 300}};
    FBSnapshotVerifyComponent(component, kFixedSize, nameForInsets(insets));
  }
}

/** Regression test, there was a bug mixing insets with infinite and zero sizes */
- (void)testInsetsWithInfinityAndZeroInsetValue
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 0);
    FBComponent *component = [FBInsetTestBackgroundComponent
                              newWithComponent:
                              [FBInsetComponent
                               newWithInsets:insets
                               component:[FBInsetTestBlockComponent newWithColor:[UIColor greenColor] size:{10,10}]]];
    static FBSizeRange kFixedSize = {{300, 300}, {300, 300}};
    FBSnapshotVerifyComponent(component, kFixedSize, nameForInsets(insets));
  }
}

@end

@implementation FBInsetTestBackgroundComponent

+ (instancetype)newWithComponent:(FBComponent *)component
{
  return [super newWithComponent:
          [FBBackgroundLayoutComponent
                            newWithComponent:
                            component
                            background:
           [FBInsetTestBlockComponent newWithColor:[UIColor grayColor] size:{}]]];
}

@end

@implementation FBInsetTestBlockComponent

+ (instancetype)newWithColor:(UIColor *)color size:(const FBComponentSize &)size
{
  return [super newWithComponent:
          [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), color}}} size:size]];
}

@end
