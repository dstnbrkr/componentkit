// Copyright 2004-present Facebook. All Rights Reserved.

@class FBComponentPreparationQueue;

@protocol FBComponentPreparationQueueListener <NSObject>

- (void)componentPreparationQueue:(FBComponentPreparationQueue *)preparationQueue
     didStartPreparingBatchOfSize:(NSUInteger)batchSize
                          batchID:(NSUInteger)batchID;

- (void)componentPreparationQueue:(FBComponentPreparationQueue *)preparationQueue
    didFinishPreparingBatchOfSize:(NSUInteger)batchSize
                          batchID:(NSUInteger)batchID;

@end
