// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBImageComponent.h"

#import "FBComponentSize.h"
#import "FBComponentSubclass.h"

@implementation FBImageComponent

+ (instancetype)newWithImage:(UIImage *)image
{
  return [self
          newWithImage:image
          size:FBComponentSize::fromCGSize(image.size)];
}

+ (instancetype)newWithImage:(UIImage *)image
                        size:(const FBComponentSize &)size
{
  return [self
          newWithView:{[UIImageView class], {{@selector(setImage:), image}}}
          size:size];
}

@end
