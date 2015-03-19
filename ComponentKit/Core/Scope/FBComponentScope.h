// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

@class FBComponentScopeFrame;

/**
 Components have local "state" that is independent of the values passed into its +new method. Components can update
 their state independently by calling the [FBComponent -updateState:] method.

 While a component is constructing itself in +new, it needs access to its state; FBComponentScope provides it.
 To use it, create a scope at the top of +new that matches the component's class. For example:

   + (id)initialState
   {
     return [MyState new];
   }

   + (instancetype)newWithModel:(Model *)model
   {
     FBComponentScope scope(self);
     MyState *state = scope.state();
     // ... use the values in state
     return [super newWithComponent:...];
   }
 */
class FBComponentScope {
public:
  /**
   @param componentClass      Always pass self.
   @param identifier          If there are multiple sibling components of the same class, you must provide an identifier
                              to distinguish them. For example, imagine four photo components that are rendered next to
                              each other; the photo's ID could serve as the identifier to distinguish them.
   @param initialStateCreator By default, the +initialState method will be invoked on the component class to get the
                              initial state. You can optionally pass a block that captures local variables, but see here
                              for why this is usually a bad idea:
                              http://facebook.github.io/react/tips/props-in-getInitialState-as-anti-pattern.html
   */
  FBComponentScope(Class __unsafe_unretained componentClass, id identifier = nil, id (^initialStateCreator)(void) = nil);

  ~FBComponentScope();

  /** @return The current state for the component being built. */
  id state() const;

private:
  FBComponentScope(const FBComponentScope&) = delete;
  FBComponentScope &operator=(const FBComponentScope&) = delete;
  FBComponentScopeFrame *_scopeFrame;
};
