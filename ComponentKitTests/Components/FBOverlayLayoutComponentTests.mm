// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

#import "FBOverlayLayoutComponent.h"

static const FBSizeRange kSize = {{0,0}, {320, 320}};

@interface FBOverlayTestView : UIView

@end

@interface FBOverlayLayoutComponentTests : FBComponentSnapshotTestCase

@end

@implementation FBOverlayLayoutComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testOverlay
{
  FBComponent *c = [FBOverlayLayoutComponent
                    newWithComponent:[FBComponent newWithView:{[UIView class], {{@selector(setBackgroundColor:), [UIColor blueColor]}}} size:{}]
                    overlay:[FBComponent newWithView:{[FBOverlayTestView class], {{@selector(setBackgroundColor:), [UIColor colorWithWhite:1.0 alpha:0.6]}}} size:{}]];

  FBSnapshotVerifyComponent(c, kSize, nil);
}

@end

@implementation FBOverlayTestView

- (id)initWithFrame:(CGRect)aRect
{
  self = [super initWithFrame:aRect];
  if (self) {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20.0, 20.0)];
    v.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [v setBackgroundColor:[UIColor blackColor]];
    v.center = CGPointMake(aRect.size.width/2.0, aRect.size.height/2.0);
    [self addSubview:v];
  }
  return self;
}

@end
