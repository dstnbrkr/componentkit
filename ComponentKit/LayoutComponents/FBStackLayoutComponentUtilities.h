// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBStackLayoutComponent.h>

inline CGFloat stackDimension(const FBStackLayoutDirection direction, const CGSize size)
{
  return (direction == FBStackLayoutDirectionVertical) ? size.height : size.width;
}

inline CGFloat crossDimension(const FBStackLayoutDirection direction, const CGSize size)
{
  return (direction == FBStackLayoutDirectionVertical) ? size.width : size.height;
}

inline BOOL compareCrossDimension(const FBStackLayoutDirection direction, const CGSize a, const CGSize b)
{
  return crossDimension(direction, a) < crossDimension(direction, b);
}

inline CGPoint directionPoint(const FBStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == FBStackLayoutDirectionVertical) ? CGPointMake(cross, stack) : CGPointMake(stack, cross);
}

inline CGSize directionSize(const FBStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == FBStackLayoutDirectionVertical) ? CGSizeMake(cross, stack) : CGSizeMake(stack, cross);
}

inline FBSizeRange directionSizeRange(const FBStackLayoutDirection direction,
                                      const CGFloat stackMin,
                                      const CGFloat stackMax,
                                      const CGFloat crossMin,
                                      const CGFloat crossMax)
{
  return {directionSize(direction, stackMin, crossMin), directionSize(direction, stackMax, crossMax)};
}

inline FBStackLayoutAlignItems alignment(FBStackLayoutAlignSelf childAlignment, FBStackLayoutAlignItems stackAlignment)
{
  switch (childAlignment) {
    case FBStackLayoutAlignSelfCenter:
      return FBStackLayoutAlignItemsCenter;
    case FBStackLayoutAlignSelfEnd:
      return FBStackLayoutAlignItemsEnd;
    case FBStackLayoutAlignSelfStart:
      return FBStackLayoutAlignItemsStart;
    case FBStackLayoutAlignSelfStretch:
      return FBStackLayoutAlignItemsStretch;
    case FBStackLayoutAlignSelfAuto:
    default:
      return stackAlignment;
  }
}
