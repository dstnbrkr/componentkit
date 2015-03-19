// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBTestComponentProvider.h"

@implementation FBTestComponentProvider

static FBTestComponentProviderBlock _block = NULL;

+ (void)setProviderImplementation:(FBTestComponentProviderBlock)block
{
  _block = block;
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return _block ? _block(model, context) : nil;
}

@end
