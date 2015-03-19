// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentBoundsAnimation.h>
#import <FBComponentKit/FBComponentLayout.h>
#import <FBComponentKit/FBDimension.h>

@class FBComponent;
@class FBComponentScopeFrame;

@protocol FBComponentProvider;
@protocol FBComponentLifecycleManagerDelegate;
@protocol FBComponentLifecycleManagerAsynchronousUpdateHandler;

struct FBComponentLifecycleManagerState {
  id model;
  FBSizeRange constrainedSize;
  FBComponentLayout layout;
  FBComponentScopeFrame *scopeFrame;
  FBComponentBoundsAnimation boundsAnimation;
};

extern const FBComponentLifecycleManagerState FBComponentLifecycleManagerStateEmpty;

@interface FBComponentLifecycleManager : NSObject

/**
 Designated initializer
 */
- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id)context;

/** See @protocol FBComponentLifecycleManagerAsynchronousUpdateHandler */
@property (nonatomic, weak) id<FBComponentLifecycleManagerAsynchronousUpdateHandler> asynchronousUpdateHandler;

@property (nonatomic, weak) id<FBComponentLifecycleManagerDelegate> delegate;

- (FBComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(FBSizeRange)constrainedSize;

/**
 Updates the state to the new one without mounting the view.

 If you are lazily mounting and unmounting the view (like in a datasource), this is the method to call
 during a state mutation.
 */
- (void)updateWithStateWithoutMounting:(const FBComponentLifecycleManagerState &)state;

/**
 Updates the state to the new one.

 If we have a view mounted, we remount the view to pick up the new state.
 */
- (void)updateWithState:(const FBComponentLifecycleManagerState &)state;

/**
 Attaches the manager to the given view. This will display the component in the view and update the view whenever the
 component is updated due to a model or state change.

 Only one manager can be attached to a view at a time. If the given view already has a manager attached, the previous
 manager will be detached before this manager attaches.

 This method efficiently recycles subviews from the previously attached manager whenever possible. Any subviews that
 could not be reused are hidden for future reuse.

 Attaching will not modify any subviews in the view that were not created by the components infrastructure.
 */
- (void)attachToView:(UIView *)view;

/**
 Detaches the manager from its view. This stops the manager from updating the view's subviews as its component updates.

 This does not remove or hide the existing views in the view. If you attach a new manager to the view, it will recycle
 the existing views.
 */
- (void)detachFromView;

/**
 Returns whether the lifecycle manager is attached to a view.
 */
- (BOOL)isAttachedToView;

/**
 Returns the current top-level layout size for the component.
 */
- (CGSize)size;

/**
 Returns the last model associated with this lifecycle manager
 */
- (id)model;

/**
 Events forwarded to children: note that ALL controllers implementing this selector will be notified
 */
// This events will be called when the component appears on screen, corresponds to willDisplayCell
- (void)componentTreeWillAppear;
// This events will be called when the component disappears, corresponds to willEndDisplayingCell
- (void)componentTreeDidDisappear;

@end


@protocol FBComponentLifecycleManagerDelegate <NSObject>

/**
 Sent when the size of the component layout changes due to a state change within a subcomponent or due to a call
 to [FBComponentLifecycleManager -updateWithState:].
 */
- (void)componentLifecycleManager:(FBComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const FBComponentBoundsAnimation &)animation;

@end
