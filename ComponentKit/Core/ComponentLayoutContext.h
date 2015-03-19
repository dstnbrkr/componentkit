// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBDimension.h>

namespace FB {
  namespace Component {
    class LayoutContext;

    /** A stack of layout contexts. */
    typedef std::vector<LayoutContext *> LayoutContextStack;

    /**
     Keeps track of the stack of components performing layout.

     In almost all cases, this should be purely internal to the infrastructure; it is used for debug purposes when we
     encounter an invalid layout (e.g. resolving a percentage against an undefined size).
     */
    struct LayoutContext {
      /**
       Constructing this class pushes the given component (and its size range) onto the layout stack.
       */
      LayoutContext(FBComponent *c, FBSizeRange sizeRange);
      /**
       Pops the component passed in the constructor from the layout stack. It is an error if the component is not on the
       top of the stack.
       */
      ~LayoutContext();

      /** The component that is in the process of laying out. */
      FBComponent *const component;

      /** The size range passed to the component. */
      const FBSizeRange sizeRange;

      /**
       Returns a reference to the current stack of components performing layout.

       @warning Both the reference to the stack and the pointers within the stack MUST NOT be stored or used later!
       */
      static const LayoutContextStack &currentStack();

      /**
       Returns a string with the contents of the current stack, with each component on one line indented by level.
       Only the class name of each component is printed.
       */
      static NSString *currentStackDescription();

      LayoutContext(const LayoutContext&) = delete;
      LayoutContext &operator=(const LayoutContext&) = delete;
    };
  }
}
