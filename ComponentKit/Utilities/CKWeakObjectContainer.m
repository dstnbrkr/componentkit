// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKWeakObjectContainer.h"

#import <objc/runtime.h>

@interface CKWeakObjectContainer : NSObject
@property (nonatomic, weak) id object;
@end

@implementation CKWeakObjectContainer
@end

void ck_objc_setNonatomicAssociatedWeakObject(id container, void *key, id value)
{
  CKWeakObjectContainer *wrapper = [CKWeakObjectContainer new];
  wrapper.object = value;
  objc_setAssociatedObject(container, key, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void ck_objc_setAssociatedWeakObject(id container, void *key, id value)
{
  CKWeakObjectContainer *wrapper = [CKWeakObjectContainer new];
  wrapper.object = value;
  objc_setAssociatedObject(container, key, wrapper, OBJC_ASSOCIATION_RETAIN);
}

id ck_objc_getAssociatedWeakObject(id container, void *key)
{
  return [(CKWeakObjectContainer*) objc_getAssociatedObject(container, key) object];
}
