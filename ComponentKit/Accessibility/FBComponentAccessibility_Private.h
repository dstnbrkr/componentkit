// Copyright 2004-present Facebook. All Rights Reserved.

namespace FB {
  namespace Component {
    namespace Accessibility {

      /**
       Force enable or disable accessibility.
       @param enabled A Boolean value that determines whether accessibility is enabled.
       @discussion Used for testing. All current unit tests at the date of adding this where written under the
       assumption that accessibility is not enabled. When setting to YES remember to set to NO on teardown.
       */
      void SetForceAccessibilityEnabled(BOOL enabled);
    }
  }
}
