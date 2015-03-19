// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <FBComponentKit/FBSuspensionController.h>

using namespace CK::ArrayController;

@interface FBTestSuspensionControllerOutputHandler : NSObject <FBSuspensionControllerOutputHandler>
@property (readwrite, nonatomic, copy) NSIndexPath *(^startingIndexPathForTailChangeset)(void);
@property (readwrite, nonatomic, copy) void(^didDequeueChangeset)(const Input::Changeset &);
@property (readwrite, nonatomic, copy) void(^tickerController)(fb_ticker_block_t);
@end

@implementation FBTestSuspensionControllerOutputHandler

- (NSIndexPath *)startingIndexPathForTailChangesetInSuspensionController:(FBSuspensionController *)controller
{
  return _startingIndexPathForTailChangeset ? _startingIndexPathForTailChangeset() : nil;
}

- (void)suspensionController:(FBSuspensionController *)controller
         didDequeueChangeset:(const Input::Changeset &)changeset
                      ticker:(fb_ticker_block_t)ticker
{
  if (_didDequeueChangeset) {
    _didDequeueChangeset(changeset);
  }
  if (_tickerController) {
    _tickerController(ticker);
  } else {
    ticker();
  }
}

@end

#define IP(__r, __s) [NSIndexPath indexPathForRow:(__r) inSection:(__s)]

#pragma mark -

@interface FBSuspensionControllerNotSuspendedTests : XCTestCase
@end

@implementation FBSuspensionControllerNotSuspendedTests
{
  FBSuspensionController *_controller;
  FBTestSuspensionControllerOutputHandler *_outputHandler;
}

- (void)setUp
{
  [super setUp];
  _outputHandler = [[FBTestSuspensionControllerOutputHandler alloc] init];
  _controller = [[FBSuspensionController alloc] initWithOutputHandler:_outputHandler];
  _controller.state = FBSuspensionControllerStateNotSuspended;
}

- (void)tearDown
{
  _controller = nil;
  _outputHandler = nil;
  [super tearDown];
}

- (void)testInsertion
{
  Input::Items items;
  items.insert({0, 1}, @0);
  Input::Changeset group = {items};

  __block BOOL didDequeue = NO;
  id block = ^(const Input::Changeset &g) {
    XCTAssertFalse(didDequeue);
    didDequeue = YES;
    XCTAssertTrue(g == group);
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue(didDequeue);
  XCTAssertFalse([_controller hasPendingChanges]);
}

- (void)testDeletion
{
  Input::Items items;
  items.remove({0, 1});
  Input::Changeset group = {items};

  __block BOOL didDequeue = NO;
  id block = ^(const Input::Changeset &g) {
    XCTAssertFalse(didDequeue);
    didDequeue = YES;
    XCTAssertTrue(g == group);
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue(didDequeue);
  XCTAssertFalse([_controller hasPendingChanges]);
}

- (void)testUpdate
{
  Input::Items items;
  items.update({0, 1}, @0);
  Input::Changeset group = {items};

  __block BOOL didDequeue = NO;
  id block = ^(const Input::Changeset &g) {
    XCTAssertFalse(didDequeue);
    didDequeue = YES;
    XCTAssertTrue(g == group);
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue(didDequeue);
  XCTAssertFalse([_controller hasPendingChanges]);
}

- (void)testMixedInsertUpdateDelete
{
  Input::Items items;
  items.update({0, 1}, @0);
  items.remove({10, 2});
  items.insert({2, 2}, @1);
  Input::Changeset group = {items};

  __block BOOL didDequeue = NO;
  id block = ^(const Input::Changeset &g) {
    XCTAssertFalse(didDequeue);
    didDequeue = YES;
    XCTAssertTrue(g == group);
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue(didDequeue);
  XCTAssertFalse([_controller hasPendingChanges]);
}

- (void)testSecondChangesIsNotEmittedUntilTickerIsCalled
{
  __block std::vector<Input::Changeset> dequeuedGroups;
  _outputHandler.didDequeueChangeset = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  __block fb_ticker_block_t ticker;
  _outputHandler.tickerController = ^(fb_ticker_block_t t) {
    ticker = t;
  };

  Input::Items changeset1;
  changeset1.insert({0, 0}, @1);
  [_controller processTailInsertion:changeset1];
  XCTAssertTrue(dequeuedGroups.size() == 1, @"First changeset should be dequeued.");

  Input::Items changeset2;
  changeset2.insert({1, 0}, @2);
  [_controller processTailInsertion:changeset2];
  XCTAssertTrue(dequeuedGroups.size() == 1, @"Second changeset should not be dequeued.");
  ticker();
  XCTAssertTrue(dequeuedGroups.size() == 2, @"Second changeset should be dequeued.");
}

@end

@interface FBSuspensionControllerFullySuspendedTests : XCTestCase
@end

@implementation FBSuspensionControllerFullySuspendedTests
{
  FBSuspensionController *_controller;
  FBTestSuspensionControllerOutputHandler *_outputHandler;
}

- (void)setUp
{
  [super setUp];
  _outputHandler = [[FBTestSuspensionControllerOutputHandler alloc] init];
  _controller = [[FBSuspensionController alloc] initWithOutputHandler:_outputHandler];
  _controller.state = FBSuspensionControllerStateFullySuspended;
}

- (void)tearDown
{
  _controller = nil;
  _outputHandler = nil;
  [super tearDown];
}

- (void)testGroupInsertionIsNotDequeued
{
  Input::Items items;
  items.insert({0, 1}, @0);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testGroupDeletionIsNotDequeued
{
  Input::Items items;
  items.remove({0, 1});
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testGroupUpdateIsNotDequeued
{
  Input::Items items;
  items.update({0, 1}, @0);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testGroupMixedAreNotDequeued
{
  Input::Items items;
  items.update({0, 1}, @0);
  items.remove({10, 2});
  items.insert({2, 2}, @1);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testTailInsertionIsNotDequeued
{
  Input::Items items;
  items.insert({2, 2}, @1);

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;
  [_controller processTailInsertion:items];
  XCTAssertTrue([_controller hasPendingChanges]);
}

@end

@interface FBSuspensionControllerMergeSuspendedTests : XCTestCase
@end

@implementation FBSuspensionControllerMergeSuspendedTests
{
  FBSuspensionController *_controller;
  FBTestSuspensionControllerOutputHandler *_outputHandler;
}

- (void)setUp
{
  [super setUp];
  _outputHandler = [[FBTestSuspensionControllerOutputHandler alloc] init];
  _controller = [[FBSuspensionController alloc] initWithOutputHandler:_outputHandler];
  _controller.state = FBSuspensionControllerStateMergeSuspended;
}

- (void)tearDown
{
  _controller = nil;
  _outputHandler = nil;
  [super tearDown];
}

- (void)testGroupInsertionIsNotDequeued
{
  Input::Items items;
  items.insert({0, 1}, @0);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
}

- (void)testGroupDeletionIsNotDequeued
{
  Input::Items items;
  items.remove({0, 1});
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
}

- (void)testGroupUpdateIsNotDequeued
{
  Input::Items items;
  items.update({0, 1}, @0);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
}

- (void)testGroupMixedAreNotDequeued
{
  Input::Items items;
  items.update({0, 1}, @0);
  items.remove({10, 2});
  items.insert({2, 2}, @1);
  Input::Changeset group = {items};

  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  [_controller processChangeset:group];
}

- (void)testTailInsertionsAreTreatedAsRegularChangesetsWhenThereAreNoOtherChangesetsEnqueued
{
  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(2, 2);
  };

  {
    Input::Items tailInsertion;
    tailInsertion.insert({0, 0}, @1);
    [_controller processTailInsertion:tailInsertion];
    // There is nothing in the queue when we do the tail insert
    // therefore the tail insert should be treated as a regular
    // changeset and do not call out to the startingIndexPathForTailChangeset
    // delegate method.
    XCTAssertTrue(dequeuedGroups.size() == 1);
    XCTAssertTrue(dequeuedGroups[0] == tailInsertion);
  }
}

- (void)testTailInsertionsAreDequeuedAndProperlyAdjusted
{
  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(3, 6);
  };

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items regularChangeset;
    regularChangeset.remove({0,0});
    regularChangeset.insert({0,0}, @1);
    regularChangeset.insert({1,0}, @2);
    [_controller processChangeset:regularChangeset];
  }

  {
    Input::Items tailInsertion;
    tailInsertion.insert({2, 2}, @1);
    tailInsertion.insert({3, 2}, @2);
    tailInsertion.insert({4, 2}, @3);
    tailInsertion.insert({0, 3}, @4);
    tailInsertion.insert({1, 3}, @5);
    tailInsertion.insert({2, 3}, @6);
    [_controller processTailInsertion:tailInsertion];
  }

  {
    Input::Items expectedItems;
    expectedItems.insert({3, 6}, @1);
    expectedItems.insert({4, 6}, @2);
    expectedItems.insert({5, 6}, @3);
    expectedItems.insert({0, 7}, @4);
    expectedItems.insert({1, 7}, @5);
    expectedItems.insert({2, 7}, @6);
    Input::Changeset expectedGroup = {expectedItems};

    XCTAssertTrue(dequeuedGroups.size() == 1);
    XCTAssertTrue(dequeuedGroups[0] == expectedGroup);
  }
}

- (void)testOnlyTailsInsertionsAreDequeueWhileThereAreOtherChangesetsInBetween
{
  __block std::vector<Input::Changeset> dequeuedGroups;
  _outputHandler.didDequeueChangeset = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(1, 0);
  };

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items regularChangeset;
    regularChangeset.insert({0,0}, @1);
    [_controller processChangeset:regularChangeset];
  }

  {
    Input::Items tailInsertion;
    tailInsertion.insert({2, 0}, @1);
    [_controller processTailInsertion:tailInsertion];
    Input::Items expectedChangeset;
    expectedChangeset.insert({1,0}, @1);
    XCTAssertTrue(dequeuedGroups.size() == 1, @"First changeset should be dequeued.");
    XCTAssertTrue(dequeuedGroups[0] == expectedChangeset, @"The dequeued changeset should be the first tail insertion");
  }

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items regularChangeset2;
    regularChangeset2.insert({1,0}, @1);
    [_controller processChangeset:regularChangeset2];
  }

  {
    Input::Items tailInsertion2;
    tailInsertion2.insert({3, 0}, @2);
    [_controller processTailInsertion:tailInsertion2];
    Input::Items expectedChangeset2;
    expectedChangeset2.insert({1,0}, @2);
    XCTAssertTrue(dequeuedGroups.size() == 2, @"Second changeset should be dequeued.");
    XCTAssertTrue(dequeuedGroups[1] == expectedChangeset2, @"The dequeued changeset should be the first tail insertion");
  }

}

- (void)testTailInsertionsAreNotDequeuedIfThereIsAChangesetWithSectionChangesEnqueuedBefore {
  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(3, 6);
  };

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items itemChanges;
    itemChanges.remove({0,0});
    itemChanges.insert({0,0}, @1);
    itemChanges.insert({1,0}, @2);
    Sections sectionChanges;
    sectionChanges.insert(1);
    [_controller processChangeset:Input::Changeset(sectionChanges, itemChanges)];
  }

  {
    Input::Items tailInsertion;
    tailInsertion.insert({2, 2}, @1);
    tailInsertion.insert({3, 2}, @2);
    tailInsertion.insert({4, 2}, @3);
    tailInsertion.insert({0, 3}, @4);
    tailInsertion.insert({1, 3}, @5);
    tailInsertion.insert({2, 3}, @6);
    [_controller processTailInsertion:tailInsertion];
  }

  {
    Input::Items expectedItems;
    expectedItems.insert({3, 6}, @1);
    expectedItems.insert({4, 6}, @2);
    expectedItems.insert({5, 6}, @3);
    expectedItems.insert({0, 7}, @4);
    expectedItems.insert({1, 7}, @5);
    expectedItems.insert({2, 7}, @6);
    Input::Changeset expectedGroup = {expectedItems};

    XCTAssertTrue(dequeuedGroups.size() == 0);
  }
}

/**
 This test makes sure that we munge the index paths for a tail insertion at dequeue time.
 We used to munge the index paths when changesets were **enqueued**. This is incorrect when we consider the ticker.
 The ticker acts as an acknowledgement that the previously emitted changeset has been "handled". In the case of
 FBComponentCollectionViewDataSource, the "handling" of the changeset includes applying the changeset to our sectioned
 array controller. If we munge the index paths at enqueue time, we use the incorrect `startingIndexPathForTailChangeset`
 b/c the array controller has not been updated.
 */
- (void)testIndexPathsForTailInsertionAreAdjustedWhenTheChangesetItEmitted
{
  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;
  __block fb_ticker_block_t ticker;
  _outputHandler.tickerController = ^(fb_ticker_block_t t) {
    ticker = t;
  };

  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(1, 0);
  };

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items regularChangeset;
    regularChangeset.remove({0,0});
    regularChangeset.insert({0,0}, @1);
    regularChangeset.insert({1,0}, @2);
    [_controller processChangeset:regularChangeset];
  }

  {
    Input::Items tailInsertion;
    tailInsertion.insert({2, 0}, @1);
    [_controller processTailInsertion:tailInsertion];

    Input::Items expectedItems;
    expectedItems.insert({1, 0}, @1);
    Input::Changeset expectedGroup = {expectedItems};

    XCTAssertTrue(dequeuedGroups.size() == 1);
    XCTAssertTrue(dequeuedGroups[0] == expectedGroup);
  }

  /**
   By changing the `startingIndexPathForTailChangeset` before calling the ticker, we ensure that the second changeset
   to be dequeued has index paths munged using at emission time, not enqueue time.
   */
  {
    Input::Items tailInsertion;
    tailInsertion.insert({3, 0}, @2);
    [_controller processTailInsertion:tailInsertion];

    // Here's the important part...
    _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
      return IP(2, 0);
    };
    ticker();

    Input::Items expectedItems;
    expectedItems.insert({2, 0}, @2);
    Input::Changeset expectedGroup = {expectedItems};

    XCTAssertTrue(dequeuedGroups.size() == 2);
    XCTAssertTrue(dequeuedGroups[1] == expectedGroup);
  }
}

- (void)disabled_testInsertionOfGroupDisablesTailDequeueing
{
  id block = ^(const Input::Changeset &g) {
    XCTFail(@"");
  };
  _outputHandler.didDequeueChangeset = block;

  Input::Items items;
  items.update({0, 1}, @0);
  items.remove({10, 2});
  items.insert({2, 2}, @1);
  Input::Changeset group = {items};

  [_controller processChangeset:group];
  XCTAssertTrue([_controller hasPendingChanges]);

  Input::Items tailInsertion;
  tailInsertion.insert({10, 20}, @15);
  [_controller processTailInsertion:tailInsertion];
  XCTAssertTrue([_controller hasPendingChanges]);
}

@end

@interface FBSuspensionControllerStateTransitionTests : XCTestCase
@end

@implementation FBSuspensionControllerStateTransitionTests
{
  FBSuspensionController *_controller;
  FBTestSuspensionControllerOutputHandler *_outputHandler;
}

- (void)setUp
{
  [super setUp];
  _outputHandler = [[FBTestSuspensionControllerOutputHandler alloc] init];
  _controller = [[FBSuspensionController alloc] initWithOutputHandler:_outputHandler];
}

- (void)tearDown
{
  _controller = nil;
  _outputHandler = nil;
  [super tearDown];
}

- (void)testTransistionFromFullySuspendedToNotSuspendedDequeuesAllQueuedChangesFIFO
{
  _controller.state = FBSuspensionControllerStateFullySuspended;

  std::vector<Input::Changeset> queue;
  Input::Items items1;
  items1.update({0, 1}, @0);
  items1.remove({10, 2});
  items1.insert({2, 2}, @1);
  queue.push_back({items1});

  Input::Items items2;
  items2.update({1, 1}, @2);
  items2.remove({5, 2});
  items2.insert({2, 8}, @3);
  queue.push_back({items2});

  Input::Items tailInsertion;
  tailInsertion.insert({2, 2}, @1);

  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  for (auto group : queue) {
    [_controller processChangeset:group];
  }
  [_controller processTailInsertion:tailInsertion];

  XCTAssertTrue(dequeuedGroups.size() == 0);
  XCTAssertTrue([_controller hasPendingChanges]);

  _controller.state = FBSuspensionControllerStateNotSuspended;

  XCTAssertTrue(dequeuedGroups[0] == queue[0]);
  XCTAssertTrue(dequeuedGroups[1] == queue[1]);
  Input::Items expectedTailGroup = {tailInsertion};
  XCTAssertTrue(dequeuedGroups[2] == expectedTailGroup);

  XCTAssertFalse([_controller hasPendingChanges]);
}

- (void)testTransistionFromFullySuspendedToMergeSuspendedAllowsTailDequeuingOnly
{
  _controller.state = FBSuspensionControllerStateFullySuspended;

  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  _outputHandler.startingIndexPathForTailChangeset = ^NSIndexPath *{
    return IP(0, 0);
  };
  _controller.state = FBSuspensionControllerStateMergeSuspended;

  {
    //Insert a changeset so that tail insertions are going in the fastpath and are being munged
    Input::Items regularChangeset;
    regularChangeset.remove({0,0});
    regularChangeset.insert({0,0}, @1);
    regularChangeset.insert({1,0}, @2);
    [_controller processChangeset:regularChangeset];
  }

  {
    Input::Items tailItems;
    tailItems.insert({2, 2}, @1);
    [_controller processTailInsertion:tailItems];
  }

  XCTAssertTrue(dequeuedGroups.size() == 1);

  Input::Items expectedItems;
  expectedItems.insert({0, 0}, @1);
  Input::Changeset expectedGroup = {expectedItems};
  XCTAssertTrue(dequeuedGroups[0] == expectedGroup);
}

- (void)testTransistionFromNotSuspendedToFullySuspendedStopsDequeueing
{
  _controller.state = FBSuspensionControllerStateNotSuspended;

  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  Input::Items items1;
  items1.update({0, 1}, @0);
  items1.remove({10, 2});
  items1.insert({2, 2}, @1);
  Input::Changeset group1 = {items1};
  [_controller processChangeset:group1];
  XCTAssertTrue(dequeuedGroups.size() == 1);
  XCTAssertTrue(dequeuedGroups[0] == group1);

  _controller.state = FBSuspensionControllerStateFullySuspended;

  Input::Items items2;
  items2.update({1, 1}, @2);
  items2.remove({2, 5});
  items2.insert({2, 8}, @3);
  Input::Changeset group2 = {items2};
  [_controller processChangeset:group2];
  XCTAssertTrue(dequeuedGroups.size() == 1);
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testTransitionFromMergeSuspendedToFullySuspendedStopsDequeueing
{
  _controller.state = FBSuspensionControllerStateMergeSuspended;

  __block std::vector<Input::Changeset> dequeuedGroups;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;
  Input::Items tailItems1;
  tailItems1.insert({2, 2}, @1);
  [_controller processTailInsertion:tailItems1];
  XCTAssertTrue(dequeuedGroups.size() == 1);

  XCTAssertTrue(dequeuedGroups[0] == tailItems1);

  _controller.state = FBSuspensionControllerStateFullySuspended;

  Input::Items tailItems2;
  tailItems2.insert({2, 8}, @3);
  [_controller processTailInsertion:tailItems2];
  XCTAssertTrue(dequeuedGroups.size() == 1);
  XCTAssertTrue([_controller hasPendingChanges]);
}

- (void)testTransitionFromNotSuspendedToFullySuspendedStopsDequeuingOfChangesEvenIfTheTickerIsCalled
{
  _controller.state = FBSuspensionControllerStateNotSuspended;

  __block std::vector<Input::Changeset> dequeuedGroups;
  __block fb_ticker_block_t ticker;
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;
  _outputHandler.tickerController = ^(fb_ticker_block_t tick) {
    ticker = tick;
  };

  Input::Items items1;
  items1.insert({2, 2}, @1);
  Input::Changeset group1 = {items1};
  [_controller processChangeset:group1];

  Input::Items items2;
  items2.insert({2, 8}, @3);
  Input::Changeset group2 = {items2};
  [_controller processChangeset:group2];

  XCTAssertTrue(dequeuedGroups.size() == 1);
  _controller.state = FBSuspensionControllerStateFullySuspended;
  ticker();
  XCTAssertTrue(dequeuedGroups.size() == 1);
  _controller.state = FBSuspensionControllerStateNotSuspended;
  XCTAssertTrue(dequeuedGroups.size() == 2);
}

/**
 This test makes sure that even though we go to a non suspended state we start dequeuing only when the ticker is called.
 e.g :
 - The suspension controller starts unsuspended and apply changeset (1)
 - Before the ticker for changeset (1) is called the suspension controller is fully suspendend, changeset (2) is added and the
 controller go to unsuspended mode again.
 - No changeset should be emmited at this point.
 - And changeset (2) should be emmited only when the ticker corresponding to changeset (1) is called.
 */
- (void)testTransitionFromFullySuspendedToNotSuspendedDoNotDequeueUntilTheTickerHasBeenCalled
{
  _controller.state = FBSuspensionControllerStateNotSuspended;
  __block std::vector<Input::Changeset> dequeuedGroups;
  __block fb_ticker_block_t ticker;
  _outputHandler.tickerController = ^(fb_ticker_block_t tick) {
    ticker = tick;
  };
  id block = ^(const Input::Changeset &g) {
    dequeuedGroups.push_back(g);
  };
  _outputHandler.didDequeueChangeset = block;

  Input::Items items1;
  items1.insert({2, 2}, @1);
  Input::Changeset group1 = {items1};
  [_controller processChangeset:group1];
  XCTAssertTrue(dequeuedGroups.size() == 1);

  _controller.state = FBSuspensionControllerStateFullySuspended;

  Input::Items items2;
  items2.insert({2, 8}, @3);
  Input::Changeset group2 = {items2};
  [_controller processChangeset:group2];

  _controller.state = FBSuspensionControllerStateNotSuspended;
  XCTAssertTrue(dequeuedGroups.size() == 1);
  ticker();
  XCTAssertTrue(dequeuedGroups.size() == 2);
}

@end
