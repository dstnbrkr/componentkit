// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKit/FBComponentPreparationQueue.h>
#import <FBComponentKit/FBComponentPreparationQueueInternal.h>

#import <FBComponentKitTestLib/CKTestRunLoopRunnning.h>

using namespace CK::ArrayController;

#pragma mark - Helpers

// Creates a simple input item.
static FBComponentPreparationInputItem *fbcpq_passthroughInputItem(NSString *UUID)
{
  return [[FBComponentPreparationInputItem alloc] initWithReplacementModel:nil
                                                          lifecycleManager:nil
                                                           constrainedSize:FBSizeRange()
                                                                   oldSize:{0, 0}
                                                                      UUID:UUID
                                                                 indexPath:nil
                                                                changeType:CKArrayControllerChangeTypeUnknown
                                                               passthrough:YES];
}

// Returns the number of output items in an array with a UUID matching the one given.
static NSUInteger fbcpq_countOfOutputItemsWithUUID(NSArray *outputItems, NSString *UUID)
{
  return [[outputItems indexesOfObjectsPassingTest:^BOOL(FBComponentPreparationOutputItem *item, NSUInteger idx, BOOL *stop) {
    return [[item UUID] isEqualToString:UUID];
  }] count];
}

#pragma mark - Tests

@interface FBComponentPreparationQueueAsyncTests : XCTestCase
@end

@implementation FBComponentPreparationQueueAsyncTests

- (void)testMultipleObjectBatch
{
  // Arrange: Create a preparation queue and a batch containing two input items.
  FBComponentPreparationQueue *queue = [[FBComponentPreparationQueue alloc] initWithQueueWidth:1];
  FBComponentPreparationInputBatch inputBatch;
  inputBatch.items.push_back(fbcpq_passthroughInputItem(@"one"));
  inputBatch.items.push_back(fbcpq_passthroughInputItem(@"two"));

  // Act: Enqueue the batch of two items, and a block callback that should run when the
  //      two items have finished being prepared as output items. Block until the callback has been run.
  __block NSArray *outputBatch = nil;
  [queue enqueueBatch:inputBatch
                block:^(const Sections &sections, PreparationBatchID ID, NSArray *batch, BOOL isContiguousTailInsertiong) {
                  outputBatch = batch;
                }];
  CKRunRunLoopUntilBlockIsTrue(^BOOL{ return outputBatch != nil; });

  // Assert
  XCTAssertEqual([outputBatch count], (NSUInteger)2,
                 @"The output batch should contain as many items as the input batch");
  XCTAssertEqual(fbcpq_countOfOutputItemsWithUUID(outputBatch, @"one"), (NSUInteger)1,
                 @"The output batch should contain one output item with a UUID of 'one', matching the input item");
  XCTAssertEqual(fbcpq_countOfOutputItemsWithUUID(outputBatch, @"two"), (NSUInteger)1,
                 @"The output batch should contain one output item with a UUID of 'two', matching the input item");
}

@end
