// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentSize.h"

#import <FBComponentKit/CKAssert.h>

FBComponentSize FBComponentSize::fromCGSize(CGSize size)
{
  return {size.width, size.height};
}

static inline void FBCSConstrain(CGFloat minVal, CGFloat exactVal, CGFloat maxVal, CGFloat *outMin, CGFloat *outMax)
{
    CKCAssert(!isnan(minVal), @"minVal must not be NaN");
    CKCAssert(!isnan(maxVal), @"maxVal must not be NaN");
    // Avoid use of min/max primitives since they're harder to reason
    // about in the presence of NaN (in exactVal)
    // Follow CSS: min overrides max overrides exact.

    // Begin with the min/max range
    *outMin = minVal;
    *outMax = maxVal;
    if (maxVal <= minVal) {
        // min overrides max and exactVal is irrelevant
        *outMax = minVal;
        return;
    }
    if (isnan(exactVal)) {
        // no exact value, so leave as a min/max range
        return;
    }
    if (exactVal > maxVal) {
        // clip to max value
        *outMin = maxVal;
    } else if (exactVal < minVal) {
        // clip to min value
        *outMax = minVal;
    } else {
        // use exact value
        *outMin = *outMax = exactVal;
    }
}

FBSizeRange FBComponentSize::resolve(const CGSize &parentSize) const
{
  CGSize resolvedExact = FBRelativeSize(width, height).resolveSize(parentSize, {NAN, NAN});
  CGSize resolvedMin = FBRelativeSize(minWidth, minHeight).resolveSize(parentSize, {0, 0});
  CGSize resolvedMax = FBRelativeSize(maxWidth, maxHeight).resolveSize(parentSize, {INFINITY, INFINITY});

  CGSize rangeMin, rangeMax;
  FBCSConstrain(resolvedMin.width, resolvedExact.width, resolvedMax.width, &rangeMin.width, &rangeMax.width);
  FBCSConstrain(resolvedMin.height, resolvedExact.height, resolvedMax.height, &rangeMin.height, &rangeMax.height);
  return {rangeMin, rangeMax};
}

bool FBComponentSize::operator==(const FBComponentSize &other) const
{
  return width == other.width && height == other.height
  && minWidth == other.minWidth && minHeight == other.minHeight
  && maxWidth == other.maxWidth && maxHeight == other.maxHeight;
}

NSString *FBComponentSize::description() const
{
  return [NSString stringWithFormat:
          @"<FBComponentSize: exact=%@, min=%@, max=%@>",
          FBRelativeSize(width, height).description(),
          FBRelativeSize(minWidth, minHeight).description(),
          FBRelativeSize(maxWidth, maxHeight).description()];
}
