// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKAsyncLayer.h>

@class CKTextComponentLayerHighlighter;
@class CKTextKitRenderer;

/**
 An implementation detail of the CKTextComponentView.  You should rarely, if ever have to deal directly with this class.
 */
@interface CKTextComponentLayer : CKAsyncLayer

@property (nonatomic, strong) CKTextKitRenderer *renderer;

@property (nonatomic, strong, readonly) CKTextComponentLayerHighlighter *highlighter;

@end
