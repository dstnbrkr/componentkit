// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

/**
 Use this function to optimistically mutate the view owned by a FBComponent. When the view is recycled, the mutation
 will be safely undone, resetting all properties to their original values.

 @warning Optimistically mutating the view for a component is **strongly** discouraged. You should instead use
 updateState: or trigger a change in the source model object.
 */
void FBPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value);

/** Used by the infrastructure to tear down optimistic mutations. Don't call this yourself. */
void FBResetOptimisticMutationsForView(UIView *view);
