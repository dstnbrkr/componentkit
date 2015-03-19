// Copyright 2004-present Facebook. All Rights Reserved.

#if  ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "FBComponentPreparationQueueListenerAnnouncer.h"

@implementation FBComponentPreparationQueueListenerAnnouncer

- (void)addListener:(id<FBComponentPreparationQueueListener>)listener
{
  FB::Component::AnnouncerHelper::addListener(self, _cmd, listener);
}

- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener
{
  FB::Component::AnnouncerHelper::removeListener(self, _cmd, listener);
}

- (void)componentPreparationQueue:(FBComponentPreparationQueue *)preparationQueue didStartPreparingBatchOfSize:(NSUInteger)batchSize batchID:(NSUInteger)batchID
{
  FB::Component::AnnouncerHelper::call(self, _cmd, preparationQueue, batchSize, batchID);
}

- (void)componentPreparationQueue:(FBComponentPreparationQueue *)preparationQueue didFinishPreparingBatchOfSize:(NSUInteger)batchSize batchID:(NSUInteger)batchID
{
  FB::Component::AnnouncerHelper::call(self, _cmd, preparationQueue, batchSize, batchID);
}

@end
