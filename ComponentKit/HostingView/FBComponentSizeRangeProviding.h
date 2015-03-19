// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBDimension.h>

@protocol FBComponentSizeRangeProviding <NSObject>
@required
/**
 Called when the layout of an `FBComponentHostingView` is dirtied.

 The delegate can use this callback to provide a size range that constrains the layout
 size of a component.
 */
- (FBSizeRange)sizeRangeForBoundingSize:(CGSize)size;
@end
