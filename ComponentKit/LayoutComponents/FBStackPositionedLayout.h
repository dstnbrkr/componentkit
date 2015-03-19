// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponentLayout.h>
#import <FBComponentKit/FBDimension.h>
#import <FBComponentKit/FBStackLayoutComponent.h>

class FBStackUnpositionedLayout;

/** Represents a set of laid out and positioned stack layout children. */
struct FBStackPositionedLayout {
  const std::vector<FBComponentLayoutChild> children;
  const CGFloat crossSize;

  /** Given an unpositioned layout, computes the positions each child should be placed at. */
  static FBStackPositionedLayout compute(const FBStackUnpositionedLayout &unpositionedLayout,
                                         const FBStackLayoutComponentStyle &style,
                                         const FBSizeRange &constrainedSize);
};
