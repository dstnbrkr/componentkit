// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

/**
 Lays out a single child component, then lays out a background component behind it stretched to its size.
 */
@interface FBBackgroundLayoutComponent : FBComponent

/**
 @param component A child that is laid out to determine the size of this component. If this is nil, then this method
        returns nil.
 @param background A child that is laid out behind it. May be nil, in which case the background is omitted.
 */
+ (instancetype)newWithComponent:(FBComponent *)component
                      background:(FBComponent *)background;

@end
