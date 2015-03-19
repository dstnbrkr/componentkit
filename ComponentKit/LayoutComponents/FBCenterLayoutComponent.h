// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

typedef NS_OPTIONS(NSUInteger, FBCenterLayoutComponentCenteringOptions) {
  /** The child is positioned in {0,0} relatively to the layout bounds */
  FBCenterLayoutComponentCenteringNone = 0,
  /** The child is centered along the X axis */
  FBCenterLayoutComponentCenteringX = 1 << 0,
  /** The child is centered along the Y axis */
  FBCenterLayoutComponentCenteringY = 1 << 1,
  /** Convenience option to center both along the X and Y axis */
  FBCenterLayoutComponentCenteringXY = FBCenterLayoutComponentCenteringX | FBCenterLayoutComponentCenteringY
};

typedef NS_OPTIONS(NSUInteger, FBCenterLayoutComponentSizingOptions) {
  /** The component will take up the maximum size possible */
  FBCenterLayoutComponentSizingOptionDefault,
  /** The component will take up the minimum size possible along the X axis */
  FBCenterLayoutComponentSizingOptionMinimumX = 1 << 0,
  /** The component will take up the minimum size possible along the Y axis */
  FBCenterLayoutComponentSizingOptionMinimumY = 1 << 1,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  FBCenterLayoutComponentSizingOptionMinimumXY = FBCenterLayoutComponentSizingOptionMinimumX | FBCenterLayoutComponentSizingOptionMinimumY,
};

/** Lays out a single child component and position it so that it is centered into the layout bounds. */
@interface FBCenterLayoutComponent : FBComponent

/**
 @param centeringOptions, see FBCenterLayoutComponentCenteringOptions.
 @param child The child to center.
 @param size The component size or {} for the default which is for the layout to take the maximum space available.
 */
+ (instancetype)newWithCenteringOptions:(FBCenterLayoutComponentCenteringOptions)centeringOptions
                          sizingOptions:(FBCenterLayoutComponentSizingOptions)sizingOptions
                                  child:(FBComponent *)child
                                   size:(const FBComponentSize &)size;

@end
