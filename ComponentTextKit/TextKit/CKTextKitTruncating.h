// Copyright 2004-present Facebook. All Rights Reserved.

#import <vector>

#import <UIKit/UIKit.h>

#import <FBComponentKit/CKTextKitRenderer.h>

@protocol CKTextKitTruncating <NSObject>

@property (nonatomic, assign, readonly) std::vector<NSRange> visibleRanges;
@property (nonatomic, assign, readonly) CGRect truncationStringRect;

/**
 A truncater object is initialized with the full state of the text.  It is a Single Responsibility Object that is
 mutative.  It configures the state of the TextKit components (layout manager, text container, text storage) to achieve
 the intended truncation, then it stores the resulting state for later fetching.

 The truncater may mutate the state of the text storage such that only the drawn string is actually present in the
 text storage itself.

 The truncater should not store a strong reference to the context to prevent retain cycles.
 */
- (instancetype)initWithContext:(CKTextKitContext *)context
     truncationAttributedString:(NSAttributedString *)truncationAttributedString
         avoidTailTruncationSet:(NSCharacterSet *)avoidTailTruncationSet
                constrainedSize:(CGSize)constrainedSize;

@end
