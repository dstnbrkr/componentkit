// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBTestHeightToggleComponent.h"

#import <FBComponentKit/FBComponentScope.h>
#import <FBComponentKit/FBComponentSubclass.h>

@implementation FBTestHeightToggleComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)newWithConstrainedSizes:(const std::pair<CGSize, CGSize> &)sizes
{
  FBComponentScope scope(self);
  NSNumber *state = scope.state();
  CGSize size = [state boolValue] ? sizes.first : sizes.second;
  return [self newWithView:{[UIView class]} size:FBComponentSize::fromCGSize(size)];
}

- (void)toggleSize
{
  [self updateState:^id(NSNumber *value) {
    return @(![value boolValue]);
  }];
}

@end
