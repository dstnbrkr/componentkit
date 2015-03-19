// Copyright 2004-present Facebook. All Rights Reserved.

#ifdef __cplusplus
extern "C" {
#endif

extern void ck_objc_setNonatomicAssociatedWeakObject(id container, void *key, id value);
extern void ck_objc_setAssociatedWeakObject(id container, void *key, id value);
extern id ck_objc_getAssociatedWeakObject(id container, void *key);

#ifdef __cplusplus
}
#endif
