// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBComponent.h>

#import <FBComponentKit/CKTextKitAttributes.h>

struct CKTextComponentAccessibilityContext
{
  NSNumber *isAccessibilityElement;
  NSString *accessibilityIdentifier;
  NSNumber *providesAccessibleElements;
  /**
   Should rarely be used, the component's text will be used by default.
   */
  FBComponentAccessibilityTextAttribute accessibilityLabel;
};

@interface CKTextComponent : FBComponent

+ (instancetype)newWithTextAttributes:(const CKTextKitAttributes &)attributes
                       viewAttributes:(const FBViewComponentAttributeValueMap &)viewAttributes
                 accessibilityContext:(const CKTextComponentAccessibilityContext &)accessibilityContext;

@end
