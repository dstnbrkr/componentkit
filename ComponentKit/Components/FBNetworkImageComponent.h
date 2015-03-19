// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBNetworkImageDownloading.h>

@class FBImageDownloader;

struct FBNetworkImageComponentOptions {
  /** Optional imade displayed while the image is loading, or when url is nil. */
  UIImage *defaultImage;
  /** Optional rectangle (in the unit coordinate space) that specifies the portion of contents that the receiver should draw. */
  CGRect cropRect;
};

/** Renders an image from a URL. */
@interface FBNetworkImageComponent : FBComponent

/**
 @param options See FBNetworkImageComponentOptions
 @param attributes Applied to the underlying UIImageView.
 */
+ (instancetype)newWithURL:(NSURL *)url
           imageDownloader:(id<FBNetworkImageDownloading>)imageDownloader
                 scenePath:(id)scenePath
                      size:(const FBComponentSize &)size
                   options:(const FBNetworkImageComponentOptions &)options
                attributes:(const FBViewComponentAttributeValueMap &)attributes;

@end
