// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FBComponent.h"
#import "FBComponentGestureActions.h"
#import "FBComponentGestureActionsInternal.h"
#import "FBComponentViewInterface.h"

@interface FBFakeActionComponent : FBComponent
- (void)test:(FBComponent *)sender;
@property (nonatomic, assign) BOOL receivedTest;
@end

@interface FBComponentGestureActionsTests : XCTestCase
@end

@implementation FBComponentGestureActionsTests

- (void)testThatApplyingATapRecognizerAttributeAddsRecognizerToViewAndUnApplyingItRemovesIt
{
  FBComponentViewAttributeValue attr = FBComponentTapGestureAttribute(@selector(test));
  UIView *view = [[UIView alloc] init];

  attr.first.applicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 1u, @"Expected tap gesture recognizer to be attached");

  attr.first.unapplicator(view, attr.second);
  XCTAssertEqual([view.gestureRecognizers count], 0u, @"Expected tap gesture recognizer to be removed");
}

- (void)testThatTapRecognizerHasComponentActionStoredOnIt
{
  FBComponentViewAttributeValue attr = FBComponentTapGestureAttribute(@selector(test));
  UIView *view = [[UIView alloc] init];

  attr.first.applicator(view, attr.second);
  UITapGestureRecognizer *recognizer = [view.gestureRecognizers firstObject];
  XCTAssertEqual([recognizer fb_componentAction], @selector(test), @"Expected fb_componentAction to be set on the GR");

  attr.first.unapplicator(view, attr.second);
}

- (void)testThatTappingAViewSendsComponentAction
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  id mockComponent = [OCMockObject mockForClass:[FBComponent class]];
  FBFakeActionComponent *fakeParentComponent = [FBFakeActionComponent new];
  [[[mockComponent stub] andReturn:fakeParentComponent] nextResponder];
  [[[mockComponent stub] andReturn:fakeParentComponent] targetForAction:[OCMArg anySelector] withSender:[OCMArg any]];
  view.fb_component = mockComponent;

  FBComponentViewAttributeValue attr = FBComponentTapGestureAttribute(@selector(test:));
  attr.first.applicator(view, attr.second);

  // Simulating touches is a PITA, but we can hack it by accessing the FBComponentGestureActionForwarder directly.
  UIGestureRecognizer *tapRecognizer = [view.gestureRecognizers firstObject];
  [[FBComponentGestureActionForwarder sharedInstance] handleGesture:tapRecognizer];
  XCTAssertTrue([fakeParentComponent receivedTest], @"Expected handler to be called");
}

@end

@implementation FBFakeActionComponent
- (void)test:(FBComponent *)sender
{
  _receivedTest = YES;
}
@end
