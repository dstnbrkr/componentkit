// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentLifecycleManager.h>

@interface FBComponentDataSourceOutputItem : NSObject

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(const FBComponentLifecycleManagerState &)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                   model:(id<NSObject>)model
                                    UUID:(NSString *)UUID;

@property (readonly, nonatomic, strong) FBComponentLifecycleManager *lifecycleManager;

- (const FBComponentLifecycleManagerState &)lifecycleManagerState;

@property (readonly, nonatomic, strong) id<NSObject> model;

@property (readonly, nonatomic, copy) NSString *UUID;

// In case of a update, this will contain the previous size
@property (readonly, nonatomic, assign) CGSize oldSize;

@end
