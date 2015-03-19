// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBTestComponentDecider.h"

@implementation FBTestComponentDecider

- (id)componentCompliantModel:(id)model
{
  return _decision ? model : nil;
}

- (NSString *)componentComplianceReason:(id)model
{
  return _decision ? @"On" : @"Off";
}

@end
