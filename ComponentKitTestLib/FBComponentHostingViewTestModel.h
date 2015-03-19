// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>


#import <FBComponentKit/CKMacros.h>
#import <FBComponentKit/FBComponentSize.h>

@interface FBComponentHostingViewTestModel : NSObject

- (instancetype)initWithColor:(UIColor *)color
                         size:(const FBComponentSize &)size;

- (instancetype)init CK_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;

@property (nonatomic, strong, readonly) UIColor *color;

@property (nonatomic, readonly) FBComponentSize size;

@end

@class FBComponent;

#ifdef __cplusplus
extern "C" {
#endif

FBComponent *FBComponentWithHostingViewTestModel(FBComponentHostingViewTestModel *model);

#ifdef __cplusplus
}
#endif
