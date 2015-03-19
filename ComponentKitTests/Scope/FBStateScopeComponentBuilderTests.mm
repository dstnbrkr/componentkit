// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import <FBComponentKit/FBComponentController.h>
#import <FBComponentKit/FBComponentSubclass.h>
#import <FBComponentKit/FBCompositeComponent.h>

#import "FBComponentInternal.h"
#import "FBComponentScopeFrame.h"
#import "FBComponentScopeInternal.h"
#import "FBThreadLocalComponentScope.h"

#pragma mark - Test Components and Controllers

@interface FBMonkeyComponent : FBComponent
@end

@implementation FBMonkeyComponent
@end

@interface FBMonkeyComponentController : FBComponentController
@end

@implementation FBMonkeyComponentController
@end

@interface FBMonkeyComponentWithAnimations : FBComponent
@end

@implementation FBMonkeyComponentWithAnimations
- (std::vector<FBComponentAnimation>)animationsFromPreviousComponent:(FBComponent *)previousComponent { return {}; }
@end

@interface FBStateExposingComponent : FBComponent
@property (nonatomic, strong, readonly) id state;
@end

@implementation FBStateExposingComponent
+ (id)initialState
{
  return @12345;
}
+ (instancetype)new
{
  FBComponentScope scope(self);
  FBStateExposingComponent *c = [super newWithView:{} size:{}];
  if (c) {
    c->_state = scope.state();
  }
  return c;
}
@end

#pragma mark - Tests

@interface FBStateScopeComponentBuilderTests : XCTestCase
@end

@implementation FBStateScopeComponentBuilderTests

#pragma mark - FBBuildComponent

- (void)testThreadLocalStateIsSet
{
  FBComponentScopeFrame *frame = [FBComponentScopeFrame rootFrameWithListener:nil];

  FBComponent *(^block)(void) = ^FBComponent *{
    XCTAssertEqualObjects(FBThreadLocalComponentScope::cursor()->equivalentPreviousFrame(), frame);
    return [FBComponent new];
  };

  (void)FBBuildComponent(nil, frame, block);
}

- (void)testThreadLocalStateIsUnset
{
  FBComponentScopeFrame *frame = nil;

  FBComponent *(^block)(void) = ^FBComponent *{
    return [FBComponent new];
  };

  (void)FBBuildComponent(nil, frame, block);

  XCTAssertTrue(FBThreadLocalComponentScope::cursor()->empty());
}

- (void)testCorrectComponentIsReturned
{
  FBComponentScopeFrame *frame = nil;

  FBComponent __block *c = nil;
  FBComponent *(^block)(void) = ^FBComponent *{
    c = [FBComponent new];
    return c;
  };

  const FBBuildComponentResult result = FBBuildComponent(nil, frame, block);
  XCTAssertEqualObjects(result.component, c);
}

- (void)testResultingFrameContainsCorrectState
{
  FBComponentScopeFrame *frame = nil;

  id state = @12345;

  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBComponent class], nil, ^{ return state; });
    (void)scope.state();
    return [FBComponent new];
  };

  const FBBuildComponentResult result = FBBuildComponent(nil, frame, block);
  XCTAssertEqualObjects([result.scopeFrame existingChildFrameWithClass:[FBComponent class] identifier:nil].state, state);
}

- (void)testStateIsReacquiredAndNewInitialValueBlockIsNotUsed
{
  FBComponentScopeFrame *frame = nil;

  id state = @12345;

  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBComponent class], nil, ^{ return state; });
    (void)scope.state();
    return [FBComponent new];
  };

  const FBBuildComponentResult firstBuildResult = FBBuildComponent(nil, frame, block);

  id __block nextState = nil;
  FBComponent *(^block2)(void) = ^FBComponent *{
    FBComponentScope scope([FBComponent class], nil, ^{ return @67890; });
    nextState = scope.state();
    return [FBComponent new];
  };

  (void)FBBuildComponent(nil, firstBuildResult.scopeFrame, block2);

  XCTAssertEqualObjects(state, nextState);
}

#pragma mark - FBComponentScopeFrameForComponent

- (void)testComponentStateIsSetToInitialStateValue
{
  FBComponentScopeFrame *frame = nil;

  FBComponent *(^block)(void) = ^FBComponent *{
    return [FBStateExposingComponent new];
  };

  FBStateExposingComponent *component = (FBStateExposingComponent *)FBBuildComponent(nil, frame, block).component;
  XCTAssertEqualObjects(component.state, [FBStateExposingComponent initialState]);
}

- (void)testStateScopeFrameIsNotFoundForComponentWhenClassNamesDoNotMatch
{
  FBComponentScopeFrame *frame = nil;

  id state = @12345;

  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBCompositeComponent class], nil, ^{ return state; });
    FBComponent *c = [FBComponent new];
    (void)scope.state();
    return c;
  };

  FBComponent *component = FBBuildComponent(nil, frame, block).component;
  XCTAssertNil(component.scopeFrameToken);
}

- (void)testStateScopeFrameIsNotFoundWhenAnotherComponentInTheSameScopeAcquiresItFirst
{
  FBComponentScopeFrame *frame = nil;

  FBComponent __block *innerComponent = nil;

  id state = @12345;

  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBComponent class], nil, ^{ return state; });

    (void)scope.state();
    innerComponent = [FBComponent new];

    return [FBComponent new];
  };

  FBComponent *outerComponent = FBBuildComponent(nil, frame, block).component;
  XCTAssertNotNil(innerComponent.scopeFrameToken);
  XCTAssertNil(outerComponent.scopeFrameToken);
}

#pragma mark - Controller Construction

- (void)testComponentWithControllerThrowsIfNoScopeExistsForTheComponent
{
  FBComponent *(^block)(void) = ^FBComponent *{
    return [FBMonkeyComponent new];
  };

  FBComponentScopeFrame *frame = nil;
  XCTAssertThrows((void)FBBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerDoesNotThrowIfScopeExistsForTheComponent
{
  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBMonkeyComponent class]);
    return [FBMonkeyComponent new];
  };

  FBComponentScopeFrame *frame = nil;
  XCTAssertNoThrow((void)FBBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerThatHasAnimationsThrowsIfNoScopeExistsForTheComponent
{
  FBComponent *(^block)(void) = ^FBComponent *{
    return [FBMonkeyComponentWithAnimations new];
  };

  FBComponentScopeFrame *frame = nil;
  XCTAssertThrows((void)FBBuildComponent(nil, frame, block));
}

- (void)testComponentWithControllerThatHasAnimationsDoesNotThrowIfScopeExistsForTheComponent
{
  FBComponent *(^block)(void) = ^FBComponent *{
    FBComponentScope scope([FBMonkeyComponentWithAnimations class]);
    return [FBMonkeyComponentWithAnimations new];
  };

  FBComponentScopeFrame *frame = nil;
  XCTAssertNoThrow((void)FBBuildComponent(nil, frame, block));
}

@end
