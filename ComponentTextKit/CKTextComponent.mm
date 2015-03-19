// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTextComponent.h"

#import <memory>
#import <vector>

#import <FBComponentKit/FBComponentInternal.h>

#import <FBComponentKit/CKTextKitRenderer.h>
#import <FBComponentKit/CKTextKitRendererCache.h>

#import <FBComponentKit/CKInternalHelpers.h>

#import "CKTextComponentView.h"

static CK::TextKit::Renderer::Cache *sharedRendererCache()
{
  // This cache is sized arbitrarily
  static CK::TextKit::Renderer::Cache *__rendererCache (new CK::TextKit::Renderer::Cache("CKTextComponentRendererCache", 500, 0.2));
  return __rendererCache;
}

/**
 The concept here is that neither the component nor layout should ever have a strong reference to the renderer object.
 This is to reduce memory load when loading thousands and thousands of text components into memory at once.  Instead
 we maintain a LRU renderer cache that is queried via stack-allocated keys.
 */
static CKTextKitRenderer *rendererForAttributes(CKTextKitAttributes &attributes, CGSize constrainedSize)
{
  CK::TextKit::Renderer::Cache *cache = sharedRendererCache();
  const CK::TextKit::Renderer::Key key {
    attributes,
    constrainedSize
  };

  CKTextKitRenderer *renderer = cache->objectForKey(key);

  if (!renderer) {
    renderer =
    [[CKTextKitRenderer alloc]
     initWithTextKitAttributes:attributes
     constrainedSize:constrainedSize];
    cache->cacheObject(key, renderer, 1);
  }

  return renderer;
}

@implementation CKTextComponent
{
  CKTextKitAttributes _attributes;
  CKTextComponentAccessibilityContext _accessibilityContext;
}

+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const FBViewComponentAttributeValueMap &)viewAttributes
                 accessibilityContext:(const CKTextComponentAccessibilityContext &)accessibilityContext
{
  CKTextKitAttributes copyAttributes = attributes.copy();
  FBViewComponentAttributeValueMap copiedMap = viewAttributes;
  CKTextComponent *c = [super newWithView:{
    [CKTextComponentView class],
    std::move(copiedMap),
    {
      .isAccessibilityElement = accessibilityContext.isAccessibilityElement,
      .accessibilityIdentifier = accessibilityContext.accessibilityIdentifier,
      .accessibilityLabel = accessibilityContext.accessibilityLabel.hasText()
      ? accessibilityContext.accessibilityLabel : ^{ return copyAttributes.attributedString.string; }
    }
  } size:{}];
  if (c) {
    c->_attributes = copyAttributes;
    c->_accessibilityContext = accessibilityContext;
  }
  return c;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  const CKTextKitRenderer *renderer = rendererForAttributes(_attributes, constrainedSize.max);
  return {
    self,
    constrainedSize.clamp({
      CKCeilPixelValue(renderer.size.width),
      CKCeilPixelValue(renderer.size.height)
    }),
    {}
  };
}

- (FB::Component::MountResult)mountInContext:(const FB::Component::MountContext &)context
                                        size:(const CGSize)size
                                    children:(std::shared_ptr<const std::vector<FBComponentLayoutChild>>)children
                              supercomponent:(FBComponent *)supercomponent
{
  FB::Component::MountResult result = [super mountInContext:context
                                                       size:size
                                                   children:children
                                             supercomponent:supercomponent];
  CKTextComponentView *view = (CKTextComponentView *)result.contextForChildren.viewManager->view;
  CKTextKitRenderer *renderer = rendererForAttributes(_attributes, size);
  view.renderer = renderer;
  return result;
}

@end
