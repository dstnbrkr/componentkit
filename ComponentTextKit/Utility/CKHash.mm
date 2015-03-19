// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKHash.h"

NSUInteger CKLongHash(unsigned long long p)
{
  p = (~p) + (p << 18);           // key = (key << 18) - key - 1;
  p ^= (p >> 31);
  p *=  21;                       // key = (key + (key << 2)) + (key << 4);
  p ^= (p >> 11);
  p += (p << 6);
  p ^= (p >> 22);
  return (NSUInteger) p;
}

//
// Thomas Wang 32/64 bit mix hash
// http://www.concentric.net/~Ttwang/tech/inthash.htm
//
NSUInteger CKPointerHash(const void *p)
{
  NSUInteger h = (NSUInteger)p;
#if !TARGET_RT_64_BIT
  h = ~h + (h << 15);             // key = (key << 15) - key - 1;
  h ^= (h >> 12);
  h += (h << 2);
  h ^= (h >> 4);
  h *= 2057;                      // key = (key + (key << 3)) + (key << 11);
  h ^= (h >> 16);
#else
  h += ~h + (h << 21);            // key = (key << 21) - key - 1;
  h ^= (h >> 24);
  h = (h + (h << 3)) + (h << 8);
  h ^= (h >> 14);
  h = (h + (h << 2)) + (h << 4);  // key * 21
  h ^= (h >> 28);
  h += (h << 31);
#endif
  return h;
}

NSUInteger CKIntegerHash(NSUInteger p)
{
  return CKPointerHash((void *)p);
}

NSUInteger CKFloatHash(float f)
{
  static_assert(sizeof (float) == sizeof (uint32_t), "Size of float must be 4 bytes");
  union {
    float key;
    uint32_t bits;
  } u;
  u.key = f;
  return CKIntegerHash(u.bits);
}

NSUInteger CKDoubleHash(double d)
{
  static_assert(sizeof (double) == sizeof (uint64_t), "Size of double must be 8 bytes");
  union {
    double key;
    uint64_t bits;
  } u;
  u.key = d;
  return CKLongHash(u.bits);
}

NSUInteger CKCGFloatHash(CGFloat f)
{
#if CGFLOAT_IS_DOUBLE
  return CKDoubleHash(f);
#else
  return CKFloatHash(f);
#endif
}

NSUInteger CKCStringHash(const char *s)
{
  // FNV-1a hash.
  NSUInteger hash = sizeof(NSUInteger) == 4 ? 2166136261U : 14695981039346656037U;
  while (*s) {
    hash ^= *s++;
    hash *= sizeof(NSUInteger) == 4 ? 16777619 : 1099511628211;
  }
  return hash;
}

NSUInteger CKIntegerPairHash(NSUInteger a, NSUInteger b)
{
  return CKLongHash((((unsigned long long)a) << 32 | b));
}

NSUInteger CKIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)
{
  NSUInteger result = subhashes[0];
  for (int ii = 1; ii < count; ++ii) {
    result = CKIntegerPairHash(result, subhashes[ii]);
  }

  return result;
}
