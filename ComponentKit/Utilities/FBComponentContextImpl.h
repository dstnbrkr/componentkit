// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/CKAssert.h>

namespace FB {
  namespace Component {
    namespace Context {
      inline NSString *threadDictionaryKey()
      {
        return @"FBComponentContext";
      }

      inline NSMutableDictionary *contextDictionary(BOOL create)
      {
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSMutableDictionary *contextDictionary = [threadDictionary objectForKey:threadDictionaryKey()];
        if (contextDictionary == nil && create) {
          contextDictionary = [NSMutableDictionary dictionary];
          [threadDictionary setObject:contextDictionary forKey:threadDictionaryKey()];
        }
        return contextDictionary;
      }

      inline void store(id key, id object)
      {
        CKCAssertNotNil(object, @"Cannot store nil objects");
        NSMutableDictionary *c = contextDictionary(YES);
        CKCAssertNil(c[key], @"Cannot store %@ = %@ as %@ already exists", key, object, c[key]);
        c[key] = object;
      }

      inline void clear(id key)
      {
        NSMutableDictionary *c = contextDictionary(NO);
        CKCAssertNotNil(c[key], @"Who removed %@ behind our back?", key);
        [c removeObjectForKey:key];
        if ([c count] == 0) {
          [[[NSThread currentThread] threadDictionary] removeObjectForKey:threadDictionaryKey()];
        }
      }

      inline id fetch(id key)
      {
        return contextDictionary(NO)[key];
      }
    };
  }
}
