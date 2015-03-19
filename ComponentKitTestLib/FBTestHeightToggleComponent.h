// Copyright 2004-present Facebook. All Rights Reserved.

#import <utility>

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponent.h>

@interface FBTestHeightToggleComponent : FBComponent

+ (instancetype)newWithConstrainedSizes:(const std::pair<CGSize, CGSize> &)sizes;

- (void)toggleSize;

@end
