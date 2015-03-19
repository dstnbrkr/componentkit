// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponentLifecycleManager.h>

@protocol FBComponentSizeRangeProviding;

@interface FBComponentLifecycleManager (Private)

/**
 If there is a sizeRangeProvider, then every state change will be
 computed using the constraint from the sizeRangeProvider,
 allowing the state to resize if needed. Otherwise state change will
 be computed using the constraint from the previous state,
 resulting in fixed state size.
 */
- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id)context
                        sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider;

@end
