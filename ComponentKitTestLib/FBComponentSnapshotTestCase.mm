// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentSnapshotTestCase.h"

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBComponentLifecycleManager.h>
#import <FBComponentKit/FBComponentLifecycleManagerInternal.h>
#import <FBComponentKit/FBComponentProvider.h>
#import <FBComponentKit/FBComponentSubclass.h>

static FBComponent *(^_componentBlock)();
static FBComponent *_leakyComponent;

@interface FBComponentSnapshotTestCase () <FBComponentProvider>

@end

@implementation FBComponentSnapshotTestCase

- (BOOL)compareSnapshotOfComponent:(FBComponent *)component
                         sizeRange:(FBSizeRange)sizeRange
          referenceImagesDirectory:(NSString *)referenceImagesDirectory
                        identifier:(NSString *)identifier
                             error:(NSError **)errorPtr
{
  FBComponentLayout spec = [component layoutThatFits:sizeRange parentSize:sizeRange.max];
  FBComponentLifecycleManager *m = [[FBComponentLifecycleManager alloc] init];
  [m updateWithState:(FBComponentLifecycleManagerState){.layout = spec}];
  UIView *v = [[UIView alloc] initWithFrame:{{0,0}, spec.size}];
  [m attachToView:v];
  return [self compareSnapshotOfView:v
            referenceImagesDirectory:referenceImagesDirectory
                          identifier:identifier
                               error:errorPtr];
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  _leakyComponent = _componentBlock();
  return _leakyComponent;
}

- (BOOL)compareSnapshotOfComponentBlock:(FBComponent *(^)())componentBlock
                       updateStateBlock:(id (^)(id))updateStackBlock
                              sizeRange:(FBSizeRange)sizeRange
               referenceImagesDirectory:(NSString *)referenceImagesDirectory
                             identifier:(NSString *)identifier
                                  error:(NSError **)errorPtr;
{
  _componentBlock = componentBlock;

  FBComponentLifecycleManager *lifecycleManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[self class] context:nil];
  [lifecycleManager updateWithState:[lifecycleManager prepareForUpdateWithModel:nil constrainedSize:sizeRange]];
  [_leakyComponent updateState:updateStackBlock];

  return [self compareSnapshotOfComponent:[lifecycleManager state].layout.component
                                sizeRange:sizeRange
                 referenceImagesDirectory:referenceImagesDirectory
                               identifier:identifier
                                    error:errorPtr];
}

@end
