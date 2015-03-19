// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKitTestLib/FBComponentTestRootScope.h>

#import "FBComponent.h"
#import "FBComponentController.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBComponentScope.h"
#import "FBComponentSubclass.h"
#import "FBComponentViewInterface.h"

@interface FBComponentControllerTests : XCTestCase <FBComponentProvider>
@end

@interface FBFooComponentController : FBComponentController
@property (nonatomic, assign) BOOL calledDidAcquireView;
@property (nonatomic, assign) BOOL calledWillRelinquishView;
@property (nonatomic, assign) BOOL calledDidUpdateComponent;
@end

@interface FBFooComponent : FBComponent
@property (nonatomic, weak) FBFooComponentController *controller;
- (void)updateStateToIncludeNewAttribute;
@end

@implementation FBComponentControllerTests

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBFooComponent new];
}

- (void)testThatCreatingComponentDoesNotInstantiateItsController
{
  FBComponentTestRootScope scope;

  FBFooComponent *fooComponent = [FBFooComponent new];
  XCTAssertNil(fooComponent.controller, @"Didn't expect creating a component to create a controller");
}

- (void)testThatAttachingManagerInstantiatesComponentController
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  XCTAssertNotNil(fooComponent.controller, @"Expected mounting a component to create controller");
}

- (void)testThatRemountingUnchangedComponentDoesNotCallDidUpdateComponent
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  FBFooComponentController *controller = fooComponent.controller;

  [clm detachFromView];
  controller.calledDidUpdateComponent = NO; // Reset to NO
  [clm attachToView:view];
  XCTAssertFalse(controller.calledDidUpdateComponent, @"Component did not update so should not call didUpdateComponent");
}

- (void)testThatUpdatingManagerUpdatesComponentController
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  UIView *view = [[UIView alloc] init];

  FBComponentLifecycleManagerState state1 = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state1];
  [clm attachToView:view];
  FBFooComponent *fooComponent1 = (FBFooComponent *)state1.layout.component;

  FBComponentLifecycleManagerState state2 = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state2];
  FBFooComponent *fooComponent2 = (FBFooComponent *)state1.layout.component;

  XCTAssertTrue(fooComponent1.controller == fooComponent2.controller,
                @"Expected controller %@ to match %@",
                fooComponent1.controller, fooComponent2.controller);
}

- (void)testThatAttachingManagerCallsDidAcquireView
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
}

- (void)testThatDetachingManagerCallsDidRelinquishView
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  XCTAssertFalse(fooComponent.controller.calledWillRelinquishView, @"Did not expect view to be released before detach");

  [clm detachFromView];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected detach to call release view");
  XCTAssertNil(fooComponent.controller.view, @"Expected detach to release view");
}

- (void)testThatUpdatingStateWhileAttachedRelinquishesOldViewAndAcquiresNewOne
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected mounting to acquire view");
  XCTAssertNotNil(fooComponent.controller.view, @"Expected mounting to acquire view");
  UIView *originalView = fooComponent.controller.view;

  fooComponent.controller.calledDidAcquireView = NO; // reset

  [fooComponent updateStateToIncludeNewAttribute];
  XCTAssertTrue(fooComponent.controller.calledWillRelinquishView, @"Expected state update to relinquish old view");
  XCTAssertTrue(fooComponent.controller.calledDidAcquireView, @"Expected state update to relinquish old view");
  XCTAssertTrue(originalView != fooComponent.controller.view, @"Expected different view");
}

- (void)testThatResponderChainIsInOrderComponentThenControllerThenRootView
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class]
                                                                                            context:nil];
  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];

  FBFooComponent *fooComponent = (FBFooComponent *)state.layout.component;
  XCTAssertEqualObjects([fooComponent nextResponder], fooComponent.controller,
                       @"Component's nextResponder should be component controller");
  XCTAssertEqualObjects([fooComponent.controller nextResponder], view,
                       @"Root component's controller's nextResponder should be root view");
}

@end


@implementation FBFooComponent

+ (id)initialState
{
  return @NO;
}

+ (instancetype)new
{
  FBComponentScope scope(self); // components with controllers must have a scope
  FBViewComponentAttributeValueMap attrs;
  if ([scope.state() boolValue]) {
    attrs.insert({@selector(setBackgroundColor:), [UIColor redColor]});
  }
  return [super newWithView:{[UIView class], std::move(attrs)} size:{}];
}

- (void)updateStateToIncludeNewAttribute
{
  [self updateState:^(id oldState){
    return @YES;
  }];
}
@end

@implementation FBFooComponentController

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  ((FBFooComponent *)self.component).controller = self;
  _calledDidUpdateComponent = YES;
}

- (void)componentWillRelinquishView
{
  [super componentWillRelinquishView];
  _calledWillRelinquishView = YES;
}

- (void)componentDidAcquireView
{
  [super componentDidAcquireView];
  _calledDidAcquireView = YES;
}

@end
