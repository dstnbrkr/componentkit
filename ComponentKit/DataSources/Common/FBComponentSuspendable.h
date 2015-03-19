// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBSuspensionController.h>

/**
 Suspension allows us to stop mutating the table view while scrolling, or optionally allow insertions at the bottom of
 a table view while scrolling, etc.

 When using `FBComponentTableViewDataSource` or `FBComponentCollectionViewDataSource`, mutations to the data source can
 be suspended by assigning to the `state` property of the exposed `FBComponentSuspendable`.
 */
@protocol FBComponentSuspendable <NSObject>

/**
 See `FBSuspensionControllerState`. And `FBSuspensionController`.
 */
@property (readwrite, nonatomic, assign) FBSuspensionControllerState state;

/**
 See `FBSuspensionController`.
 */
@property (readonly, nonatomic, assign) BOOL hasPendingChanges;

@end
