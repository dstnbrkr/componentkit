// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKAsyncLayer.h>
#import <FBComponentKit/CKAsyncTransaction.h>

@class CKAsyncTransaction;

@protocol CKAsyncLayerDrawingDelegate
- (void)drawAsyncLayerInContext:(CGContextRef)context parameters:(NSObject *)parameters;
@end

@interface CKAsyncLayer ()
{
  int32_t _displaySentinel;
}

/**
 @summary The dispatch queue used for async display.

 @desc This is exposed here for tests only.
 */
+ (dispatch_queue_t)displayQueue;

+ (ck_async_transaction_operation_block_t)asyncDisplayBlockWithBounds:(CGRect)bounds
                                                        contentsScale:(CGFloat)contentsScale
                                                               opaque:(BOOL)opaque
                                                      backgroundColor:(CGColorRef)backgroundColor
                                                      displaySentinel:(int32_t *)displaySentinel
                                         expectedDisplaySentinelValue:(int32_t)expectedDisplaySentinelValue
                                                      drawingDelegate:(id<CKAsyncLayerDrawingDelegate>)drawingDelegate
                                                       drawParameters:(NSObject *)drawParameters;

@end
