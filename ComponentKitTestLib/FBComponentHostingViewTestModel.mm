// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentHostingViewTestModel.h"

#import <FBComponentKit/FBComponent.h>

@implementation FBComponentHostingViewTestModel

- (instancetype)initWithColor:(UIColor *)color
                         size:(const FBComponentSize &)size
{
  if (self = [super init]) {
    _color = color;
    _size = size;
  }
  return self;
}

@end

FBComponent *FBComponentWithHostingViewTestModel(FBComponentHostingViewTestModel *model)
{
  return [FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [model color]}}}
                             size:[model size]];
}
