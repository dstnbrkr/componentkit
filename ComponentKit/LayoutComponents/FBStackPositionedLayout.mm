// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBStackPositionedLayout.h"

#import "CKInternalHelpers.h"
#import "ComponentUtilities.h"
#import "FBStackLayoutComponentUtilities.h"
#import "FBStackUnpositionedLayout.h"

static CGFloat crossOffset(const FBStackLayoutComponentStyle &style,
                           const FBStackUnpositionedItem &l,
                           const CGFloat crossSize)
{
  switch (alignment(l.child.alignSelf, style.alignItems)) {
    case FBStackLayoutAlignItemsEnd:
      return crossSize - crossDimension(style.direction, l.layout.size);
    case FBStackLayoutAlignItemsCenter:
      return CKFloorPixelValue((crossSize - crossDimension(style.direction, l.layout.size)) / 2);
    case FBStackLayoutAlignItemsStart:
    case FBStackLayoutAlignItemsStretch:
      return 0;
  }
}

static FBStackPositionedLayout stackedLayout(const FBStackLayoutComponentStyle &style,
                                             const CGFloat offset,
                                             const FBStackUnpositionedLayout &unpositionedLayout,
                                             const FBSizeRange &constrainedSize)
{
  // The cross dimension is the max of the childrens' cross dimensions (clamped to our constraint below).
  const auto it = std::max_element(unpositionedLayout.items.begin(), unpositionedLayout.items.end(),
                                   [&](const FBStackUnpositionedItem &a, const FBStackUnpositionedItem &b){
                                     return compareCrossDimension(style.direction, a.layout.size, b.layout.size);
                                   });
  const auto largestChildCrossSize = it == unpositionedLayout.items.end() ? 0 : crossDimension(style.direction, it->layout.size);
  const auto minCrossSize = crossDimension(style.direction, constrainedSize.min);
  const auto maxCrossSize = crossDimension(style.direction, constrainedSize.max);
  const CGFloat crossSize = MIN(MAX(minCrossSize, largestChildCrossSize), maxCrossSize);

  CGPoint p = directionPoint(style.direction, offset, 0);
  BOOL first = YES;
  auto stackedChildren = FB::map(unpositionedLayout.items, [&](const FBStackUnpositionedItem &l) -> FBComponentLayoutChild {
    p = p + directionPoint(style.direction, l.child.spacingBefore, 0);
    if (!first) {
      p = p + directionPoint(style.direction, style.spacing, 0);
    }
    first = NO;
    FBComponentLayoutChild c = {
      // apply the cross alignment for this item
      p + directionPoint(style.direction, 0, crossOffset(style, l, crossSize)),
      l.layout,
    };
    p = p + directionPoint(style.direction, stackDimension(style.direction, l.layout.size) + l.child.spacingAfter, 0);
    return c;
  });
  return {stackedChildren, crossSize};
}

FBStackPositionedLayout FBStackPositionedLayout::compute(const FBStackUnpositionedLayout &unpositionedLayout,
                                                         const FBStackLayoutComponentStyle &style,
                                                         const FBSizeRange &constrainedSize)
{
  switch (style.justifyContent) {
    case FBStackLayoutJustifyContentStart:
      return stackedLayout(style, 0, unpositionedLayout, constrainedSize);
    case FBStackLayoutJustifyContentCenter:
      return stackedLayout(style, floorf(unpositionedLayout.violation / 2), unpositionedLayout, constrainedSize);
    case FBStackLayoutJustifyContentEnd:
      return stackedLayout(style, unpositionedLayout.violation, unpositionedLayout, constrainedSize);
  }
}
