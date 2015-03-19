// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponentLayout.h>
#import <FBComponentKit/FBStackLayoutComponent.h>

struct FBStackUnpositionedItem {
  /** The original source child. */
  FBStackLayoutComponentChild child;
  /** The proposed layout. */
  FBComponentLayout layout;
};

/** Represents a set of stack layout children that have their final layout computed, but are not yet positioned. */
struct FBStackUnpositionedLayout {
  /** A set of proposed child layouts, not yet positioned. */
  const std::vector<FBStackUnpositionedItem> items;
  /** The total size of the children in the stack dimension, including all spacing. */
  const CGFloat stackDimensionSum;
  /** The amount by which stackDimensionSum violates constraints. If positive, less than min; negative, greater than max. */
  const CGFloat violation;

  /** Given a set of children, computes the unpositioned layouts for those children. */
  static FBStackUnpositionedLayout compute(const std::vector<FBStackLayoutComponentChild> &children,
                                           const FBStackLayoutComponentStyle &style,
                                           const FBSizeRange &sizeRange);
};
