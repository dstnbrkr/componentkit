// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentDeciding.h>

@interface FBComponentConstantDecider : NSObject <FBComponentDeciding>

- (instancetype)initWithEnabled:(BOOL)enabled;

@end
