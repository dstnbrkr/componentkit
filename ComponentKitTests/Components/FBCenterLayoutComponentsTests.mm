// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

#import "FBBackgroundLayoutComponent.h"
#import "FBCenterLayoutComponent.h"
#import "FBStackLayoutComponent.h"

static const FBSizeRange kSize = {{100, 120}, {320, 160}};

@interface FBCenterLayoutComponentsTests : FBComponentSnapshotTestCase

@end

@implementation FBCenterLayoutComponentsTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testWithOptions
{
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringNone sizingOptions:{}];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringXY sizingOptions:{}];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringX sizingOptions:{}];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringY sizingOptions:{}];
}

- (void)testWithSizingOptions
{
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringNone sizingOptions:FBCenterLayoutComponentSizingOptionDefault];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringNone sizingOptions:FBCenterLayoutComponentSizingOptionMinimumX];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringNone sizingOptions:FBCenterLayoutComponentSizingOptionMinimumY];
  [self testWithCenteringOptions:FBCenterLayoutComponentCenteringNone sizingOptions:FBCenterLayoutComponentSizingOptionMinimumXY];
}

- (void)testWithCenteringOptions:(FBCenterLayoutComponentCenteringOptions)options
                   sizingOptions:(FBCenterLayoutComponentSizingOptions)sizingOptions
{
  FBComponent *c = [FBBackgroundLayoutComponent
                    newWithComponent:
                    [FBCenterLayoutComponent
                     newWithCenteringOptions:options
                     sizingOptions:sizingOptions
                     child:[FBComponent
                            newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor greenColor]}}}
                            size:{70.0, 100.0}]
                     size:{}]
                    background:
                    [FBComponent
                     newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
                     size:{}]];

  FBSnapshotVerifyComponent(c, kSize, suffixForCenteringOptions(options, sizingOptions));
}

static NSString *suffixForCenteringOptions(FBCenterLayoutComponentCenteringOptions centeringOptions,
                                           FBCenterLayoutComponentSizingOptions sizingOptinos)
{
  NSMutableString *suffix = [NSMutableString string];

  if ((centeringOptions & FBCenterLayoutComponentCenteringX) != 0) {
    [suffix appendString:@"CenteringX"];
  }

  if ((centeringOptions & FBCenterLayoutComponentCenteringY) != 0) {
    [suffix appendString:@"CenteringY"];
  }

  if ((sizingOptinos & FBCenterLayoutComponentSizingOptionMinimumX) != 0) {
    [suffix appendString:@"SizingMinimumX"];
  }

  if ((sizingOptinos & FBCenterLayoutComponentSizingOptionMinimumY) != 0) {
    [suffix appendString:@"SizingMinimumY"];
  }

  return suffix;
}

- (void)testMinimumSizeRangeIsGivenToChildWhenNotCentering
{
  FBCenterLayoutComponent *c =
  [FBCenterLayoutComponent
   newWithCenteringOptions:FBCenterLayoutComponentCenteringNone
   sizingOptions:{}
   child:
   [FBBackgroundLayoutComponent
    newWithComponent:
    [FBStackLayoutComponent
     newWithView:{}
     size:{}
     style:{}
     children:{
       {
         [FBComponent
          newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
          size:{10,10}],
         .flexGrow = YES,
       }
     }]
    background:
    [FBComponent
     newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}}}
     size:{}]]
   size:{}];
  FBSnapshotVerifyComponent(c, kSize, nil);
}

@end
