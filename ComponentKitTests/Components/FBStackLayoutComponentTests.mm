// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

#import "FBComponent.h"
#import "FBComponentSubclass.h"
#import "FBRatioLayoutComponent.h"
#import "FBStackLayoutComponent.h"

static FBComponentViewConfiguration whiteBg = {[UIView class], {{@selector(setBackgroundColor:), [UIColor whiteColor]}}};

@interface FBStackLayoutComponentTests : FBComponentSnapshotTestCase
@end

@implementation FBStackLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static FBStackLayoutComponentChild flexChild(FBComponent *c, BOOL flex)
{
  return {c, .flexGrow = flex, .flexShrink = flex};
}

- (FBStackLayoutComponent *)_layoutWithJustify:(FBStackLayoutJustifyContent)justify
                                          flex:(BOOL)flex
{
  return [FBStackLayoutComponent
          newWithView:whiteBg
          size:{}
          style:{
            .direction = FBStackLayoutDirectionHorizontal,
            .justifyContent = justify,
          }
          children:{
            flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], flex),
            flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}], flex),
            flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], flex),
          }];
}

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static FBSizeRange kSize = {{300, 0}, {300, 300}};
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentStart flex:NO], kSize, @"justifyStart");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentCenter flex:NO], kSize, @"justifyCenter");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentEnd flex:NO], kSize, @"justifyEnd");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentStart flex:YES], kSize, @"flex");
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static FBSizeRange kSize = {{110, 0}, {110, 300}};
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentStart flex:NO], kSize, @"justifyStart");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentCenter flex:NO], kSize, @"justifyCenter");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentEnd flex:NO], kSize, @"justifyEnd");
  FBSnapshotVerifyComponent([self _layoutWithJustify:FBStackLayoutJustifyContentStart flex:YES], kSize, @"flex");
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkComponentsHaveBeenClampedToZeroButViolationStillExists
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = FBStackLayoutDirectionHorizontal}
   children:{
     // After flexShrink-able children are all clamped to zero, the sum of their widths is 100px.
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexShrink = NO,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = YES,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexShrink = NO,
     },
   }];

  // Width is 75px--that's less than the sum of the widths of the child components, which is 100px.
  static FBSizeRange kSize = {{75, 0}, {75, 150}};
  FBSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFlexWithUnequalIntrinsicSizes
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionHorizontal,
   }
   children:{
     flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], YES),
     flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}], YES),
     flexChild([FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}], YES),
   }];

  // width 300px; height 0-150px.
  static FBSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  FBSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static FBSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  FBSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testCrossAxisSizeBehaviors
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }];

  // width 0-300px; height 300px
  static FBSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");

  // width 300px; height 300px
  static FBSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kFixedHeight, @"fixedHeight");
}

- (void)testStackSpacing
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .spacing = 10,
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}]},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,50}]},
   }];

  // width 0-300px; height 300px
  static FBSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testStackSpacingWithChildrenHavingNilComponents
{
  // This should take a zero height since all children have a nil component. If it takes a height > 0, a blue border
  // will show up, hence failing the test.

  static const FBComponentViewAttribute borderAttribute = {"FBStackLayoutComponentTest.border", ^(UIView *view, id value) {
    view.layer.borderColor = [UIColor blueColor].CGColor;
    view.layer.borderWidth = 3.0f;
  }};

  FBComponent *c =
  [FBStackLayoutComponent
   newWithView:{[UIView class], {{borderAttribute, nil}}}
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .spacing = 10,
     .alignItems = FBStackLayoutAlignItemsStretch
   }
   children:{
     {nil},
     {nil},
   }];

  // width 300px; height 0-300px
  static FBSizeRange kVariableHeight = {{300, 0}, {300, 300}};
  FBSnapshotVerifyComponentWithInsets(c, kVariableHeight, UIEdgeInsetsMake(10, 10, 10, 10), @"variableHeight");
}

- (void)testComponentSpacing
{
  // width 0-INF; height 0-INF
  static FBSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};

  FBStackLayoutComponent *spacingBefore =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
   }
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingBefore = 10
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
       .spacingBefore = 20
     },
   }];
  FBSnapshotVerifyComponent(spacingBefore, kAnySize, @"spacingBefore");

  FBStackLayoutComponent *spacingAfter =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
   }
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingAfter = 10
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
       .spacingAfter = 20
     },
   }];
  FBSnapshotVerifyComponent(spacingAfter, kAnySize, @"spacingAfter");

  FBStackLayoutComponent *spacingBalancedOut =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .spacing = 10,
   }
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}],
       .spacingBefore = -10,
       .spacingAfter = -10
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}],
     },
   }];
  FBSnapshotVerifyComponent(spacingBalancedOut, kAnySize, @"spacingBalancedOut");
}

- (void)testJustifiedCenterWithComponentSpacing
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];

  // width 0-300px; height 300px
  static FBSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kVariableHeight, @"variableHeight");
}

- (void)testComponentThatChangesCrossSizeWhenMainSizeIsFlexed
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionHorizontal,
   }
   children:{
     {[FBRatioLayoutComponent
       newWithRatio:1.5
       component:
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{}]
      ], .flexBasis = FBRelativeDimension::Percent(1), .flexGrow = YES, .flexShrink = YES},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}]},
   }];

  // width 0-300px; height 300px
  static FBSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  FBSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithFlexedMainDimension
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .alignItems = FBStackLayoutAlignItemsCenter,
   }
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}],
       .flexShrink = YES,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexShrink = YES,
     },
   }];

  static FBSizeRange kFixedWidth = {{150, 0}, {150, 100}};
  FBSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignCenterWithIndefiniteCrossDimension
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionHorizontal,
   }
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{100,100}]
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .alignSelf = FBStackLayoutAlignSelfCenter,
     },
   }];

  static FBSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  FBSnapshotVerifyComponent(c, kFixedWidth, nil);
}

- (void)testAlignedStart
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
     .alignItems = FBStackLayoutAlignItemsStart
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static FBSizeRange kExactSize = {{300, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedEnd
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
     .alignItems = FBStackLayoutAlignItemsEnd
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static FBSizeRange kExactSize = {{300, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedCenter
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
     .alignItems = FBStackLayoutAlignItemsCenter
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static FBSizeRange kExactSize = {{300, 300}, {300, 300}};
  FBSnapshotVerifyComponent(c, kExactSize, nil);
}

- (void)testAlignedStretchNoChildExceedsMin
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
     .alignItems = FBStackLayoutAlignItemsStretch
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static FBSizeRange kVariableSize = {{200, 200}, {300, 300}};

  // all children should be 200px wide
  FBSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testAlignedStretchOneChildExceedsMin
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{
     .direction = FBStackLayoutDirectionVertical,
     .justifyContent = FBStackLayoutJustifyContentCenter,
     .alignItems = FBStackLayoutAlignItemsStretch
   }
   children:{
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}], 0},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,70}], 20},
     {[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{150,90}], 30},
   }];
  static FBSizeRange kVariableSize = {{50, 50}, {300, 300}};

  // all children should be 150px wide
  FBSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testEmptyStack
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{}
   children:{}];
  static FBSizeRange kVariableSize = {{50, 50}, {300, 300}};

  FBSnapshotVerifyComponent(c, kVariableSize, nil);
}

- (void)testFixedFlexBasisAppliedWhenFlexingItems
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = FBStackLayoutDirectionHorizontal}
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = YES,
       .flexBasis = 10
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}],
       .flexGrow = YES,
       .flexBasis = 10,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = YES,
       .flexBasis = 10,
     },
   }];

  // width 300px; height 0-150px.
  static FBSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  FBSnapshotVerifyComponent(c, kUnderflowSize, @"underflow");

  // width 200px; height 0-150px.
  static FBSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  FBSnapshotVerifyComponent(c, kOverflowSize, @"overflow");
}

- (void)testPercentageFlexBasisResolvesAgainstParentSize
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = FBStackLayoutDirectionHorizontal}
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexGrow = YES,
       // This should override the intrinsic size of 50pts and instead compute to 50% = 100pts.
       // The result should be that the red box is twice as wide as the blue and gree boxes after flexing.
       .flexBasis = FBRelativeDimension::Percent(0.5)
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{50,50}],
       .flexGrow = YES,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexGrow = YES,
     },
   }];

  static FBSizeRange kSize = {{200, 0}, {200, INFINITY}};
  FBSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = FBStackLayoutDirectionHorizontal}
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{50,50}],
       .flexBasis = 20
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{150,150}],
       .flexBasis = 20,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{50,50}],
       .flexBasis = 20,
     },
   }];

  static FBSizeRange kSize = {{300, 0}, {300, 150}};
  FBSnapshotVerifyComponent(c, kSize, nil);
}

- (void)testCrossAxisStretchingOccursAfterStackAxisFlexing
{
  // If cross axis stretching occurred *before* flexing, then the blue child would be stretched to 3000 points tall.
  // Instead it should be stretched to 300 points tall, matching the red child and not overlapping the green inset.
  FBComponent *c =
  [FBInsetComponent
   newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
   insets:{10, 10, 10, 10}
   component:
   [FBStackLayoutComponent
    newWithView:{}
    size:{}
    style:{
      .direction = FBStackLayoutDirectionHorizontal,
      .alignItems = FBStackLayoutAlignItemsStretch,
    }
    children:{
      {
        [FBComponent
         newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}}
         size:{.width = 10, .height = 0}],
      },
      {
        [FBRatioLayoutComponent
         newWithRatio:1.0
         component:
         [FBComponent
          newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
          size:{3000, 3000}]],
        .flexGrow = YES,
        .flexShrink = YES,
      },
    }]];

  static FBSizeRange kSize = {{300, 0}, {300, INFINITY}};
  FBSnapshotVerifyComponent(c, kSize, nil);
}

// TODO(bgesiak)[t5837937]: This test verifies the current resizing behavior.
// This behavior should be changed as part of t5837937.
- (void)testViolationIsDistributedEquallyAmongFlexibleChildComponents
{
  FBStackLayoutComponent *c =
  [FBStackLayoutComponent
   newWithView:whiteBg
   size:{}
   style:{.direction = FBStackLayoutDirectionHorizontal}
   children:{
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}} size:{300,50}],
       .flexShrink = YES,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{100,50}],
       .flexShrink = NO,
     },
     {
       [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}} size:{200,50}],
       .flexShrink = YES,
     },
   }];

  // A width of 400px results in a violation of 200px. This is distributed equally among each flexible component,
  // causing both of them to be shrunk by 100px, resulting in widths of 300px, 100px, and 50px.
  // In the W3 flexbox standard, flexible components are shrunk proportionate to their original sizes,
  // resulting in widths of 180px, 100px, and 120px.
  // This test verifies the current behavior--the snapshot contains widths 300px, 100px, and 50px.
  static FBSizeRange kSize = {{400, 0}, {400, 150}};
  FBSnapshotVerifyComponent(c, kSize, nil);
}

@end
