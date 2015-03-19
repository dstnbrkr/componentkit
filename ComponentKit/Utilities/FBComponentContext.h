// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentContextImpl.h>

/**
 Provides a way to implicitly pass parameters to child components.

 @warning Contexts should be used sparingly. Prefer explicitly passing parameters instead.
 */
template<typename T>
class FBComponentContext {
public:
  /**
   Puts an object in the context dictionary. Objects are currently keyed by class, meaning you cannot store multiple
   objects of the same class.

   @example FBComponentContext<FBFoo> fooContext(foo);
   */
  FBComponentContext(T *object) : _key([T class])
  {
    FB::Component::Context::store(_key, object);
  }

  /**
   Fetches an object from the context dictionary.

   You may only call this from inside +new. If you want access to something from context later, store it in an ivar.

   @example FBFoo *foo = FBComponentContext<FBFoo>::get();
   */
  static T *get()
  {
    return FB::Component::Context::fetch([T class]);
  }

  FBComponentContext(const FBComponentContext&) = delete;
  FBComponentContext &operator=(const FBComponentContext&) = delete;
  ~FBComponentContext()
  {
    FB::Component::Context::clear(_key);
  }

private:
  const Class _key;
};
