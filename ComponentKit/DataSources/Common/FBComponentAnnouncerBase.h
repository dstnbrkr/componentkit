// Copyright 2004-present Facebook. All Rights Reserved.

#import <objc/message.h>
#import <vector>

#import <Foundation/Foundation.h>

@interface FBComponentAnnouncerBase : NSObject
{
@public
  // we make this public, so it can be accessed from FB::AnnouncerHelper
  // it's ok, since this include should only be included in the codegen files
  // and others won't have this visibility

  // shared pointer (reference counted) of a vector listeners
  // we need it to be a shared pointer, since we want to be
  // able atomically grab it for enumeration, even if someone
  // else is modifying it in a different thread at the same time
  // We use a vector instead of a hash mainly for 2 reasons:
  //  1) dealing with __weak id as a key in a hash is more complicated
  //  2) we assume that the number of listeners is relatively small, and
  //     add/remove is not a frequent event.
  // n.b. using boost::shared_ptr might lead to faster code, since it's lockless
  std::shared_ptr<const std::vector<__weak id>> _listenerVector;
}
@end

namespace FB {
  namespace Component {
    // The implementation of FBAnnouncer, so codegen doesn't have to generate the actual logic.
    struct AnnouncerHelper
    {
    private:
      // function to load the current listeners vector in a thread safe way
      static std::shared_ptr<const std::vector<__weak id>> loadListeners(FBComponentAnnouncerBase *self);
    public:
      // called by codegen for required protocol methods
      template<typename... ARGS>
      static void call(FBComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;

        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          for (id listener : *frozenListeners) {
            objc_msgSendTyped(listener, s, args...);
          }
        }
      }

      // called by codegen for optional protocol methods
      template<typename... ARGS>
      static void callOptional(FBComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;

        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          for (id listener : *frozenListeners) {
            if ([listener respondsToSelector:s]) {
              objc_msgSendTyped(listener, s, args...);
            }
          }
        }
      }

      // called by codegen to add listeners
      static void addListener(FBComponentAnnouncerBase *self, SEL s, id listener);

      // called by codegen to remove listeners
      static void removeListener(FBComponentAnnouncerBase *self, SEL s, id listener);
    };
  }
}
