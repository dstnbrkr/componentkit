// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKitTestLib/FBComponentTestRootScope.h>

#import "FBComponent.h"
#import "FBComponentController.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBComponentScope.h"
#import "FBComponentSubclass.h"

@interface FBComponentControllerLifecycleMethodTests : XCTestCase <FBComponentProvider>
@end

struct FBLifecycleMethodCounts {
  NSUInteger willMount;
  NSUInteger didMount;
  NSUInteger willRemount;
  NSUInteger didRemount;
  NSUInteger willUnmount;
  NSUInteger didUnmount;

  NSString *description() const
  {
    return [NSString stringWithFormat:@"willMount:%lu didMount:%lu willRemount:%lu didRemount:%lu willUnmount:%lu didUnmount:%lu",
            (unsigned long)willMount, (unsigned long)didMount, (unsigned long)willRemount,
            (unsigned long)didRemount, (unsigned long)willUnmount, (unsigned long)didUnmount];
  }

  bool operator==(const FBLifecycleMethodCounts &other) const
  {
    return willMount == other.willMount && didMount == other.didMount
    && willRemount == other.willRemount && didRemount == other.didRemount
    && willUnmount == other.willUnmount && didUnmount == other.didUnmount;
  }
};

@interface FBLifecycleComponentController : FBComponentController
{
@public
  FBLifecycleMethodCounts _counts;
}
@end

@interface FBLifecycleComponent : FBComponent
@property (nonatomic, weak) FBLifecycleComponentController *controller;
- (void)updateStateToIncludeNewAttribute;
@end

@implementation FBComponentControllerLifecycleMethodTests

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBLifecycleComponent new];
}

- (void)testThatMountingComponentCallsWillAndDidMount
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  FBLifecycleComponentController *controller = ((FBLifecycleComponent *)state.layout.component).controller;
  const FBLifecycleMethodCounts actual = controller->_counts;
  const FBLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUnmountingComponentCallsWillAndDidUnmount
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  [clm detachFromView];

  FBLifecycleComponentController *controller = ((FBLifecycleComponent *)state.layout.component).controller;
  const FBLifecycleMethodCounts actual = controller->_counts;
  const FBLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileMountedCallsWillAndDidRemount
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  FBLifecycleComponent *component = (FBLifecycleComponent *)state.layout.component;
  [component updateStateToIncludeNewAttribute];

  FBLifecycleComponentController *controller = component.controller;
  const FBLifecycleMethodCounts actual = controller->_counts;
  const FBLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willRemount = 1, .didRemount = 1};
  XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
}

- (void)testThatUpdatingComponentWhileNotMountedCallsNothing
{
  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState state = [clm prepareForUpdateWithModel:nil constrainedSize:{{0,0}, {100, 100}}];
  [clm updateWithState:state];

  UIView *view = [[UIView alloc] init];
  [clm attachToView:view];
  [clm detachFromView];

  FBLifecycleComponent *component = (FBLifecycleComponent *)state.layout.component;
  FBLifecycleComponentController *controller = component.controller;
  {
    const FBLifecycleMethodCounts actual = controller->_counts;
    const FBLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1, .willUnmount = 1, .didUnmount = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  controller->_counts = {}; // Reset all to zero
  [component updateStateToIncludeNewAttribute];
  {
    const FBLifecycleMethodCounts actual = controller->_counts;
    const FBLifecycleMethodCounts expected = {};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }

  [clm attachToView:view];
  {
    const FBLifecycleMethodCounts actual = controller->_counts;
    const FBLifecycleMethodCounts expected = {.willMount = 1, .didMount = 1};
    XCTAssertTrue(actual == expected, @"Expected %@ but got %@", expected.description(), actual.description());
  }
}

@end

@implementation FBLifecycleComponent

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

@implementation FBLifecycleComponentController

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  [(FBLifecycleComponent *)[self component] setController:self];
}

- (void)willMount { [super willMount]; _counts.willMount++; }
- (void)didMount { [super didMount]; _counts.didMount++; }
- (void)willRemount { [super willRemount]; _counts.willRemount++; }
- (void)didRemount { [super didRemount]; _counts.didRemount++; }
- (void)willUnmount { [super willUnmount]; _counts.willUnmount++; }
- (void)didUnmount { [super didUnmount]; _counts.didUnmount++; }

@end
