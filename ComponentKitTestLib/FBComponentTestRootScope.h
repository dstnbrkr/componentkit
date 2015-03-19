// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBThreadLocalComponentScope.h>

/**
 If you are constructing components manually in a test without using FBComponentLifecycleManager, you must wrap their
 creation in FBComponentTestRootScope. For example:

   FBComponentTestRootScope scope;
   FBComponent *c = ...;
 */
class FBComponentTestRootScope {
public:
  FBComponentTestRootScope() : _threadScope(nil, nullptr) {};
private:
  FBThreadLocalComponentScope _threadScope;
};
