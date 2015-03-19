// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

/* generic functors */

namespace CK {
  
  template<class T>
  struct DescribeFunctor {
    NSString *operator()(const T &t) const {
      return [NSString stringWithFormat:@"%d", static_cast<int>(t)];
    }
  };
  
  template<class T>
  struct HashFunctor {
    size_t operator()(const T &key) const {
      return (size_t)(key);
    }
  };
  
  template<class T>
  struct EqualFunctor {
    bool operator()(const T &left, const T&right) const {
      return left == right;
    }
  };
  
  template<class T>
  struct CompareFunctor {
    bool operator()(const T &left, const T &right) const {
      return (int)left < (int)right;
    };
  };
  
  template<class T>
  struct RoundToIntegerFunctor {
    T operator()(const T &t) const {
      return t;
    }
  };

  template<class T>
  struct RoundToSubFunctor {
    T operator()(const T &t, float sub) const {
      return t;
    }
  };

}
