// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

const NSRange CKTextComponentLayerInvalidHighlightRange = { NSNotFound, 0 };

@class CKTextComponentLayer;

@interface CKTextComponentLayerHighlighter : NSObject

- (instancetype)initWithTextComponentLayer:(CKTextComponentLayer *)textComponentLayer;

@property (nonatomic, assign) NSRange highlightedRange;

- (void)layoutHighlight;

@end
