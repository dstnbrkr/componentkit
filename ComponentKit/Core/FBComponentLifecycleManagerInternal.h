// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponentLifecycleManager.h>
#import <FBComponentKit/FBComponentScopeInternal.h>

/**
 Debug Purposes Only.
 */
@interface FBComponentLifecycleManager () <FBComponentStateListener>

- (FBComponentLifecycleManagerState)state;

@end
