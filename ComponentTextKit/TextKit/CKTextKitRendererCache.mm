// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKTextKitRendererCache.h>

namespace CK {
  namespace TextKit {
    void lowMemoryNotificationHandler(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
      // Compaction is a relatively cheap operation and it's important that we get it done ASAP, so use the high-pri queue.
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        (static_cast<ApplicationObserver *>(observer))->onLowMemory();
      });
    }
    void enteredBackgroundNotificationHandler(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
      (static_cast<ApplicationObserver *>(observer))->onEnterBackground();
    }
  }
}
