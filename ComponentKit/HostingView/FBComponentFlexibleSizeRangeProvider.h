// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentSizeRangeProviding.h>

typedef NS_ENUM(NSInteger, FBComponentSizeRangeFlexibility) {
  FBComponentSizeRangeFlexibilityNone = 0,     /** {w, h} -> {{w, h}, {w, h}} */
  FBComponentSizeRangeFlexibleWidth,           /** {w, h} -> {{0, h}, {inf, h}} */
  FBComponentSizeRangeFlexibleHeight,          /** {w, h} -> {{w, 0}, {w, inf}} */
  FBComponentSizeRangeFlexibleWidthAndHeight,  /** {w, h} -> {{0, 0}, {inf, inf}} */
};

/**
 Concrete implementation of `FBComponentSizeRangeProvider` that implements the most
 common sizing behaviours where none, either, or both of the dimensions can be constrained
 to the view's bounding dimensions.
 */
@interface FBComponentFlexibleSizeRangeProvider : NSObject <FBComponentSizeRangeProviding>

/**
 Returns a new instance of the receiver that calculates size ranges based on the
 specified `flexibility` mode.
 */
+ (instancetype)providerWithFlexibility:(FBComponentSizeRangeFlexibility)flexibility;

@end
