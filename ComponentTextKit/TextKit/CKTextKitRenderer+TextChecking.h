// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTextKitRenderer.h"

/**
 Application extensions to NSTextCheckingType. We're allowed to do this (see NSTextCheckingAllCustomTypes).
 */
static uint64_t const CKTextKitTextCheckingTypeEntity =               1ULL << 33;
static uint64_t const CKTextKitTextCheckingTypeTruncation =           1ULL << 34;

@class CKTextKitEntityAttribute;

@interface CKTextKitTextCheckingResult : NSTextCheckingResult
@property (nonatomic, strong, readonly) CKTextKitEntityAttribute *entityAttribute;
@end

@interface CKTextKitRenderer (TextChecking)

- (NSTextCheckingResult *)textCheckingResultAtPoint:(CGPoint)point;

@end
