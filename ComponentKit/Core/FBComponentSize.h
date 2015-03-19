// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBDimension.h>

/**
 A struct specifying a component's size. Example:

   FBComponentSize size = {
     .width = Percent(0.5),
     .maxWidth = 200,
     .minHeight = Percent(0.75)
   };

   // <FBComponentSize: exact={50%, Auto}, min={Auto, 75%}, max={200pt, Auto}>
   size.description();

 */
struct FBComponentSize {
  FBRelativeDimension width;
  FBRelativeDimension height;

  FBRelativeDimension minWidth;
  FBRelativeDimension minHeight;

  FBRelativeDimension maxWidth;
  FBRelativeDimension maxHeight;

  static FBComponentSize fromCGSize(CGSize size);

  FBSizeRange resolve(const CGSize &parentSize) const;

  bool operator==(const FBComponentSize &other) const;
  NSString *description() const;
};
