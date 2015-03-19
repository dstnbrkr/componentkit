// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

/**
 This component lays out a single component and then overlays a component on top of it streched to its size
 */
@interface FBOverlayLayoutComponent : FBComponent

+ (instancetype)newWithComponent:(FBComponent *)component
                         overlay:(FBComponent *)overlay;

@end
