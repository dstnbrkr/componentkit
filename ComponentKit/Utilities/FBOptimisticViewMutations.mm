// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBOptimisticViewMutations.h"

#import <objc/runtime.h>

#import <FBComponentKit/CKAssert.h>

const char kOptimisticViewMutationOriginalValuesAssociatedObjectKey = ' ';

void FBPerformOptimisticViewMutation(UIView *view, NSString *keyPath, id value)
{
  CKCAssertMainThread();
  CKCAssertNotNil(view, @"Must have a non-nil view");
  CKCAssertNotNil(keyPath, @"Must have a non-nil keyPath");

  NSMutableDictionary *originalValues = objc_getAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey);
  if (originalValues == nil) {
    originalValues = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey, originalValues, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  if (originalValues[keyPath] == nil) {
    // First mutation for this keypath; store the old value.
    originalValues[keyPath] = [view valueForKeyPath:keyPath] ?: [NSNull null];
  }

  [view setValue:value forKeyPath:keyPath];
}

void FBResetOptimisticMutationsForView(UIView *view)
{
  NSDictionary *originalValues = objc_getAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey);
  if (originalValues) {
    for (NSString *keyPath in originalValues) {
      id value = originalValues[keyPath];
      [view setValue:(value == [NSNull null] ? nil : value) forKeyPath:keyPath];
    }
    objc_setAssociatedObject(view, &kOptimisticViewMutationOriginalValuesAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}
