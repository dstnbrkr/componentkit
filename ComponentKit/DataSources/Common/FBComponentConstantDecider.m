// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentConstantDecider.h"

@implementation FBComponentConstantDecider
{
  BOOL _enabled;
}

- (instancetype)initWithEnabled:(BOOL)enabled
{
  if (self = [super init]) {
    _enabled = enabled;
  }
  return self;
}

- (id)componentCompliantModel:(id)model
{
  return _enabled ? model : nil;
}

- (NSString *)componentComplianceReason:(id)model
{
  return _enabled ? nil : @"Decider disabled by default";
}
@end
