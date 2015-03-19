// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentPreparationQueue.h>

@interface FBComponentPreparationQueue ()

/**
 FBComponentPreparationQueue is (sort of generic) it handles input batches, and then performs something on each input
 item concurrently, batching up the output.

 This is the "synchronous" part of the implementation, our function that converts input to output. This is exposed here
 for unit tests that verify the conversion separately from the queueing/batching.
 */
+ (FBComponentPreparationOutputItem *)prepare:(FBComponentPreparationInputItem *)item;

@end
