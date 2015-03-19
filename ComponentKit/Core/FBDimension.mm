// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBDimension.h"

#import <tgmath.h>

#import <FBComponentKit/CKAssert.h>

#import <FBHashKit/FBHash.h>

#import "ComponentLayoutContext.h"
#import "CKMacros.h"

#define CKCAssertPositiveReal(description, num) \
  CKCAssert(num >= 0 && num < CGFLOAT_MAX, @"%@ must be a real positive integer.\n%@", description, FB::Component::LayoutContext::currentStackDescription())
#define CKCAssertInfOrPositiveReal(description, num) \
  CKCAssert(isinf(num) || (num >= 0 && num < CGFLOAT_MAX), @"%@ must be infinite or a real positive integer.\n%@", description, FB::Component::LayoutContext::currentStackDescription())

FBRelativeDimension::FBRelativeDimension(Type type, CGFloat value) : _type(type), _value(value)
{
  if (type == Type::POINTS) {
    CKCAssertPositiveReal(@"Points", value);
  }
}

bool FBRelativeDimension::operator==(const FBRelativeDimension &other) const
{
  // Implementation assumes that "auto" assigns '0' to value.
  if (_type != other._type) {
    return false;
  }
  switch (_type) {
    case Type::AUTO:
      return true;
    case Type::POINTS:
    case Type::PERCENT:
      return _value == other._value;
  }
}

NSString *FBRelativeDimension::description() const
{
  switch (_type) {
    case Type::AUTO:
      return @"Auto";
    case Type::POINTS:
      return [NSString stringWithFormat:@"%.0fpt", _value];
    case Type::PERCENT:
      return [NSString stringWithFormat:@"%.0f%%", _value * 100.0];
  }
}

CGFloat FBRelativeDimension::resolve(CGFloat autoSize, CGFloat parent) const
{
  switch (_type) {
    case Type::AUTO:
      return autoSize;
    case Type::POINTS:
      return _value;
    case Type::PERCENT:
      return round(_value * parent);
  }
}

FBSizeRange::FBSizeRange(const CGSize &_min, const CGSize &_max) : min(_min), max(_max)
{
  CKCAssertPositiveReal(@"Range min width", min.width);
  CKCAssertPositiveReal(@"Range min height", min.height);
  CKCAssertInfOrPositiveReal(@"Range max width", max.width);
  CKCAssertInfOrPositiveReal(@"Range max height", max.height);
  CKCAssert(min.width <= max.width,
            @"Range min width (%f) must not be larger than max width (%f).", min.width, max.width);
  CKCAssert(min.height <= max.height,
            @"Range min height (%f) must not be larger than max height (%f).", min.height, max.height);
}

CGSize FBSizeRange::clamp(const CGSize &size) const
{
  return {
    MAX(min.width, MIN(max.width, size.width)),
    MAX(min.height, MIN(max.height, size.height))
  };
}

struct _Range {
  CGFloat min;
  CGFloat max;

  /**
   Intersects another dimension range. If the other range does not overlap, this size range "wins" by returning a
   single point within its own range that is closest to the non-overlapping range.
   */
  _Range intersect(const _Range &other) const
  {
    CGFloat newMin = MAX(min, other.min);
    CGFloat newMax = MIN(max, other.max);
    if (!(newMin > newMax)) {
      return {newMin, newMax};
    } else {
      // No intersection. If we're before the other range, return our max; otherwise our min.
      if (min < other.min) {
        return {max, max};
      } else {
        return {min, min};
      }
    }
  }
};

FBSizeRange FBSizeRange::intersect(const FBSizeRange &other) const
{
  auto w = _Range({min.width, max.width}).intersect({other.min.width, other.max.width});
  auto h = _Range({min.height, max.height}).intersect({other.min.height, other.max.height});
  return {{w.min, h.min}, {w.max, h.max}};
}

bool FBSizeRange::operator==(const FBSizeRange &other) const
{
  return CGSizeEqualToSize(min, other.min) && CGSizeEqualToSize(max, other.max);
}
NSString *FBSizeRange::description() const
{
  return [NSString stringWithFormat:@"<FBSizeRange: min=%@, max=%@>", NSStringFromCGSize(min), NSStringFromCGSize(max)];
}
size_t FBSizeRange::hash() const
{
  std::hash<CGFloat> hasher;
  NSUInteger subhashes[] = {
    hasher(min.width),
    hasher(min.height),
    hasher(max.width),
    hasher(max.height)
  };
  return FBIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
}

FBRelativeSize::FBRelativeSize(const FBRelativeDimension &_width, const FBRelativeDimension &_height) : width(_width), height(_height) {}
FBRelativeSize::FBRelativeSize(const CGSize &size) : FBRelativeSize(size.width, size.height) {}
FBRelativeSize::FBRelativeSize() : FBRelativeSize({}, {}) {}

CGSize FBRelativeSize::resolveSize(const CGSize &parentSize, const CGSize &autoSize) const
{
  return {
    width.resolve(autoSize.width, parentSize.width),
    height.resolve(autoSize.height, parentSize.height),
  };
}

bool FBRelativeSize::operator==(const FBRelativeSize &other) const
{
  return width == other.width && height == other.height;
}

NSString *FBRelativeSize::description() const
{
  return [NSString stringWithFormat:@"{%@, %@}", width.description(), height.description()];
}

FBRelativeSizeRange::FBRelativeSizeRange(const FBRelativeSize &_min, const FBRelativeSize &_max) : min(_min), max(_max) {}
FBRelativeSizeRange::FBRelativeSizeRange(const FBRelativeSize &exact) : FBRelativeSizeRange(exact, exact) {}
FBRelativeSizeRange::FBRelativeSizeRange(const CGSize &exact) : FBRelativeSizeRange(FBRelativeSize(exact)) {}
FBRelativeSizeRange::FBRelativeSizeRange(const FBRelativeDimension &exactWidth, const FBRelativeDimension &exactHeight) : FBRelativeSizeRange(FBRelativeSize(exactWidth, exactHeight)) {}
FBRelativeSizeRange::FBRelativeSizeRange() : FBRelativeSizeRange(FBRelativeSize(), FBRelativeSize()) {}

FBSizeRange FBRelativeSizeRange::resolveSizeRange(const CGSize &parentSize, const FBSizeRange &autoFBSizeRange) const
{
  return {
    min.resolveSize(parentSize, autoFBSizeRange.min),
    max.resolveSize(parentSize, autoFBSizeRange.max)
  };
}
