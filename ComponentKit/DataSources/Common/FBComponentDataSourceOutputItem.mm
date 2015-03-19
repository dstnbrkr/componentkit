// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentDataSourceOutputItem.h"

#import <FBHashKit/FBHash.h>

#import "ComponentUtilities.h"
#import "FBComponentLifecycleManager.h"
#import "CKMacros.h"

@implementation FBComponentDataSourceOutputItem
{
  FBComponentLifecycleManagerState _lifecycleManagerState;
  NSUInteger _hash;
}

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                   lifecycleManagerState:(const FBComponentLifecycleManagerState &)lifecycleManagerState
                                 oldSize:(CGSize)oldSize
                                   model:(id<NSObject>)model
                                    UUID:(NSString *)UUID
{
  if (self = [super init]) {
    _lifecycleManager = lifecycleManager;
    _lifecycleManagerState = lifecycleManagerState;
    _oldSize = oldSize;
    _model = model;
    _UUID = [UUID copy];

    NSUInteger subhashes[] = {
      [_lifecycleManager hash],
      [_model hash],
      [_UUID hash],
    };
    _hash = FBIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
  }
  return self;
}

- (const FBComponentLifecycleManagerState &)lifecycleManagerState
{
  return _lifecycleManagerState;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBComponentDataSourceOutputItem class]]) {
    return NO;
  }
  FBComponentDataSourceOutputItem *other = (FBComponentDataSourceOutputItem *)object;
  return (
          CKObjectIsEqual(_lifecycleManager, other->_lifecycleManager) &&
          CKObjectIsEqual(_model, other->_model) &&
          CKObjectIsEqual(_UUID, other->_UUID)
          );
}

- (NSUInteger)hash
{
  return _hash;
}

@end
