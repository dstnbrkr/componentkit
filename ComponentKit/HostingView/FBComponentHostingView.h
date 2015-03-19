// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKMacros.h>
#import <FBComponentKit/FBComponentProvider.h>

@protocol FBComponentHostingViewDelegate;
@protocol FBComponentSizeRangeProviding;

/**
 A view the can host a component tree and automatically update it when the model or internal state changes.
 */
@interface FBComponentHostingView : UIView

/**
 The delegate of the view.
 */
@property (nonatomic, weak) id<FBComponentHostingViewDelegate> delegate;

/**
 Designated initializer.
 */
- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                        sizeRangeProvider:(id<FBComponentSizeRangeProviding>)sizeRangeProvider
                                  context:(id<NSObject>)context;

/**
 The model object used to generate the component-tree hosted by the view.

 Setting a new model will synchronously construct and mount a new component tree and the
 delegate will be notified if there is a change in size.
 */
@property (nonatomic, strong) id<NSObject> model;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
- (instancetype)initWithFrame:(CGRect)frame CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@end
