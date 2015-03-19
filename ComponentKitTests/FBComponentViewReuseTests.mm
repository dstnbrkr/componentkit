// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "ComponentViewManager.h"
#import "ComponentViewReuseUtilities.h"
#import "FBComponent.h"
#import "FBComponentInternal.h"
#import "FBComponentLifecycleManager.h"
#import "FBComponentProvider.h"
#import "FBCompositeComponent.h"

@interface FBComponentViewReuseTests : XCTestCase <FBComponentProvider>
@end

/** Injects a view not controlled by components and specifies its children should be mounted inside it. */
@interface FBViewInjectingComponent : FBCompositeComponent
@end

/** Doesn't actually do anything, just provides a BOOL for storage. */
@interface FBReuseAwareView : UIView
@property (nonatomic, assign, getter=isInReusePool) BOOL inReusePool;
@end

using namespace FB::Component;

@implementation FBComponentViewReuseTests

- (void)testThatRecyclingViewWithoutEnteringReusePoolDoesNotCallReuseBlocks
{
  FBComponent *component =
  [FBComponent
   newWithView:{
     {
       "reuse-aware-view",
       ^{ return [[UIView alloc] init]; },
       ^(UIView *v){ XCTFail(@"Didn't expect to have didEnterReusePool called"); },
       ^(UIView *v){ XCTFail(@"Didn't expect to have willLeaveReusePool called"); }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  FB::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *subview;
  {
    ViewManager m(container);
    subview = m.viewForConfiguration([component class], [component viewConfiguration]);
  }

  {
    ViewManager m(container);
    XCTAssertTrue(subview == m.viewForConfiguration([component class], [component viewConfiguration]), @"Expected to receive recycled view");
  }
}

- (void)testThatViewEnteringReusePoolTriggersCallToDidEnterReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;
  FBComponent *firstComponent =
  [FBComponent
   newWithView:{
     {
       "reuse-aware-view",
       ^{ return [[UIView alloc] init]; },
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect to have willLeaveReusePool called"); }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  FB::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *createdView;
  {
    ViewManager m(container);
    createdView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  FBComponent *secondComponent = [FBComponent newWithView:{[UIImageView class], {}} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertTrue(viewThatEnteredReusePool == createdView, @"Expected created view %@ to enter pool but got %@",
               createdView, viewThatEnteredReusePool);
}

- (void)testThatViewLeavingReusePoolTriggersCallToWillLeaveReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;
  __block BOOL calledWillLeaveReusePool = NO;
  FBComponent *firstComponent =
  [FBComponent
   newWithView:{
     {
       "reuse-aware-view",
       ^{ return [[UIView alloc] init]; },
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){
         XCTAssertTrue(v == viewThatEnteredReusePool, @"Expected %@ but got %@", viewThatEnteredReusePool, v);
         calledWillLeaveReusePool = YES;
       }
     },
     {}
   }
   size:{}];

  UIView *container = [[UIView alloc] init];
  FB::Component::ViewReuseUtilities::mountingInRootView(container);
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  FBComponent *secondComponent = [FBComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  {
    ViewManager m(container);
    (void)m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
  }

  XCTAssertTrue(calledWillLeaveReusePool, @"Expected to call willLeaveReusePool when recycling view");
}

- (void)testThatHidingParentViewTriggersCallToDidEnterReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;

  FBComponent *innerComponent =
  [FBComponent
   newWithView:{
     {
       "reuse-aware-view",
       ^{ return [[UIView alloc] init]; },
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect willLeaveReusePool"); }
     },
     {}
   }
   size:{}];

  FBComponent *firstComponent =
  [FBCompositeComponent
   newWithView:{[UIView class], {}}
   component:innerComponent];

  UIView *container = [[UIView alloc] init];
  FB::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *topLevelView;
  {
    ViewManager m(container);
    topLevelView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
    {
      ViewManager m2(topLevelView);
      (void)m2.viewForConfiguration([innerComponent class], [innerComponent viewConfiguration]);
    }
  }

  FBComponent *secondComponent = [FBComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertNotNil(viewThatEnteredReusePool, @"Expected view to enter reuse pool when its parent was hidden");
  XCTAssertFalse(viewThatEnteredReusePool.hidden, @"View that entered pool should not be hidden since its parent was");
  XCTAssertTrue(topLevelView.hidden, @"Top-level view should be hidden for reuse");
}

- (void)testThatUnhidingParentViewButLeavingChildViewHiddenLeavesViewInReusePool
{
  __block UIView *viewThatEnteredReusePool = nil;

  FBComponent *innerComponent =
  [FBComponent
   newWithView:{
     {
       "reuse-aware-view",
       ^{ return [[UIView alloc] init]; },
       ^(UIView *v){ viewThatEnteredReusePool = v; },
       ^(UIView *v){ XCTFail(@"Didn't expect willLeaveReusePool"); }
     },
     {}
   }
   size:{}];

  FBComponent *firstComponent =
  [FBCompositeComponent
   newWithView:{[UIView class], {}}
   component:innerComponent];

  UIView *container = [[UIView alloc] init];
  FB::Component::ViewReuseUtilities::mountingInRootView(container);
  UIView *topLevelView;
  {
    ViewManager m(container);
    topLevelView = m.viewForConfiguration([firstComponent class], [firstComponent viewConfiguration]);
    {
      ViewManager m2(topLevelView);
      (void)m2.viewForConfiguration([innerComponent class], [innerComponent viewConfiguration]);
    }
  }

  FBComponent *secondComponent = [FBComponent newWithView:{[UIImageView class]} size:{}];
  {
    ViewManager m(container);
    (void)m.viewForConfiguration([secondComponent class], [secondComponent viewConfiguration]);
  }

  XCTAssertNotNil(viewThatEnteredReusePool, @"Expected view to enter reuse pool when its parent was hidden");
  XCTAssertFalse(viewThatEnteredReusePool.hidden, @"View that entered pool should not be hidden since its parent was");

  FBComponent *thirdComponent =
  [FBCompositeComponent
   newWithView:{[UIView class], {}}
   component:[FBComponent newWithView:{} size:{}]];
  {
    ViewManager m(container);
    UIView *newestTopLevelView = m.viewForConfiguration([thirdComponent class], [thirdComponent viewConfiguration]);
    XCTAssertTrue(newestTopLevelView == topLevelView, @"Expected top level view to be reused");
    {
      ViewManager m2(newestTopLevelView);
    }
  }

  XCTAssertTrue(viewThatEnteredReusePool.hidden, @"View should now be hidden since its parent was unhidden");
  // The key here is that we did *not* receive any notifications about leaving the pool since it remained in the pool,
  // even though its parent was unhidden and it was hidden.
}

- (void)testThatComponentThatInjectsAnIntermediateViewNotControlledByComponentsDoesNotBreakViewReuseForItsSubviews
{
  UIView *rootView = [[UIView alloc] init];

  FBComponentLifecycleManager *clm = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [clm updateWithState:[clm prepareForUpdateWithModel:@NO constrainedSize:{{0,0}, {100, 100}}]];
  [clm attachToView:rootView];

  // Find the reuse aware view
  FBReuseAwareView *reuseAwareView = [[[[[[rootView subviews] firstObject] subviews] firstObject] subviews] firstObject];
  XCTAssertFalse(reuseAwareView.inReusePool, @"Shouldn't be in reuse pool now, it's just been mounted");

  // Update to a totally different component so that the reuse aware view's parent should be hidden
  [clm updateWithState:[clm prepareForUpdateWithModel:@YES constrainedSize:{{0,0}, {100, 100}}]];
  XCTAssertTrue(reuseAwareView.inReusePool, @"Should be in reuse pool as its parent is hidden by components");
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  if ([(NSNumber *)model boolValue]) {
    return [FBComponent newWithView:{[UIView class]} size:{50, 50}];
  } else {
    return [FBViewInjectingComponent
            newWithComponent:
            [FBComponent
             newWithView:{
               {
                 "reuse-aware-view",
                 ^{ return [[FBReuseAwareView alloc] init]; },
                 ^(UIView *v){ ((FBReuseAwareView *)v).inReusePool = YES; },
                 ^(UIView *v){ ((FBReuseAwareView *)v).inReusePool = NO; }
               },
               {}
             }
             size:{}]];
  }
}

@end

@interface FBInjectingView : UIView
@property (nonatomic, strong, readonly) UIView *injectedView;
@end

@implementation FBInjectingView
- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _injectedView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:_injectedView];
  }
  return self;
}
- (void)layoutSubviews
{
  [super layoutSubviews];
  [_injectedView setFrame:{CGPointZero, [self bounds].size}];
}
@end

@implementation FBViewInjectingComponent

+ (instancetype)newWithComponent:(FBComponent *)component
{
  return [super newWithView:{[FBInjectingView class]} component:component];
}

- (FB::Component::MountResult)mountInContext:(const FB::Component::MountContext &)context
size:(const CGSize)size
children:(std::shared_ptr<const std::vector<FBComponentLayoutChild>>)children
supercomponent:(FBComponent *)supercomponent
{
  const auto result = [super mountInContext:context size:size children:children supercomponent:supercomponent];
  FBInjectingView *injectingView = (FBInjectingView *)result.contextForChildren.viewManager->view;
  return {
    .mountChildren = YES,
    .contextForChildren = result.contextForChildren.childContextForSubview(injectingView.injectedView),
  };
}

@end

@implementation FBReuseAwareView
@end
