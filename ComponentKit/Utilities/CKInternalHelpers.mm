// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKInternalHelpers.h"

#import <objc/runtime.h>
#import <stdio.h>
#import <string>

BOOL CKSubclassOverridesSelector(Class superclass, Class subclass, SEL selector)
{
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  IMP superclassIMP = superclassMethod ? method_getImplementation(superclassMethod) : NULL;
  IMP subclassIMP = subclassMethod ? method_getImplementation(subclassMethod) : NULL;
  return (superclassIMP != subclassIMP);
}

std::string CKStringFromPointer(const void *ptr)
{
  char buf[64];
  snprintf(buf, sizeof(buf), "%p", ptr);
  return buf;
}

CGFloat CKScreenScale()
{
  static CGFloat _scale;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _scale = [UIScreen mainScreen].scale;
  });
  return _scale;
}

CGFloat CKFloorPixelValue(CGFloat f)
{
  return floorf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKCeilPixelValue(CGFloat f)
{
  return ceilf(f * CKScreenScale()) / CKScreenScale();
}

CGFloat CKRoundPixelValue(CGFloat f)
{
  return roundf(f * CKScreenScale()) / CKScreenScale();
}
