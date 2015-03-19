// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKTextKitAttributes.h>

enum {
  CKUIControlEventTextViewDidBeginHighlightingText  = 1 << 24,
  CKUIControlEventTextViewDidCancelHighlightingText = 1 << 25,
  CKUIControlEventTextViewDidEndHighlightingText    = 1 << 26,
  CKUIControlEventTextViewDidTapText                = CKUIControlEventTextViewDidEndHighlightingText,
};

@class CKTextKitRenderer;

@interface CKTextComponentView : UIControl

@property (nonatomic, strong) CKTextKitRenderer *renderer;

@end
