// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentFlexibleSizeRangeProvider.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

@implementation FBComponentFlexibleSizeRangeProvider {
  FBComponentSizeRangeFlexibility _flexibility;
}

+ (instancetype)providerWithFlexibility:(FBComponentSizeRangeFlexibility)flexibility
{
  return [[self alloc] initWithFlexibility:flexibility];
}

- (instancetype)init
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

- (instancetype)initWithFlexibility:(FBComponentSizeRangeFlexibility)flexibility
{
  if (self = [super init]) {
    _flexibility = flexibility;
  }
  return self;
}

- (FBSizeRange)sizeRangeForBoundingSize:(CGSize)size
{
  switch (_flexibility) {
    case FBComponentSizeRangeFlexibleWidth:
      return FBSizeRange(CGSizeMake(0, size.height), CGSizeMake(INFINITY, size.height));
    case FBComponentSizeRangeFlexibleHeight:
      return FBSizeRange(CGSizeMake(size.width, 0), CGSizeMake(size.width, INFINITY));
    case FBComponentSizeRangeFlexibleWidthAndHeight:
      return FBSizeRange(); // Default constructor creates unconstrained range
    case FBComponentSizeRangeFlexibilityNone:
    default:
      return FBSizeRange(size, size);
  }
}

@end
