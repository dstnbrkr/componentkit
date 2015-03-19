// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentViewConfiguration.h>

@class FBComponent;
@class UIView;

/**
 FBComponentHierarchyDebugHelper allows
 */
@interface FBComponentHierarchyDebugHelper : NSObject
/**
 Describe the component hierarchy starting from the window. This recursively searches downwards in the view hierarchy to
 find views which have a lifecycle manager, from which we can get the component layout hierarchies.
 @return A string with a description of the hierarchy.
 */
+ (NSString *)componentHierarchyDescription;

@end
