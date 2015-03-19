// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import "FBComponentContext.h"

@interface FBComponentContextTests : XCTestCase
@end

@implementation FBComponentContextTests

- (void)testEstablishingAComponentContextAllowsYouToFetchIt
{
  NSObject *o = [[NSObject alloc] init];
  FBComponentContext<NSObject> context(o);

  NSObject *o2 = FBComponentContext<NSObject>::get();
  XCTAssertTrue(o == o2);
}

- (void)testFetchingAnObjectThatHasNotBeenEstablishedWithGetReturnsNil
{
  XCTAssertNil(FBComponentContext<NSObject>::get(), @"Expected to return nil without throwing");
}

static void openContextWithNSObject()
{
  NSObject *o = [[NSObject alloc] init];
  FBComponentContext<NSObject> context(o);
}

- (void)testAttemptingToEstablishComponentContextWithDuplicateClassThrows
{
  NSObject *o = [[NSObject alloc] init];
  FBComponentContext<NSObject> context(o);

  XCTAssertThrows(openContextWithNSObject(), @"Expected opening another context with NSObject to throw");
}

- (void)testComponentContextCleansUpWhenItGoesOutOfScope
{
  {
    NSObject *o = [[NSObject alloc] init];
    FBComponentContext<NSObject> context(o);
  }
  XCTAssertNil(FBComponentContext<NSObject>::get(), @"Expected getting NSObject to return nil as its scope is closed");
}

@end
