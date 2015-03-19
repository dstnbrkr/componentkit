// Copyright 2004-present Facebook. All Rights Reserved.

#import <string>

#import <UIKit/UIKit.h>

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector);

std::string CKStringFromPointer(const void *ptr);

CGFloat CKScreenScale();

CGFloat CKFloorPixelValue(CGFloat f);

CGFloat CKCeilPixelValue(CGFloat f);

CGFloat CKRoundPixelValue(CGFloat f);
