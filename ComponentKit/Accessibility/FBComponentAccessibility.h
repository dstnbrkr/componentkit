// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/ComponentUtilities.h>
#import <FBComponentKit/FBComponentAction.h>

class FBComponentViewConfiguration;

typedef NSString *(^FBAccessibilityLazyTextBlock)();

/**
 A text attribute used for accessibility, this attribute can be initialized in two ways :
 - If some computation needs to be done like aggregation or other string manipulations you can provide a block that
   will be lazily executed when the component is mounted only when voiceover is enabled, this way we don't do
   unnecessary computations when VoiceOver is not enabled.
 - Use an NSString directly; reserve this for when no computation is needed to get the string
 */
struct FBComponentAccessibilityTextAttribute {
  FBComponentAccessibilityTextAttribute() {};
  FBComponentAccessibilityTextAttribute(FBAccessibilityLazyTextBlock textBlock) : accessibilityLazyTextBlock(textBlock) {};
  FBComponentAccessibilityTextAttribute(NSString *text) : accessibilityLazyTextBlock(^{ return text; }) {};

  BOOL hasText() const {
    return accessibilityLazyTextBlock != nil;
  }

  NSString *value() const {
    return accessibilityLazyTextBlock ? accessibilityLazyTextBlock() : nil;
  };

private:
  FBAccessibilityLazyTextBlock accessibilityLazyTextBlock;
};

/**
 Separate structure to handle accessibility as we want the components infrastructure to decide wether to use it or not depending if accessibility is enabled or not.
 */
struct FBComponentAccessibilityContext {
  NSNumber *isAccessibilityElement;
  NSString *accessibilityIdentifier;
  FBComponentAccessibilityTextAttribute accessibilityLabel;
  FBComponentAction accessibilityComponentAction;

  bool operator==(const FBComponentAccessibilityContext &other) const
  {
    return CKObjectIsEqual(other.accessibilityIdentifier, accessibilityIdentifier)
    && CKObjectIsEqual(other.isAccessibilityElement, isAccessibilityElement)
    && CKObjectIsEqual(other.accessibilityLabel.value(), accessibilityLabel.value())
    && other.accessibilityComponentAction == accessibilityComponentAction;
  }
};

namespace FB {
  namespace Component {
    namespace Accessibility {
      /**
       @return A modified configuration for which extra view component attributes have been added to handle accessibility.
       e.g: The following view configuration `{[UIView class], {{@selector(setBlah:), @"Blah"}}, {.accessibilityIdentifier = @"accessibilityId"}}`
       will become `{[UIView class], {{@selector(setBlah:), @"Blah"}, {@selector(setAccessibilityIdentifier), @"accessibilityId"}}, {.accessibilityIdentifier = @"accessibilityId"}}`
       */
      FBComponentViewConfiguration AccessibleViewConfiguration(const FBComponentViewConfiguration &viewConfiguration);
      BOOL IsAccessibilityEnabled();
    }
  }
}
