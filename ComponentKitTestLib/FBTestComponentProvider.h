// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentProvider.h>

/**
 When testing infrastructure we need to be able to provide custom components. This is a stock implementation of
 @protocol(FBComponentProvider) that allows you to set up a block as the implementation of the protocol method.
 */
@interface FBTestComponentProvider : NSObject <FBComponentProvider>

/**
 This signature should be kept in sync with +[<FBComponentProvier> componentForModel:context:].
 */
typedef FBComponent *(^FBTestComponentProviderBlock)(id<NSObject> model, id<NSObject> context);

/**
 @param block The implementation of +componentForModel:context:. This should be set before passing the Class object
 around.
 */
+ (void)setProviderImplementation:(FBTestComponentProviderBlock)block;

@end
