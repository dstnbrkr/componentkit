// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

@class FBComponentLifecycleManager;

/**
 Protocol describing the behavior of an external object the FBComponentLifecycleManager can delegate asynchronous updates to.

 e.g: FBComponentDatasource currently implements this protocol and enqueue an asynchronous update for the corresponding item
 when notified by the FBComponentLifecycleManager.
 */
@protocol FBComponentLifecycleManagerAsynchronousUpdateHandler <NSObject>

- (void)handleAsynchronousUpdateForComponentLifecycleManager:(FBComponentLifecycleManager *)manager;

@end
