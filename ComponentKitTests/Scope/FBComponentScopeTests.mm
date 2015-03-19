// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKit/FBCompositeComponent.h>

#import "FBComponentScopeFrame.h"
#import "FBThreadLocalComponentScope.h"

@interface FBComponentScopeTests : XCTestCase
@end

@implementation FBComponentScopeTests

- (void)testThreadLocalStateIsEmptyByDefault
{
  XCTAssertTrue(FBThreadLocalComponentScope::cursor() != nullptr);
  XCTAssertTrue(FBThreadLocalComponentScope::cursor()->empty());
}

- (void)testThreadLocalStateIsNotNullAfterCreatingThreadStateScope
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil,frame);
  XCTAssertTrue(FBThreadLocalComponentScope::cursor() != nullptr);
}

- (void)testThreadLocalStateStoresPassedInFrameAsEquivalentPreviousFrame
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);
  XCTAssertEqualObjects(FBThreadLocalComponentScope::cursor()->equivalentPreviousFrame(), frame);
}

- (void)testThreadLocalStateBeginsWithRootCurrentFrame
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);

  FBComponentScopeFrame *currentFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  XCTAssertTrue(currentFrame != NULL);
}

- (void)testThreadLocalStatePushesChildScope
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);

  FBComponentScopeFrame *rootFrame = FBThreadLocalComponentScope::cursor()->currentFrame();

  FBComponentScope scope([FBCompositeComponent class]);

  FBComponentScopeFrame *currentFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  XCTAssertTrue(currentFrame != rootFrame);
}

- (void)testCreatingThreadLocalStateScopeThrowsIfScopeAlreadyExists
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];

  FBThreadLocalComponentScope threadScope(nil, frame);
  XCTAssertThrows(FBThreadLocalComponentScope(nil, frame));
}

#pragma mark - Scope Frame

- (void)testHasChildScopeIsCreatedWithCorrectKeys
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBComponentScopeFrame *childFrame = [frame childFrameWithComponentClass:[FBCompositeComponent class]
                                                               identifier:@"moose"
                                                                    state:@123
                                                               controller:nil];

  XCTAssertEqual(childFrame.componentClass, [FBCompositeComponent class]);
  XCTAssertEqualObjects(childFrame.identifier, @"moose");
  XCTAssertEqualObjects(childFrame.state, @123);
}

- (void)testHasChildScopeReturnsTrueWhenTheScopeMatches
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBComponentScopeFrame __unused *childFrame = [frame childFrameWithComponentClass:[FBCompositeComponent class]
                                                                        identifier:@"moose"
                                                                             state:@123
                                                                        controller:nil];

  XCTAssertNotNil([frame existingChildFrameWithClass:[FBCompositeComponent class] identifier:@"moose"]);
  XCTAssertNil([frame existingChildFrameWithClass:[FBCompositeComponent class] identifier:@"meese"]);
  XCTAssertNil([frame existingChildFrameWithClass:[FBCompositeComponent class] identifier:nil]);

  XCTAssertNil([frame existingChildFrameWithClass:[NSArray class] identifier:@"moose"]);
  XCTAssertNil([frame existingChildFrameWithClass:[NSArray class] identifier:nil]);
}

- (void)testFrameIsPoppedWhenScopeCloses
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);

  FBComponentScopeFrame *rootFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  {
    FBComponentScope scope([FBCompositeComponent class], @"moose");
    XCTAssertTrue(FBThreadLocalComponentScope::cursor()->currentFrame() != rootFrame);
  }
  XCTAssertEqual(FBThreadLocalComponentScope::cursor()->currentFrame(), rootFrame);
}

- (void)testHasChildScopeIsTrueEvenAfterScopeClosesAndPopsAFrame
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);

  FBComponentScopeFrame *rootFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  {
    FBComponentScope scope([FBCompositeComponent class], @"moose");
  }
  XCTAssertEqual(FBThreadLocalComponentScope::cursor()->currentFrame(), rootFrame);
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDown
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBComponentScopeFrame *createdFrame = NULL;
  {
    FBThreadLocalComponentScope threadScope(nil, frame);
    {
      FBComponentScope scope([FBCompositeComponent class], @"macaque", ^{ return @42; });
      id __unused state = scope.state();
    }

    createdFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  }

  FBComponentScopeFrame *createdFrame2 = NULL;
  {
    FBThreadLocalComponentScope threadScope(nil, createdFrame);
    {
      // This block should never be called. We should inherit the previous scope.
      BOOL __block blockCalled = NO;
      FBComponentScope scope([FBCompositeComponent class], @"macaque", ^{
        blockCalled = YES;
        return @365;
      });
      id state = scope.state();
      XCTAssertFalse(blockCalled);
      XCTAssertEqualObjects(state, @42);
    }

    createdFrame2 = FBThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSibling
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBComponentScopeFrame *createdFrame = NULL;
  {
    FBThreadLocalComponentScope threadScope(nil, frame);
    {
      FBComponentScope scope([FBCompositeComponent class], @"spongebob", ^{ return @"FUN"; });
      id __unused state = scope.state();
    }
    {
      FBComponentScope scope([FBCompositeComponent class], @"patrick", ^{ return @"HAHA"; });
      id __unused state = scope.state();
    }

    createdFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  }

  FBComponentScopeFrame *createdFrame2 = nullptr;
  {
    FBThreadLocalComponentScope threadScope(nil, createdFrame);
    {
      // This block should never be called. We should inherit the previous scope.
      FBComponentScope scope([FBCompositeComponent class], @"spongebob", ^{ return @"rotlf-nope!"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"FUN");
    }
    {
      // This block should never be called. We should inherit the previous scope.
      FBComponentScope scope([FBCompositeComponent class], @"patrick", ^{ return @"rotlf-nope!"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"HAHA");
    }

    createdFrame2 = FBThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testThreadStateScopeAcquiringPreviousScopeStateOneLevelDownWithSiblingThatDoesNotAcquire
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBComponentScopeFrame *createdFrame = NULL;
  {
    FBThreadLocalComponentScope threadScope(nil, frame);
    {
      FBComponentScope scope([FBCompositeComponent class], @"Quoth", ^{ return @"nevermore"; });
      id __unused state = scope.state();
    }
    {
      FBComponentScope scope([FBCompositeComponent class], @"perched", ^{ return @"raven"; });
      id __unused state = scope.state();
    }

    createdFrame = FBThreadLocalComponentScope::cursor()->currentFrame();
  }

  FBComponentScopeFrame *createdFrame2 = nullptr;
  {
    FBThreadLocalComponentScope threadScope(nil, createdFrame);
    {
      // This block should never be called. We should inherit the previous scope.
      FBComponentScope scope([FBCompositeComponent class], @"Quoth", ^{ return @"Lenore"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"nevermore");
    }
    {
      FBComponentScope scope([FBCompositeComponent class], @"chamber", ^{ return @"door"; });
      id state = scope.state();
      XCTAssertEqualObjects(state, @"door");
    }

    createdFrame2 = FBThreadLocalComponentScope::cursor()->currentFrame();
  }
}

- (void)testCreatingSiblingScopeWithSameClassNameThrows
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);
  {
    FBComponentScope scope([FBCompositeComponent class]);
  }
  {
    XCTAssertThrows(FBComponentScope([FBCompositeComponent class]));
  }
}

- (void)testCreatingSiblingScopeWithSameClassNameAndSameIdentifierThrows
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);
  {
    FBComponentScope scope([FBCompositeComponent class], @"lasagna");
  }
  {
    XCTAssertThrows(FBComponentScope([FBCompositeComponent class], @"lasagna"));
  }
}

- (void)testCreatingSiblingScopeWithSameClassButDifferentIdenfitiferDoesNotThrow
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];
  FBThreadLocalComponentScope threadScope(nil, frame);
  {
    FBComponentScope scope([FBCompositeComponent class], @"linguine");
  }
  {
    XCTAssertNoThrow(FBComponentScope([FBCompositeComponent class], @"spaghetti"));
  }
}

- (void)testTeardownThrowsIfStateScopeHasNotBeenPoppedBackToTheRoot
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];

  BOOL exceptionThrown = NO;
  @try {
    FBThreadLocalComponentScope threadScope(nil, frame);

    FBComponentScopeFrame *frame2 = [FBComponentScopeFrame rootFrameWithListener:nil];
    FBThreadLocalComponentScope::cursor()->pushFrameAndEquivalentPreviousFrame(frame2, nil);
  } @catch(...) {
    exceptionThrown = YES;
  }

  XCTAssertTrue(exceptionThrown);
  FBThreadLocalComponentScope::cursor()->popFrame();
  XCTAssertTrue(FBThreadLocalComponentScope::cursor()->empty());
}

@end
