// Copyright 2004-present Facebook. All Rights Reserved.

#import <utility>
#import <vector>

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKAssert.h>

@class FBComponent;

struct FBComponentLayoutChild;

/** Deletes the target off the main thread; important since component layouts are large recursive structures. */
struct FBOffMainThreadDeleter {
  void operator()(std::vector<FBComponentLayoutChild> *target);
};

/** Represents the computed size of a component, as well as the computed sizes and positions of its children. */
struct FBComponentLayout {
  FBComponent *component;
  CGSize size;
  std::shared_ptr<const std::vector<FBComponentLayoutChild>> children;

  FBComponentLayout(FBComponent *c, CGSize s, std::vector<FBComponentLayoutChild> ch = {})
  : component(c), size(s), children(new std::vector<FBComponentLayoutChild>(std::move(ch)), FBOffMainThreadDeleter()) {
    CKCAssertNotNil(c, @"Nil components are not allowed");
  };

  FBComponentLayout()
  : component(nil), size({0, 0}), children(new std::vector<FBComponentLayoutChild>(), FBOffMainThreadDeleter()) {};
};

struct FBComponentLayoutChild {
  CGPoint position;
  FBComponentLayout layout;
};

/** @returns YES if any child (including recursive children) overflows the component layout. */
BOOL FBComponentLayoutHasOverflow(const FBComponentLayout &layout);

/** Recursively mounts the layout in the view, returning a set of the mounted components. */
NSSet *FBMountComponentLayout(const FBComponentLayout &layout, UIView *view, FBComponent *supercomponent = nil);
