// Copyright 2004-present Facebook. All Rights Reserved.

#import <unordered_map>

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBComponentAction.h>

struct FBButtonComponentAccessibilityConfiguration {
  /** Accessibility identifier */
  NSString *accessibilityIdentifier;
  /** Accessibility label for the button. If one is not provided, the button title will be used as a label */
  NSString *accessibilityLabel;
};

/**
 A component that creates a UIButton.

 This component chooses the smallest size within its SizeRange that will fit its content. If its max size is smaller
 than the size required to fit its content, it will be truncated.
 */
@interface FBButtonComponent : FBComponent

+ (instancetype)newWithTitles:(const std::unordered_map<UIControlState, NSString *> &)titles
                  titleColors:(const std::unordered_map<UIControlState, UIColor *> &)titleColors
                       images:(const std::unordered_map<UIControlState, UIImage *> &)images
             backgroundImages:(const std::unordered_map<UIControlState, UIImage *> &)backgroundImages
                    titleFont:(UIFont *)titleFont
                     selected:(BOOL)selected
                      enabled:(BOOL)enabled
                       action:(FBComponentAction)action
                         size:(const FBComponentSize &)size
                   attributes:(const FBViewComponentAttributeValueMap &)attributes
   accessibilityConfiguration:(FBButtonComponentAccessibilityConfiguration)accessibilityConfiguration;

@end
