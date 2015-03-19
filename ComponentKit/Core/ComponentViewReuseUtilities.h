// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <UIKit/UIKit.h>

class FBComponentViewClass;

namespace FB {
  namespace Component {
    class ViewReuseUtilities {
    public:
      /** Called when Components will begin mounting in a root view */
      static void mountingInRootView(UIView *rootView);
      /** Called when Components creates a view */
      static void createdView(UIView *view, const FBComponentViewClass &viewClass, UIView *parent);
      /** Called when Components will begin mounting child components in a new child view */
      static void mountingInChildContext(UIView *view, UIView *parent);

      /** Called when Components is about to hide a Components-managed view */
      static void didHide(UIView *view);
      /** Called when Components is about to unhide a Components-managed view */
      static void willUnhide(UIView *view);
    };
  }
}
