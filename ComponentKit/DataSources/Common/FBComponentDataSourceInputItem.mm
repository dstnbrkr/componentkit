// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentDataSourceInputItem.h"

#import <FBHashKit/FBHash.h>

#import "ComponentUtilities.h"
#import "FBComponentLifecycleManager.h"
#import "CKMacros.h"

@implementation FBComponentDataSourceInputItem
{
  NSUInteger _hash;
  FBSizeRange _constrainedSize;
}

- (instancetype)initWithLifecycleManager:(FBComponentLifecycleManager *)lifecycleManager
                                   model:(id<NSObject>)model
                         constrainedSize:(FBSizeRange)constrainedSize
                                    UUID:(NSString *)UUID
{
  if (self = [super init]) {
    _lifecycleManager = lifecycleManager;
    _model = model;
    _constrainedSize = constrainedSize;
    _UUID = [UUID copy];

    NSUInteger subhashes[] = {
      [_lifecycleManager hash],
      [_model hash],
      _constrainedSize.hash(),
      [_UUID hash],
    };
    _hash = FBIntegerArrayHash(subhashes, CK_ARRAY_COUNT(subhashes));
  }
  return self;
}

- (FBSizeRange)constrainedSize
{
  return _constrainedSize;
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBComponentDataSourceInputItem class]]) {
    return NO;
  }
  FBComponentDataSourceInputItem *other = (FBComponentDataSourceInputItem *)object;
  return (CKObjectIsEqual(_lifecycleManager, other->_lifecycleManager) &&
          CKObjectIsEqual(_model, other->_model) &&
          _constrainedSize == other->_constrainedSize &&
          CKObjectIsEqual(_UUID, other->_UUID));
}

- (NSUInteger)hash
{
  return _hash;
}

@end
