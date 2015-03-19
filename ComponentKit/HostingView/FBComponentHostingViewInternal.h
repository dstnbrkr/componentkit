// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponentHostingView.h>
#import <FBComponentKit/FBDimension.h>

@class FBComponentLifecycleManager;

@interface FBComponentHostingView ()

@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, readonly) FBSizeRange constrainedSize;
@property (nonatomic, readonly) FBComponentLifecycleManager *lifecycleManager;

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                   model:(id<NSObject>)model
                           containerView:(UIView *)containerView;

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)manager
                       sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                   model:(id<NSObject>)model;

@end
