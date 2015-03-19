// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <Foundation/Foundation.h>

#import <FBComponentKit/CKArrayControllerChangeType.h>
#import <FBComponentKit/CKArrayControllerChangeset.h>

#import <FBComponentKit/FBComponentLayout.h>
#import <FBComponentKit/FBComponentLifecycleManager.h>
#import <FBComponentKit/FBComponentPreparationQueueTypes.h>
#import <FBComponentKit/FBDimension.h>

@protocol FBComponentPreparationItem <NSObject>

@property (readonly, nonatomic, strong) id replacementModel;

@property (readonly, nonatomic, strong) FBComponentLifecycleManager *lifecycleManager;

@property (readonly, nonatomic, assign) CGSize oldSize;

@property (readonly, nonatomic, copy) NSString *UUID;

@property (readonly, nonatomic, copy) NSIndexPath *indexPath;

@property (readonly, nonatomic, assign) CKArrayControllerChangeType changeType;

@property (readonly, nonatomic, assign, getter = isPassthrough) BOOL passthrough;

@end

@interface FBComponentPreparationInputItem : NSObject <
FBComponentPreparationItem
>

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                         constrainedSize:(FBSizeRange)constrainedSize
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                               indexPath:(NSIndexPath *)indexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough;

- (FBSizeRange)constrainedSize;

@end

@interface FBComponentPreparationOutputItem : NSObject <
FBComponentPreparationItem
>

- (instancetype)initWithReplacementModel:(id<NSObject>)replacementModel
                        lifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(FBComponentLifecycleManagerState)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                    UUID:(NSString *)UUID
                               indexPath:(NSIndexPath *)indexPath
                              changeType:(CKArrayControllerChangeType)changeType
                             passthrough:(BOOL)passthrough;

- (FBComponentLifecycleManagerState)lifecycleManagerState;

@end

struct FBComponentPreparationInputBatch {
  PreparationBatchID ID;
  CK::ArrayController::Sections sections;
  std::vector<FBComponentPreparationInputItem *> items;
  BOOL isContiguousTailInsertion;
};

@protocol FBComponentPreparationQueueListener;
/**
 Given a batch of input items, converts them to output items. Each item in the batch is processed concurrently. The
 entire converted batch is returned when all items have been processed.
 */
@interface FBComponentPreparationQueue : NSObject

typedef void (^FBComponentPreparationQueueCallback)(const CK::ArrayController::Sections &sections, PreparationBatchID ID, NSArray *batch, BOOL isContiguousTailInsertion);

/**
 @param queueWidth Must be greater than 0, this is the maximum number of items computed concurrently in a batch
 */
- (instancetype)initWithQueueWidth:(NSInteger)queueWidth;
/**
 @param batch The batch of input items to process.
 @param block Called with the output items. The order of items in the array is undefined. The block is invoked on the
 main queue.
 */
- (void)enqueueBatch:(const FBComponentPreparationInputBatch &)batch
               block:(FBComponentPreparationQueueCallback)block;

/**
 Allows adding/removing listeners to hear events on the FBComponentPreparationQueue.
 */
- (void)addListener:(id<FBComponentPreparationQueueListener>)listener;
- (void)removeListener:(id<FBComponentPreparationQueueListener>)listener;

@end
