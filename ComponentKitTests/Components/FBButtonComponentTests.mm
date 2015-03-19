// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKitTestLib/FBComponentSnapshotTestCase.h>

#import "FBButtonComponent.h"

@interface FBButtonComponentTests : FBComponentSnapshotTestCase
@end

@implementation FBButtonComponentTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

static UIImage *fakeImage()
{
  static UIImage *fakeImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    CGSize size = { 17, 17 };
    size_t bytesPerRow = ((((size_t)size.width * 4)+31)&~0x1f);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ref = CGBitmapContextCreate(NULL, size.width, size.height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);

    CGContextSetAllowsAntialiasing(ref, YES);
    CGContextSetInterpolationQuality(ref, kCGInterpolationHigh);
    CGContextSetFillColorWithColor(ref, [[UIColor redColor] CGColor]);
    CGContextFillRect(ref, {{0,0}, {17, 17}});
    CGImageRef im = CGBitmapContextCreateImage(ref);
    CGContextRelease(ref);
    fakeImage = [UIImage imageWithCGImage:im scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(im);
  });
  return fakeImage;
}

- (void)testButtonWithTitle
{
  FBButtonComponent *b = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  FBSizeRange size;
  FBSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithImage
{
  FBButtonComponent *b = [FBButtonComponent newWithTitles:{}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  FBSizeRange size;
  FBSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImage
{
  FBButtonComponent *b = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{}
                               accessibilityConfiguration:{}];
  FBSizeRange size;
  FBSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonWithTitleAndImageAndContentEdgeInsets
{
  NSValue *insets = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
  FBButtonComponent *b = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello World"}}
                                              titleColors:{}
                                                   images:{{UIControlStateNormal, fakeImage()}}
                                         backgroundImages:{}
                                                titleFont:nil
                                                 selected:NO
                                                  enabled:YES
                                                   action:{}
                                                     size:{}
                                               attributes:{{@selector(setContentEdgeInsets:), insets}}
                               accessibilityConfiguration:{}];
  FBSizeRange size;
  FBSnapshotVerifyComponent(b, size, nil);
}

- (void)testButtonStates
{
  std::unordered_map<UIControlState, UIColor *> titleColors = {
    {UIControlStateNormal, [UIColor blackColor]},
    {UIControlStateHighlighted, [UIColor redColor]},
    {UIControlStateSelected, [UIColor blueColor]},
    {UIControlStateDisabled, [UIColor greenColor]},
    {UIControlStateDisabled|UIControlStateSelected, [UIColor yellowColor]},
    {UIControlStateSelected|UIControlStateHighlighted, [UIColor orangeColor]},
  };
  FBSizeRange size;

  FBButtonComponent *normal = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                   titleColors:titleColors
                                                        images:{}
                                              backgroundImages:{}
                                                     titleFont:nil
                                                      selected:NO
                                                       enabled:YES
                                                        action:{}
                                                          size:{}
                                                    attributes:{}
                                    accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(normal, size, @"normal");

  FBButtonComponent *hi = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                               titleColors:titleColors
                                                    images:{}
                                          backgroundImages:{}
                                                 titleFont:nil
                                                  selected:NO
                                                   enabled:YES
                                                    action:{}
                                                      size:{}
                                                attributes:{{@selector(setHighlighted:), @YES}}
                                accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(hi, size, @"highlighted");

  FBButtonComponent *sel = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                titleColors:titleColors
                                                     images:{}
                                           backgroundImages:{}
                                                  titleFont:nil
                                                   selected:YES
                                                    enabled:YES
                                                     action:{}
                                                       size:{}
                                                 attributes:{}
                                 accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(sel, size, @"selected");

  FBButtonComponent *dis = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                titleColors:titleColors
                                                     images:{}
                                           backgroundImages:{}
                                                  titleFont:nil
                                                   selected:NO
                                                    enabled:NO
                                                     action:{}
                                                       size:{}
                                                 attributes:{}
                                 accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(dis, size, @"disabled");

  FBButtonComponent *dissel = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                   titleColors:titleColors
                                                        images:{}
                                              backgroundImages:{}
                                                     titleFont:nil
                                                      selected:YES
                                                       enabled:NO
                                                        action:{}
                                                          size:{}
                                                    attributes:{}
                                    accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(dissel, size, @"disabled_selected");

  FBButtonComponent *selhi = [FBButtonComponent newWithTitles:{{UIControlStateNormal, @"Hello"}}
                                                  titleColors:titleColors
                                                       images:{}
                                             backgroundImages:{}
                                                    titleFont:nil
                                                     selected:YES
                                                      enabled:YES
                                                       action:{}
                                                         size:{}
                                                   attributes:{{@selector(setHighlighted:), @YES}}
                                   accessibilityConfiguration:{}];
  FBSnapshotVerifyComponent(selhi, size, @"selected_highlighted");
}

@end
