// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponent.h"
#import "FBComponentAnimation.h"
#import "FBComponentController.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBComponentScope.h"
#import "FBComponentViewInterface.h"
#import "FBCompositeComponent.h"

static BOOL notified;

@interface FBCoolComponent : FBCompositeComponent
@property (readwrite, nonatomic, weak) FBComponentController *controller;
+ (instancetype)newCoolComponentWithModel:(id<NSObject>)model;
@end

@implementation FBCoolComponent
+ (instancetype)newCoolComponentWithModel:(id<NSObject>)model
{
  FBComponentScope scope(self);
  return [super newWithComponent:
          [FBComponent
           newWithView:{[UIView class], {{@selector(setBackgroundColor:), (UIColor *)model}}}
           size:{}]];
}
@end

@interface FBCoolComponentController : FBComponentController
@end

@implementation FBCoolComponentController
- (void)componentTreeWillAppear
{
  [super componentTreeWillAppear];
  notified = YES;
}

- (void)didUpdateComponent
{
  [super didUpdateComponent];
  ((FBCoolComponent *)self.component).controller = self;
}

@end

@interface FBComponentLifecycleManagerTests : XCTestCase <FBComponentProvider, FBComponentLifecycleManagerDelegate>
@end

@implementation FBComponentLifecycleManagerTests {
  BOOL _calledLifecycleManagerSizeDidChange;
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return [FBCoolComponent newCoolComponentWithModel:model];
}

static const FBSizeRange size = {{0,0}, {40.0, 40.0}};

- (void)tearDown
{
  _calledLifecycleManagerSizeDidChange = NO;
  [super tearDown];
}

- (void)testRepeatedPrepareForUpdateWithoutMountingConstructsNewComponents
{
  NSObject *model = [UIColor clearColor];
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:model constrainedSize:size];
  FBCoolComponent *componentA = (FBCoolComponent *)stateA.layout.component;

  FBComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:model constrainedSize:size];
  FBCoolComponent *componentB = (FBCoolComponent *)stateB.layout.component;

  XCTAssertTrue(componentA != componentB);
}

- (void)testRepeatedPrepareForUpdateWithoutMountingUsesPreviouslyComputedState
{
  NSObject *model = [UIColor clearColor];
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];

  FBComponentLifecycleManagerState stateA = [lifeManager prepareForUpdateWithModel:model constrainedSize:size];
  FBCoolComponent *componentA = (FBCoolComponent *)stateA.layout.component;
  FBComponentController *controllerA = componentA.controller;

  FBComponentLifecycleManagerState stateB = [lifeManager prepareForUpdateWithModel:model constrainedSize:size];
  FBCoolComponent *componentB = (FBCoolComponent *)stateB.layout.component;
  FBComponentController *controllerB = componentB.controller;

  XCTAssertTrue(controllerA == controllerB);
}

- (void)testAttachingManagerInsertsComponentViewInHierarchy
{
  NSObject *model = [UIColor clearColor];
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:model constrainedSize:size]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

  XCTAssertTrue([view.subviews count] == 0, @"Expect an empty view before mounting");
  [lifeManager attachToView:view];
  XCTAssertTrue([view.subviews count] > 0, @"Does not expect an empty view after mounting");
}

- (void)testIsAttachedToView
{
  NSObject *model = [UIColor clearColor];
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:model constrainedSize:size]];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  XCTAssertFalse([lifeManager isAttachedToView], @"Expect -isAttachedToView to be false before mounting.");
  [lifeManager attachToView:view];
  XCTAssertTrue([lifeManager isAttachedToView], @"Expect -isAttachedToView to be true after mounting.");
}

- (void)testAttachingManagerToViewAlreadyAttachedToAnotherManagerChangesViewManagerToNewManager
{
  FBComponentLifecycleManager *firstLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]
                         ];
  FBComponentLifecycleManager *secondLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:[UIColor blueColor] constrainedSize:size]
                          ];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];
  XCTAssertEqualObjects(view.fb_componentLifecycleManager, secondLifeManager, @"Expect fb_componentLifecycleManager to point to previous manager");
}

- (void)testAttachingManagerToViewAlreadyAttachedToAnotherManagerMountsTheCorrectComponent
{
  NSObject *firstModel = [UIColor redColor];
  NSObject *secondModel = [UIColor blueColor];
  FBComponentLifecycleManager *firstLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:firstModel constrainedSize:size]
                         ];
  FBComponentLifecycleManager *secondLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:secondModel constrainedSize:size]
                          ];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];

  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], secondModel, @"Expect the last component mounted to be rendered in the view");
}

- (void)testUpdatingAManagerDetachedByNewManagerDoesNotUpdateViewAttachedToNewManager
{
  FBComponentLifecycleManager *firstLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]
                         ];
  FBComponentLifecycleManager *secondLifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [secondLifeManager updateWithState:[secondLifeManager prepareForUpdateWithModel:[UIColor blueColor] constrainedSize:size]
                          ];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [firstLifeManager attachToView:view];
  [secondLifeManager attachToView:view];

  [firstLifeManager updateWithState:[firstLifeManager prepareForUpdateWithModel:[UIColor greenColor] constrainedSize:size]
                         ];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], [UIColor blueColor],
                        @"Expect the last manager attached to the view to be controlling color, not the first manager");
}

- (void)testUpdatingAManagerAfterDetachDoesNotUpdateView
{
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]
                    ];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 40.0, 40.0)];
  [lifeManager attachToView:view];
  [lifeManager detachFromView];

  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor greenColor] constrainedSize:size]
                    ];
  XCTAssertEqualObjects([[view.subviews firstObject] backgroundColor], [UIColor redColor],
                        @"Expect the manager to leave view untouched after detach");
}

- (void)testNotifyingControllerThroughLifecycleManager
{
  notified = NO;
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]
                    ];
  [lifeManager componentTreeWillAppear];
  XCTAssertTrue(notified, @"Expect the controller to be notified of the event");
}

- (void)testCallingUpdateWithStateTriggersSizeDidChangeCallback
{
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager setDelegate:self];
  [lifeManager updateWithState:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]
                    ];
  XCTAssertTrue(_calledLifecycleManagerSizeDidChange, @"Expect the manager to be notified when the size changes as a result of a call to -updateWithState:");
}

- (void)testCallingUpdateWithStateWithoutMountingDoesNotTriggerSizeDidChangeCallback
{
  FBComponentLifecycleManager *lifeManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifeManager setDelegate:self];
  [lifeManager updateWithStateWithoutMounting:[lifeManager prepareForUpdateWithModel:[UIColor redColor] constrainedSize:size]];

  // It is important that that -componentLifecycleManager:sizeDidChangeWithAnimation: is not called when calling
  // -updateWithStateWithoutMounting:, because this would result in nested -beginUpdates/-endUpdates
  // calls inside FBComponentDataSource.
  XCTAssertFalse(_calledLifecycleManagerSizeDidChange, @"Expect the manager to NOT be notified of size changes as a result of a call to -updateWithStateWithoutMounting:");
}

#pragma mark - FBComponentLifecycleManagerDelegate

- (void)componentLifecycleManager:(FBComponentLifecycleManager *)manager
       sizeDidChangeWithAnimation:(const FBComponentBoundsAnimation &)animation
{
  _calledLifecycleManagerSizeDidChange = YES;
}

@end
