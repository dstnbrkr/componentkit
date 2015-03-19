// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import "FBComponentAnnouncerBase.h"
#import "FBComponentPreparationQueueListener.h"

@interface FBComponentPreparationQueueListenerAnnouncer : FBComponentAnnouncerBase <FBComponentPreparationQueueListener>

- (void)addListener:(id<FBComponentPreparationQueueListener>)listener;
- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener;

@end

