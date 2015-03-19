// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBOverlayLayoutComponent.h"

#import <FBComponentKit/CKAssert.h>
#import <FBComponentKit/CKMacros.h>

#import "FBComponentSubclass.h"

@implementation FBOverlayLayoutComponent
{
  FBComponent *_overlay;
  FBComponent *_component;
}

+ (instancetype)newWithComponent:(FBComponent *)component
                         overlay:(FBComponent *)overlay
{
  FBOverlayLayoutComponent *c = [super newWithView:{} size:{}];
  if (c) {
    CKAssertNotNil(component, @"Component that will be overlayed on shouldn't be nil");
    c->_overlay = overlay;
    c->_component = component;
  }
  return c;
}

+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view size:(const FBComponentSize &)size
{
  CK_NOT_DESIGNATED_INITIALIZER();
}

/**
 First layout the contents, then fit the overlay on top of it.
 */
- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
                          restrictedToSize:(const FBComponentSize &)size
                      relativeToParentSize:(CGSize)parentSize
{
  CKAssert(size == FBComponentSize(),
           @"FBOverlayLayoutComponent only passes size {} to the super class initializer, but received size %@ "
           "(component=%@, overlay=%@)", size.description(), _component, _overlay);

  FBComponentLayout contentsLayout = [_component layoutThatFits:constrainedSize parentSize:parentSize];
  return {
    self,
    contentsLayout.size,
    _overlay ? std::vector<FBComponentLayoutChild> {
      {{0,0}, contentsLayout},
      {{0,0}, [_overlay layoutThatFits:{contentsLayout.size, contentsLayout.size} parentSize:contentsLayout.size]}
    } : std::vector<FBComponentLayoutChild> {
      {{0,0}, contentsLayout},
    }
  };
}

@end
