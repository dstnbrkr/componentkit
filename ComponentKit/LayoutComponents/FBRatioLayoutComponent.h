// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponent.h>

/**
 Ratio layout component
 For when the content should respect a certain inherent ratio but can be scaled (think photos or videos)
 The ratio passed is the ratio of height / width you expect

 For a ratio 0.5, the component will have a flat rectangle shape
  _ _ _ _
 |       |
 |_ _ _ _|

 For a ratio 2.0, the component will be twice as tall as it is wide
  _ _
 |   |
 |   |
 |   |
 |_ _|

 **/
@interface FBRatioLayoutComponent : FBComponent

+ (instancetype)newWithRatio:(float)ratio
                   component:(FBComponent *)component;

@end
