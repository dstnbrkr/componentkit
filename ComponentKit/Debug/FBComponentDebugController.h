// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentInternal.h>
#import <FBComponentKit/FBComponentViewConfiguration.h>

@class FBComponent;
@class UIView;

/**
 FBComponentDebugController exposes the functionality needed by the lldb helpers to control the debug behavior for
 components.
 */
@interface FBComponentDebugController : NSObject

+ (BOOL)debugMode;

/**
 Setting the debug mode enables the injection of debug configuration into the component.
 */
+ (void)setDebugMode:(BOOL)debugMode;

/**
 Components are an immutable construct. Whenever we make changes to the parameters on which the components depended,
 the changes won't be reflected in the component hierarchy until we explicitly cause a reflow/update. A reflow
 essentially rebuilds the component hierarchy and mounts it back on the view.

 This is particularly used in reflowing the component hierarchy when we set the debug mode.
 */
+ (void)reflowComponents;

@end

/** Returns an adjusted mount context that inserts a debug view if the viewConfiguration doesn't have a view. */
FB::Component::MountContext FBDebugMountContext(Class componentClass,
                                                const FB::Component::MountContext &context,
                                                const FBComponentViewConfiguration &viewConfiguration,
                                                const CGSize size);
