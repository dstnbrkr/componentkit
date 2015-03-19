// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBDimension.h>

@class FBComponentLifecycleManager;

@interface FBComponentDataSourceInputItem : NSObject

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                                   model:(id<NSObject>)model
                         constrainedSize:(FBSizeRange)constrainedSize
                                    UUID:(NSString *)UUID;

@property (readonly, nonatomic, strong) FBComponentLifecycleManager *lifecycleManager;

@property (readonly, nonatomic, strong) id<NSObject> model;

- (FBSizeRange)constrainedSize;

@property (readonly, nonatomic, copy) NSString *UUID;

@end
