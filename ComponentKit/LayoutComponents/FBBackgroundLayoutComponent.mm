// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBBackgroundLayoutComponent.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "FBComponentSubclass.h"

@interface FBBackgroundLayoutComponent ()
{
  FBComponent *_component;
  FBComponent *_background;
}
@end

@implementation FBBackgroundLayoutComponent

+ (instancetype)newWithComponent:(FBComponent *)component
                      background:(FBComponent *)background
{
  if (component == nil) {
    return nil;
  }
  FBBackgroundLayoutComponent *c = [super newWithView:{} size:{}];
  c->_component = component;
  c->_background = background;
  return c;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view size:(const FBComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

/**
 First layout the contents, then fit the background image.
 */
- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
                          restrictedToSize:(const FBComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == FBComponentSize(),
           @"FBBackgroundLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, background=%@)", size.description(), _component, _background);

  const FBComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];

  std::vector<FBComponentLayoutChild> children;
  if (_background) {
    // Size background to exactly the same size.
    children.push_back({{0,0}, [_background layoutThatFits:{contentsLayout.size, contentsLayout.size}
                                                parentSize:contentsLayout.size]});
  }
  children.push_back({{0,0}, contentsLayout});

  return {self, contentsLayout.size, children};
}

@end
