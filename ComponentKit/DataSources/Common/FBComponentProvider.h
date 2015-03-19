// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@class FBComponent;

/**
 Objects that use FBComponentTableViewDataSource need to provide an implementation of this protocol. The Components
 infrastructure is decoupled from specific model and component classes by requiring product code to construct the
 correct component.
 */
@protocol FBComponentProvider <NSObject>

/**
 For the given model, an implementation is expected to create an instance of the correct component. Note that this
 method may be called concurrently on any thread. Therefore it should be threadsafe and should probably not use globals.
 @param model The model object for which we need a component.
 @param context The context parameter passed to the components infrastructure, for example the initializer of
 FBComponentTableViewDataSource. It is up to your implementation to pass whatever additional information you need to
 construct the correct component.
 */
+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context;

@end
