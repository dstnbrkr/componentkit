// Copyright 2004-present Facebook. All Rights Reserved.

#import <string>

#import <UIKit/UIKit.h>

/**
 A dimension relative to constraints to be provided in the future.
 A RelativeDimension can be one of three types:

 "Auto" - This indicated "I have no opinion" and may be resolved in whatever way makes most sense given
 the circumstances. This is the default type.

 "Points" - Just a number. It will always resolve to exactly this amount.

 "Percent" - Multiplied to a provided parent amount to resolve a final amount.

 A number of convenience constructors have been provided to make using RelativeDimension straight-forward.

 FBRelativeDimension x;                                     // Auto (default case)
 FBRelativeDimension z = 10;                                // 10 Points
 FBRelativeDimension y = FBRelativeDimension::Auto();       // Auto
 FBRelativeDimension u = FBRelativeDimension::Percent(0.5); // 50%

 */
class FBRelativeDimension {
public:
  FBRelativeDimension() : FBRelativeDimension(Type::AUTO, 0) {}
  FBRelativeDimension(CGFloat points) : FBRelativeDimension(Type::POINTS, points) {}

  static FBRelativeDimension Auto() { return FBRelativeDimension(); }
  static FBRelativeDimension Points(CGFloat p) { return FBRelativeDimension(p); }
  static FBRelativeDimension Percent(CGFloat p) { return {FBRelativeDimension::Type::PERCENT, p}; }

  FBRelativeDimension(const FBRelativeDimension &) = default;
  FBRelativeDimension &operator=(const FBRelativeDimension &) = default;

  bool operator==(const FBRelativeDimension &) const;
  NSString *description() const;
  CGFloat resolve(CGFloat autoSize, CGFloat parent) const;

private:
  enum class Type {
    AUTO,
    POINTS,
    PERCENT,
  };
  FBRelativeDimension(Type type, CGFloat value);
  Type _type;
  CGFloat _value;
};

/** Expresses an inclusive range of sizes. Used to provide a simple constraint to component layout. */
struct FBSizeRange {
  CGSize min;
  CGSize max;

  /** The default constructor creates an unconstrained range. */
  FBSizeRange() : FBSizeRange({0,0}, {INFINITY, INFINITY}) {}

  FBSizeRange(const CGSize &min, const CGSize &max);

  /** Clamps the provided CGSize between the [min, max] bounds of this SizeRange. */
  CGSize clamp(const CGSize &size) const;

  /**
   Intersects another size range. If the other size range does not overlap in either dimension, this size range
   "wins" by returning a single point within its own range that is closest to the non-overlapping range.
   */
  FBSizeRange intersect(const FBSizeRange &other) const;

  bool operator==(const FBSizeRange &other) const;
  NSString *description() const;
  size_t hash() const;
};

/** Expresses a size with relative dimensions. */
struct FBRelativeSize {
  FBRelativeDimension width;
  FBRelativeDimension height;
  FBRelativeSize(const FBRelativeDimension &width, const FBRelativeDimension &height);

  /** Convenience constructor to provide size in Points. */
  FBRelativeSize(const CGSize &size);

  /** Convenience constructor for {Auto, Auto} */
  FBRelativeSize();

  /** Resolve this size relative to a parent size and an auto size. */
  CGSize resolveSize(const CGSize &parentSize, const CGSize &autoSize) const;

  bool operator==(const FBRelativeSize &other) const;
  NSString *description() const;
};

/**
 Expresses an inclusive range of relative sizes. Used to provide additional constraint to component layout.
 */
struct FBRelativeSizeRange {
  FBRelativeSize min;
  FBRelativeSize max;
  FBRelativeSizeRange(const FBRelativeSize &min, const FBRelativeSize &max);

  /**
   Convenience constructors to provide an exact size (min == max).
   FBRelativeSizeRange r = {80, 60} // width: [80, 80], height: [60, 60].
   */
  FBRelativeSizeRange(const FBRelativeSize &exact);
  FBRelativeSizeRange(const CGSize &exact);
  FBRelativeSizeRange(const FBRelativeDimension &exactWidth, const FBRelativeDimension &exactHeight);

  /** Convenience constructor for {{Auto, Auto}, {Auto, Auto}}. */
  FBRelativeSizeRange();

  /**
   Provided a parent size and values to use in place of Auto, compute final dimensions for this RelativeSizeRange
   to arrive at a SizeRange. As an example:

   CGSize parent = {200, 120};
   RelativeSizeRange rel = {Percent(0.5), Percent(2/3)}
   rel.resolveSizeRange(parent); // {{100, 60}, {100, 60}}

   The default for Auto() is *everything*, meaning min = {0,0}; max = {INFINITY, INFINITY};
   */
  FBSizeRange resolveSizeRange(const CGSize &parentSize,
                               const FBSizeRange &autoSizeRange = {{0,0}, {INFINITY, INFINITY}}) const;
};
