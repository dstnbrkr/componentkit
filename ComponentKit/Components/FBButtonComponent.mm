// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBButtonComponent.h"

#import <array>

#import <FBComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"
#import "FBComponentSubclass.h"

/**
 Note this only enumerates through the default UIControlStates, not any application-defined or system-reserved ones.
 It excludes any states with both UIControlStateHighlighted and UIControlStateDisabled set as that is an invalid value.
 (UIButton will, surprisingly enough, throw away one of the bits if they are set together instead of ignoring it.)
 */
static void enumerateAllStates(void (^block)(UIControlState))
{
  for (int highlighted = 0; highlighted < 2; highlighted++) {
    for (int disabled = 0; disabled < 2; disabled++) {
      for (int selected = 0; selected < 2; selected++) {
        UIControlState state = (highlighted ? UIControlStateHighlighted : 0) | (disabled ? UIControlStateDisabled : 0) | (selected ? UIControlStateSelected : 0);
        if (state & UIControlStateHighlighted && state & UIControlStateDisabled) {
          continue;
        }
        block(state);
      }
    }
  }
}

static inline NSUInteger indexForState(UIControlState state)
{
  NSUInteger offset = 0;
  if (state & UIControlStateHighlighted) {
    offset += 4;
  }
  if (state & UIControlStateDisabled) {
    offset += 2;
  }
  if (state & UIControlStateSelected) {
    offset += 1;
  }
  return offset;
}

struct FBStateConfiguration {
  NSString *title;
  UIColor *titleColor;
  UIImage *image;
  UIImage *backgroundImage;

  bool operator==(const FBStateConfiguration &other) const
  {
    return CKObjectIsEqual(title, other.title)
    && CKObjectIsEqual(titleColor, other.titleColor)
    && CKObjectIsEqual(image, other.image)
    && CKObjectIsEqual(backgroundImage, other.backgroundImage);
  }
};

/** Use indexForState to map from UIControlState to an array index. */
typedef std::array<FBStateConfiguration, 8> FBStateConfigurationArray;

@interface FBButtonComponentConfiguration : NSObject
{
@public
  FBStateConfigurationArray _configurations;
  NSUInteger _precomputedHash;
}
@end

@implementation FBButtonComponent
{
  CGSize _intrinsicSize;
}

+ (instancetype)newWithTitles:(const std::unordered_map<UIControlState, NSString *> &)titles
                  titleColors:(const std::unordered_map<UIControlState, UIColor *> &)titleColors
                       images:(const std::unordered_map<UIControlState, UIImage *> &)images
             backgroundImages:(const std::unordered_map<UIControlState, UIImage *> &)backgroundImages
                    titleFont:(UIFont *)titleFont
                     selected:(BOOL)selected
                      enabled:(BOOL)enabled
                       action:(FBComponentAction)action
                         size:(const FBComponentSize &)size
                   attributes:(const FBViewComponentAttributeValueMap &)passedAttributes
   accessibilityConfiguration:(FBButtonComponentAccessibilityConfiguration)accessibilityConfiguration
{
  static const FBComponentViewAttribute titleFontAttribute = {"FBButtonComponent.titleFont", ^(UIButton *button, id value){
    button.titleLabel.font = value;
  }};

  static const FBComponentViewAttribute configurationAttribute = {
    "FBButtonComponent.config",
    ^(UIButton *view, FBButtonComponentConfiguration *config) {
      enumerateAllStates(^(UIControlState state) {
        const FBStateConfiguration &stateConfig = config->_configurations[indexForState(state)];
        if (stateConfig.title) {
          [view setTitle:stateConfig.title forState:state];
        }
        if (stateConfig.titleColor) {
          [view setTitleColor:stateConfig.titleColor forState:state];
        }
        if (stateConfig.image) {
          [view setImage:stateConfig.image forState:state];
        }
        if (stateConfig.backgroundImage) {
          [view setBackgroundImage:stateConfig.backgroundImage forState:state];
        }
      });
    },
    // No unapplicator.
    nil,
    ^(UIButton *view, FBButtonComponentConfiguration *oldConfig, FBButtonComponentConfiguration *newConfig) {
      enumerateAllStates(^(UIControlState state) {
        const FBStateConfiguration &oldStateConfig = oldConfig->_configurations[indexForState(state)];
        const FBStateConfiguration &newStateConfig = newConfig->_configurations[indexForState(state)];
        if (!CKObjectIsEqual(oldStateConfig.title, newStateConfig.title)) {
          [view setTitle:newStateConfig.title forState:state];
        }
        if (!CKObjectIsEqual(oldStateConfig.titleColor, newStateConfig.titleColor)) {
          [view setTitleColor:newStateConfig.titleColor forState:state];
        }
        if (!CKObjectIsEqual(oldStateConfig.image, newStateConfig.image)) {
          [view setImage:newStateConfig.image forState:state];
        }
        if (!CKObjectIsEqual(oldStateConfig.backgroundImage, newStateConfig.backgroundImage)) {
          [view setBackgroundImage:newStateConfig.backgroundImage forState:state];
        }
      });
    }
  };

  FBViewComponentAttributeValueMap attributes(passedAttributes);
  attributes.insert({
    {configurationAttribute, configurationFromValues(titles, titleColors, images, backgroundImages)},
    {titleFontAttribute, titleFont},
    {@selector(setSelected:), @(selected)},
    {@selector(setEnabled:), @(enabled)},
    {@selector(setAccessibilityIdentifier:), accessibilityConfiguration.accessibilityIdentifier},
  });
  if (action) {
    attributes.insert(FBComponentActionAttribute(action, UIControlEventTouchUpInside));
  }

  UIEdgeInsets contentEdgeInsets = UIEdgeInsetsZero;
  auto it = passedAttributes.find(@selector(setContentEdgeInsets:));
  if (it != passedAttributes.end()) {
    contentEdgeInsets = [it->second UIEdgeInsetsValue];
  }

  FBButtonComponent *b = [super
                          newWithView:{
                            [UIButton class],
                            std::move(attributes),
                            {
                              .accessibilityIdentifier = accessibilityConfiguration.accessibilityIdentifier,
                              .accessibilityLabel = accessibilityConfiguration.accessibilityLabel,
                              .accessibilityComponentAction = enabled ? action : NULL
                            }
                          }
                          size:size];

  UIControlState state = (selected ? UIControlStateSelected : UIControlStateNormal)
                       | (enabled ? UIControlStateNormal : UIControlStateDisabled);
  b->_intrinsicSize = intrinsicSize(valueForState(titles, state), titleFont, valueForState(images, state),
                                    valueForState(backgroundImages, state), contentEdgeInsets);
  return b;
}

- (FBComponentLayout)computeLayoutThatFits:(FBSizeRange)constrainedSize
{
  return {self, constrainedSize.clamp(_intrinsicSize)};
}

static FBButtonComponentConfiguration *configurationFromValues(const std::unordered_map<UIControlState, NSString *> &titles,
                                                               const std::unordered_map<UIControlState, UIColor *> &titleColors,
                                                               const std::unordered_map<UIControlState, UIImage *> &images,
                                                               const std::unordered_map<UIControlState, UIImage *> &backgroundImages)
{
  FBButtonComponentConfiguration *config = [[FBButtonComponentConfiguration alloc] init];
  FBStateConfigurationArray &configs = config->_configurations;
  NSUInteger hash = 0;
  for (const auto it : titles) {
    configs[indexForState(it.first)].title = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  for (const auto it : titleColors) {
    configs[indexForState(it.first)].titleColor = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  for (const auto it : images) {
    configs[indexForState(it.first)].image = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  for (const auto it : backgroundImages) {
    configs[indexForState(it.first)].backgroundImage = it.second;
    hash ^= (it.first ^ [it.second hash]);
  }
  config->_precomputedHash = hash;
  return config;
}

template<typename T>
static T valueForState(const std::unordered_map<UIControlState, T> &m, UIControlState state)
{
  auto it = m.find(state);
  if (it != m.end()) {
    return it->second;
  }
  // "If a title is not specified for a state, the default behavior is to use the title associated with the
  // UIControlStateNormal state." (Similarly for other attributes.)
  it = m.find(UIControlStateNormal);
  if (it != m.end()) {
    return it->second;
  }
  return nil;
}

static CGSize intrinsicSize(NSString *title, UIFont *titleFont, UIImage *image,
                            UIImage *backgroundImage, UIEdgeInsets contentEdgeInsets)
{
  // This computation is based on observing [UIButton -sizeThatFits:].
  CGSize titleSize = [title sizeWithFont:titleFont ?: [UIFont systemFontOfSize:[UIFont buttonFontSize]]];
  CGSize imageSize = image.size;
  CGSize contentSize = {
    titleSize.width + imageSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
    MAX(titleSize.height, imageSize.height) + contentEdgeInsets.top + contentEdgeInsets.bottom
  };
  CGSize backgroundImageSize = backgroundImage.size;
  return {
    MAX(backgroundImageSize.width, contentSize.width),
    MAX(backgroundImageSize.height, contentSize.height)
  };
}

@end

@implementation FBButtonComponentConfiguration

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  } else if ([object isKindOfClass:[self class]]) {
    FBButtonComponentConfiguration *other = object;
    return _configurations == other->_configurations;
  }
  return NO;
}

- (NSUInteger)hash
{
  return _precomputedHash;
}

@end
