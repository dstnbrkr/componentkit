// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentAccessibility.h"
#import "FBComponentAccessibility_Private.h"

#import <FBComponentKit/CKAssert.h>

#import "ComponentViewManager.h"
#import "FBComponentViewConfiguration.h"

/** Helper that converts the accessibility context characteristics to a map of component view attributes */
static FBViewComponentAttributeValueMap ViewAttributesFromAccessibilityContext(const FBComponentAccessibilityContext &accessibilityContext)
{
  FBViewComponentAttributeValueMap accessibilityAttributes;
  if (accessibilityContext.accessibilityIdentifier) {
    accessibilityAttributes[@selector(setAccessibilityIdentifier:)] = accessibilityContext.accessibilityIdentifier;
  }
  if (accessibilityContext.isAccessibilityElement) {
    accessibilityAttributes[@selector(setIsAccessibilityElement:)] = accessibilityContext.isAccessibilityElement;
  }
  if (accessibilityContext.accessibilityLabel.hasText()) {
    accessibilityAttributes[@selector(setAccessibilityLabel:)] = accessibilityContext.accessibilityLabel.value();
  }
  return accessibilityAttributes;
}

FBComponentViewConfiguration FB::Component::Accessibility::AccessibleViewConfiguration(const FBComponentViewConfiguration &viewConfiguration)
{
  CKCAssertMainThread();
  // Copy is intentional so we can move later.
  FBComponentAccessibilityContext accessibilityContext = viewConfiguration.accessibilityContext();
  const FBViewComponentAttributeValueMap &accessibilityAttributes = ViewAttributesFromAccessibilityContext(accessibilityContext);
  if (accessibilityAttributes.size() > 0) {
    FBViewComponentAttributeValueMap newAttributes(*viewConfiguration.attributes());
    newAttributes.insert(accessibilityAttributes.begin(), accessibilityAttributes.end());
    // Copy is intentional so we can move later.
    FBComponentViewClass viewClass = viewConfiguration.viewClass();
    // If the specified view class doesn't have a view, force the creation of one
    // so the accessibility attributes can be realized.
    return FBComponentViewConfiguration(viewClass.hasView() ? std::move(viewClass) : FBComponentViewClass([UIView class]),
                                        std::move(newAttributes), std::move(accessibilityContext));
  } else {
    return viewConfiguration;
  }
}

static BOOL _forceAccessibilityEnabled = NO;
static BOOL _forceAccessibilityDisabled = NO;

void FB::Component::Accessibility::SetForceAccessibilityEnabled(BOOL enabled)
{
  _forceAccessibilityEnabled = enabled;
  _forceAccessibilityDisabled = !enabled;
}

BOOL FB::Component::Accessibility::IsAccessibilityEnabled()
{
  CKCAssertMainThread();
  return !_forceAccessibilityDisabled && (_forceAccessibilityEnabled || UIAccessibilityIsVoiceOverRunning());
}
