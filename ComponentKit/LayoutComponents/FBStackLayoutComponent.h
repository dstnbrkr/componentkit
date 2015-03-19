// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <FBComponentKit/FBComponent.h>

typedef NS_ENUM(NSUInteger, FBStackLayoutDirection) {
  FBStackLayoutDirectionVertical,
  FBStackLayoutDirectionHorizontal,
};

/** If no children are flexible, how should this component justify its children in the available space? */
typedef NS_ENUM(NSUInteger, FBStackLayoutJustifyContent) {
  /**
   On overflow, children overflow out of this component's bounds on the right/bottom side.
   On underflow, children are left/top-aligned within this component's bounds.
   */
  FBStackLayoutJustifyContentStart,
  /**
   On overflow, children are centered and overflow on both sides.
   On underflow, children are centered within this component's bounds in the stacking direction.
   */
  FBStackLayoutJustifyContentCenter,
  /**
   On overflow, children overflow out of this component's bounds on the left/top side.
   On underflow, children are right/bottom-aligned within this component's bounds.
   */
  FBStackLayoutJustifyContentEnd,
};

typedef NS_ENUM(NSUInteger, FBStackLayoutAlignItems) {
  /** Align children to start of cross axis */
  FBStackLayoutAlignItemsStart,
  /** Align children with end of cross axis */
  FBStackLayoutAlignItemsEnd,
  /** Center children on cross axis */
  FBStackLayoutAlignItemsCenter,
  /** Expand children to fill cross axis */
  FBStackLayoutAlignItemsStretch,
};

/**
 Each child may override their parent stack's cross axis alignment.
 @see FBStackLayoutAlignItems
 */
typedef NS_ENUM(NSUInteger, FBStackLayoutAlignSelf) {
  /** Inherit alignment value from containing stack. */
  FBStackLayoutAlignSelfAuto,
  FBStackLayoutAlignSelfStart,
  FBStackLayoutAlignSelfEnd,
  FBStackLayoutAlignSelfCenter,
  FBStackLayoutAlignSelfStretch,
};

struct FBStackLayoutComponentStyle {
  /** Specifies the direction children are stacked in. */
  FBStackLayoutDirection direction;
  /** The amount of space between each child. */
  CGFloat spacing;
  /** How children are aligned if there are no flexible children. */
  FBStackLayoutJustifyContent justifyContent;
  /** Orientation of children along cross axis */
  FBStackLayoutAlignItems alignItems;
};

struct FBStackLayoutComponentChild {
  FBComponent *component;
  /** Additional space to place before the component in the stacking direction. */
  CGFloat spacingBefore;
  /** Additional space to place after the component in the stacking direction. */
  CGFloat spacingAfter;
  /** If the sum of childrens' stack dimensions is less than the minimum size, should this component grow? */
  BOOL flexGrow;
  /** If the sum of childrens' stack dimensions is greater than the maximum size, should this component shrink? */
  BOOL flexShrink;
  /** Specifies the initial size in the stack dimension for the child. */
  FBRelativeDimension flexBasis;
  /** Orientation of the child along cross axis, overriding alignItems */
  FBStackLayoutAlignSelf alignSelf;
};

/**
 A simple layout component that stacks a list of children vertically or horizontally.

 - All children are initially laid out with the an infinite available size in the stacking direction.
 - In the other direction, this component's constraint is passed.
 - The children's sizes are summed in the stacking direction.
   - If this sum is less than this component's minimum size in stacking direction, children with flexGrow are flexed.
   - If it is greater than this component's maximum size in the stacking direction, children with flexShrink are flexed.
   - If, even after flexing, the sum is still greater than this component's maximum size in the stacking direction,
     justifyContent determines how children are laid out.

 For example:
 - Suppose stacking direction is Vertical, min-width=100, max-width=300, min-height=200, max-height=500.
 - All children are laid out with min-width=100, max-width=300, min-height=0, max-height=INFINITY.
 - If the sum of the childrens' heights is less than 200, components with flexGrow are flexed larger.
 - If the sum of the childrens' heights is greater than 500, components with flexShrink are flexed smaller.
   Each component is shrunk by `((sum of heights) - 500)/(number of components)`.
 - If the sum of the childrens' heights is greater than 500 even after flexShrink-able components are flexed,
   justifyContent determines how children are laid out.
 */
@interface FBStackLayoutComponent : FBComponent

/**
 @param view A view configuration, or {} for no view.
 @param size A size, or {} for the default size.
 @param style Specifies how children are laid out.
 @param children A vector of children components.
 */
+ (instancetype)newWithView:(const FBComponentViewConfiguration &)view
                       size:(const FBComponentSize &)size
                      style:(FBStackLayoutComponentStyle)style
                   children:(const std::vector<FBStackLayoutComponentChild> &)children;

@end
