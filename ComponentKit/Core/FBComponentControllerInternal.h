// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentController.h>

@interface FBComponentController ()

- (void)componentWillMount:(FBComponent *)component;
- (void)componentDidMount:(FBComponent *)component;
- (void)componentWillUnmount:(FBComponent *)component;
- (void)componentDidUnmount:(FBComponent *)component;
- (void)component:(FBComponent *)component willRelinquishView:(UIView *)view;
- (void)component:(FBComponent *)component didAcquireView:(UIView *)view;

@end
