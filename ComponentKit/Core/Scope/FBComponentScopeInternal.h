// Copyright 2004-present Facebook. All Rights Reserved.

#import <unordered_map>
#import <vector>

#import <FBComponentKit/FBComponentBoundsAnimation.h>
#import <FBComponentKit/FBComponentScope.h>
#import <FBComponentKit/FBComponentScopeFrame.h>

@class FBComponent;

@class FBComponentScopeFrame;

@protocol FBComponentStateListener <NSObject>
- (void)componentStateDidEnqueueStateModificationWithTryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate;
@end

struct FBBuildComponentResult {
  FBComponent *component;
  FBComponentScopeFrame *scopeFrame;
  FBComponentBoundsAnimation boundsAnimation;
};

FBBuildComponentResult FBBuildComponent(id<FBComponentStateListener> listener,
                                        FBComponentScopeFrame *previousRootFrame,
                                        FBComponent *(^function)(void));

/**
 This is only meant to be called when constructing a component and as part of the implementation
 itself. This method looks to see if the currently defined scope matches that of the argument and
 if so it returns the state-scope frame corresponding to the current scope. Otherwise it returns nil.
 */
FBComponentScopeFrame *FBComponentScopeFrameForComponent(FBComponent *component);
