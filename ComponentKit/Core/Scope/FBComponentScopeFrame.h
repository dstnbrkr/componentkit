// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentBoundsAnimation.h>
#import <FBComponentKit/FBComponentScope.h>

@class FBComponent;
@class FBComponentController;
@protocol FBComponentStateListener;

@interface FBComponentScopeFrame : NSObject

/**
 Construct a state-scope frame with a given listener.
 This is the only way to create a root-frame since the other constructor
 derives a name frame within the scope of the given parent.
 */
+ (instancetype)rootFrameWithListener:(id<FBComponentStateListener>)listener;

/**
 Create a new child state-scope frame resident within the scope of parent. This
 will modify the state-scope tree so that parent[key] = theNewFrame.
 */
- (instancetype)childFrameWithComponentClass:(Class __unsafe_unretained)aClass
                                  identifier:(id)identifier
                                       state:(id)state
                                  controller:(FBComponentController *)controller;

@property (nonatomic, readonly, weak) id<FBComponentStateListener> listener;
@property (nonatomic, readonly, strong) Class componentClass;
@property (nonatomic, readonly, strong) id identifier;
@property (nonatomic, readonly, strong) id state;
@property (nonatomic, readonly, strong) FBComponentController *controller;

@property (nonatomic, readonly, strong) id updatedState;

/**
 These are to prevent a component from potentially acquiring the state of a
 parent component (since they might have the same class). We mark the state
 as acquired and pass a reference to the component to assist in debugging.
 */
- (void)markAcquiredByComponent:(FBComponent *)component;

@property (nonatomic, readonly) BOOL acquired;
@property (nonatomic, readonly, weak) FBComponent *owningComponent;

- (FBComponentBoundsAnimation)boundsAnimationFromPreviousFrame:(FBComponentScopeFrame *)previousFrame;

- (FBComponentScopeFrame *)existingChildFrameWithClass:(Class __unsafe_unretained)aClass identifier:(id)identifier;

- (void)updateState:(id (^)(id))updateFunction tryAsynchronousUpdate:(BOOL)tryAsynchronousUpdate;

/**
 For internal use only; forwards a selector to all component controllers that override it.
 - Only works with a whitelisted set of selectors;
 - Only invokes the selector on a controller if it is *overridden* from the base FBComponentController implementation,
   for efficiency.
 */
- (void)announceEventToControllers:(SEL)selector;

@end
