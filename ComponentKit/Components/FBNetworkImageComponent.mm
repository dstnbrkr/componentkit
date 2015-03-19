// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBNetworkImageComponent.h"

@interface FBNetworkImageSpecifier : NSObject
- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<FBNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, strong, readonly) UIImage *defaultImage;
@property (nonatomic, strong, readonly) id<FBNetworkImageDownloading> imageDownloader;
@property (nonatomic, strong, readonly) id scenePath;
@property (nonatomic, assign, readonly) CGRect cropRect;
@end

@interface FBNetworkImageComponentView : UIImageView
@property (nonatomic, strong) FBNetworkImageSpecifier *specifier;
- (void)didEnterReusePool;
- (void)willLeaveReusePool;
@end

@implementation FBNetworkImageComponent

+ (instancetype)newWithURL:(NSURL *)url
           imageDownloader:(id<FBNetworkImageDownloading>)imageDownloader
                 scenePath:(id)scenePath
                      size:(const FBComponentSize &)size
                   options:(const FBNetworkImageComponentOptions &)options
                attributes:(const FBViewComponentAttributeValueMap &)passedAttributes
{
  CGRect cropRect = options.cropRect;
  if (CGRectIsEmpty(cropRect)) {
    cropRect = CGRectMake(0, 0, 1, 1);
  }
  FBViewComponentAttributeValueMap attributes(passedAttributes);
  attributes.insert({
    {@selector(setSpecifier:), [[FBNetworkImageSpecifier alloc] initWithURL:url
                                                               defaultImage:options.defaultImage
                                                            imageDownloader:imageDownloader
                                                                  scenePath:scenePath
                                                                   cropRect:cropRect]},

  });
  return [super newWithView:{
    {[FBNetworkImageComponentView class], @selector(didEnterReusePool), @selector(willLeaveReusePool)},
    std::move(attributes)
  } size:size];
}

@end

@implementation FBNetworkImageSpecifier

- (instancetype)initWithURL:(NSURL *)url
               defaultImage:(UIImage *)defaultImage
            imageDownloader:(id<FBNetworkImageDownloading>)imageDownloader
                  scenePath:(id)scenePath
                   cropRect:(CGRect)cropRect
{
  if (self = [super init]) {
    _url = [url copy];
    _defaultImage = defaultImage;
    _imageDownloader = imageDownloader;
    _scenePath = scenePath;
    _cropRect = cropRect;
  }
  return self;
}

- (NSUInteger)hash
{
  return [_url hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([object isKindOfClass:[self class]]) {
    FBNetworkImageSpecifier *other = object;
    return CKObjectIsEqual(_url, other->_url)
           && CKObjectIsEqual(_defaultImage, other->_defaultImage)
           && CKObjectIsEqual(_imageDownloader, other->_imageDownloader)
           && CKObjectIsEqual(_scenePath, other->_scenePath);
  }
  return NO;
}

@end

@implementation FBNetworkImageComponentView
{
  BOOL _inReusePool;
  id _download;
}

- (void)dealloc
{
  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
  }
}

- (void)didDownloadImage:(CGImageRef)image error:(NSError *)error
{
  if (image) {
    self.image = [UIImage imageWithCGImage:image];
    [self updateContentsRect];
  }
  _download = nil;
}

- (void)setSpecifier:(FBNetworkImageSpecifier *)specifier
{
  if (CKObjectIsEqual(specifier, _specifier)) {
    return;
  }

  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
    _download = nil;
  }

  _specifier = specifier;
  self.image = specifier.defaultImage;

  [self _startDownloadIfNotInReusePool];
}

- (void)didEnterReusePool
{
  _inReusePool = YES;
  if (_download) {
    [_specifier.imageDownloader cancelImageDownload:_download];
    _download = nil;
  }
  // Release the downloaded image that we're holding to lower memory usage.
  self.image = _specifier.defaultImage;
}

- (void)willLeaveReusePool
{
  _inReusePool = NO;
  [self _startDownloadIfNotInReusePool];
}

- (void)_startDownloadIfNotInReusePool
{
  if (_inReusePool) {
    return;
  }

  if (_specifier.url == nil) {
    return;
  }

  __weak FBNetworkImageComponentView *weakSelf = self;
  _download = [_specifier.imageDownloader downloadImageWithURL:_specifier.url
                                                     scenePath:_specifier.scenePath
                                                        caller:self
                                                 callbackQueue:dispatch_get_main_queue()
                                         downloadProgressBlock:nil
                                                    completion:^(CGImageRef image, NSError *error)
               {
                 [weakSelf didDownloadImage:image error:error];
               }];
}

- (void)updateContentsRect
{
  if (CGRectIsEmpty(self.bounds)) {
    return;
  }

  // If we're about to crop the width or height, make sure the cropped version won't be upscaled
  CGFloat croppedWidth = self.image.size.width * _specifier.cropRect.size.width;
  CGFloat croppedHeight = self.image.size.height * _specifier.cropRect.size.height;
  if ((_specifier.cropRect.size.width == 1 || croppedWidth >= self.bounds.size.width) &&
      (_specifier.cropRect.size.height == 1 || croppedHeight >= self.bounds.size.height)) {
    self.layer.contentsRect = _specifier.cropRect;
  }
}

#pragma mark - UIView

- (void)layoutSubviews
{
  [super layoutSubviews];

  [self updateContentsRect];
}

@end
