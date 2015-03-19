//
//  FBComponentHostingViewDelegate.h
//  FBComponentKit
//
//  Created by Jonathan Dann on 7/20/14.
//
//

#import <Foundation/Foundation.h>

@class FBComponentHostingView;

@protocol FBComponentHostingViewDelegate <NSObject>
@required
/**
 Called after the hosting view updates the component view to a new size.

 The delegate can use this callback to appropriately resize the view frame to fit the new
 component size. The view will not resize itself.
 */
- (void)componentHostingViewDidInvalidateSize:(FBComponentHostingView *)hostingView;
@end
