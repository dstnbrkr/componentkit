// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import <FBComponentKitTestLib/FBComponentHostingViewTestModel.h>

#import "FBComponent.h"
#import "FBComponentFlexibleSizeRangeProvider.h"
#import "FBComponentHostingView.h"
#import "FBComponentHostingViewDelegate.h"
#import "FBComponentHostingViewInternal.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentViewInterface.h"

@interface FBComponentHostingViewTests : XCTestCase <FBComponentProvider, FBComponentHostingViewDelegate>
@end

@interface FBFakeComponentLifecycleManager : NSObject
@property (nonatomic, assign) BOOL updateWithStateWasCalled;
@end

@implementation FBFakeComponentLifecycleManager {
  BOOL _isAttached;
}

- (FBComponentLifecycleManagerState)prepareForUpdateWithModel:(id)model constrainedSize:(FBSizeRange)constrainedSize
{
  return FBComponentLifecycleManagerStateEmpty;
}

- (void)updateWithState:(const FBComponentLifecycleManagerState &)state
{
  self.updateWithStateWasCalled = YES;
}

- (void)attachToView:(UIView *)view
{
  _isAttached = YES;
}

- (void)detachFromView
{
  _isAttached = NO;
}

- (BOOL)isAttachedToView
{
  return _isAttached;
}

- (void)setDelegate:(id<FBComponentLifecycleManagerDelegate>)delegate {}

@end

@implementation FBComponentHostingViewTests {
  BOOL _calledSizeDidInvalidate;
}

+ (FBComponent *)componentForModel:(FBComponentHostingViewTestModel *)model context:(id<NSObject>)context
{
  return FBComponentWithHostingViewTestModel(model);
}

- (FBComponentHostingView *)newHostingView
{
  FBComponentLifecycleManager *manager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  return [self newHostingViewWithLifecycleManager:manager];
}

- (FBComponentHostingView *)newHostingViewWithLifecycleManager:(FBComponentLifecycleManager *)manager
{
  FBComponentHostingViewTestModel *model = [[FBComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:FBComponentSize::fromCGSize(CGSizeMake(50, 50))];
  FBComponentHostingView *view = [[FBComponentHostingView alloc] initWithLifecycleManager:manager sizeRangeProvider:[FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibleWidthAndHeight] model:model];
  view.bounds = CGRectMake(0, 0, 100, 100);
  [view layoutIfNeeded];
  return view;
}

- (void)tearDown
{
  _calledSizeDidInvalidate = NO;
  [super tearDown];
}

- (void)testInitializationInsertsContainerViewInHierarchy
{
  FBComponentHostingView *hostingView = [self newHostingView];
  XCTAssertTrue(hostingView.subviews.count == 1, @"Expect hosting view to have a single subview.");
}

- (void)testInitializationInsertsComponentViewInHierarcy
{
  FBComponentHostingView *hostingView = [self newHostingView];

  XCTAssertTrue([hostingView.containerView.subviews count] > 0, @"Expect that initialization should insert component view as subview of container view.");
}

- (void)testLifecycleManagerAttachedToContainerAndNotRoot
{
  FBComponentHostingView *hostingView = [self newHostingView];
  XCTAssertNil(hostingView.fb_componentLifecycleManager, @"Expect hosting view to have no lifecycle manager.");
  XCTAssertNotNil(hostingView.containerView.fb_componentLifecycleManager, @"Expect container view to have a lifecycle manager.");
}

- (void)testUpdatesOnBoundsChange
{
  id fakeManager = [[FBFakeComponentLifecycleManager alloc] init];
  FBComponentHostingView *hostingView = [self newHostingViewWithLifecycleManager:fakeManager];

  hostingView.bounds = CGRectMake(0, 0, 100, 100);

  XCTAssertTrue([fakeManager updateWithStateWasCalled], @"Expect update to be triggered on bounds change.");
}

- (void)testUpdatesOnModelChange
{
  id fakeManager = [[FBFakeComponentLifecycleManager alloc] init];
  FBComponentHostingView *hostingView = [self newHostingViewWithLifecycleManager:fakeManager];
  FBComponentHostingViewTestModel *model = [[FBComponentHostingViewTestModel alloc] initWithColor:[UIColor redColor] size:FBComponentSize::fromCGSize(CGSizeMake(50, 50))];

  hostingView.model = model;

  XCTAssertTrue([fakeManager updateWithStateWasCalled], @"Expect update to be triggered on bounds change.");
}

- (void)testCallsDelegateOnSizeChange
{
  FBComponentHostingView *hostingView = [self newHostingView];
  hostingView.delegate = self;
  hostingView.model = [[FBComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:FBComponentSize::fromCGSize(CGSizeMake(75, 75))];
  hostingView.bounds = (CGRect){ .size = [hostingView sizeThatFits:CGSizeMake(75, CGFLOAT_MAX)] };
  [hostingView layoutIfNeeded];

  XCTAssertTrue(_calledSizeDidInvalidate, @"Expect -componentHostingViewSizeDidInvalidate: to be called when component size changes.");
}

- (void)testUpdateWithEmptyBoundsDoesntAttachLifecycleManager
{
  FBComponentLifecycleManager *manager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  FBComponentHostingViewTestModel *model = [[FBComponentHostingViewTestModel alloc] initWithColor:[UIColor orangeColor] size:FBComponentSize::fromCGSize(CGSizeMake(50, 50))];
  FBComponentHostingView *hostingView = [[FBComponentHostingView alloc] initWithLifecycleManager:manager sizeRangeProvider:[FBComponentFlexibleSizeRangeProvider providerWithFlexibility:FBComponentSizeRangeFlexibleWidthAndHeight] model:model];
  [hostingView layoutIfNeeded];

  XCTAssertFalse([manager isAttachedToView], @"Expect lifecycle manager to not be attached to the view when the bounds rect is empty.");
}

#pragma mark - FBComponentHostingViewDelegate

- (void)componentHostingViewDidInvalidateSize:(FBComponentHostingView *)hostingView
{
  _calledSizeDidInvalidate = YES;
}

@end
