// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentDeciding.h>

@interface FBTestComponentDecider : NSObject <
FBComponentDeciding
>

@property (readwrite, nonatomic, assign) BOOL decision;

@end
