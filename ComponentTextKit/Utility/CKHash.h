// Copyright 2004-present Facebook. All Rights Reserved.

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

extern NSUInteger CKPointerHash(const void *p);

extern NSUInteger CKIntegerHash(NSUInteger p);

extern NSUInteger CKFloatHash(float f);

extern NSUInteger CKDoubleHash(double d);

extern NSUInteger CKCGFloatHash(CGFloat f);

extern NSUInteger CKCStringHash(const char *s);

extern NSUInteger CKLongHash(unsigned long long p);

extern NSUInteger CKIntegerPairHash(NSUInteger a, NSUInteger b);

extern NSUInteger CKIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count);

#ifdef __cplusplus
}
#endif
