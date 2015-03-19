// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

struct FBComponentSize;

/**
 A component that displays an image using UIImageView.
 */
@interface FBImageComponent : FBComponent

/**
 Uses a static layout with the image's size.
 */
+ (instancetype)newWithImage:(UIImage *)image;

/**
 Uses a static layout with the given image size.
 */
+ (instancetype)newWithImage:(UIImage *)image
                        size:(const FBComponentSize &)size;

@end
