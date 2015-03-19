// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTextComponentView.h"

@class CKTextComponentLayer;
@class CKTextComponentLayerHighlighter;
@class CKTextComponentViewControlTracker;

@interface CKTextComponentView ()

@property (nonatomic, strong, readonly) CKTextComponentLayer *textLayer;

@property (nonatomic, strong, readonly) CKTextComponentViewControlTracker *controlTracker;

@end
