// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@protocol FBComponentDeciding <NSObject>

/*
 * Returns a component compliant model if possible
 * Nil otherwise
 */
- (id)componentCompliantModel:(id)model;

/*
 * In case the model is not component compliant, returns a string explaining why
 * Otherwise returns nil. Used for logging and debugging.
 */
- (NSString *)componentComplianceReason:(id)model;

@end
