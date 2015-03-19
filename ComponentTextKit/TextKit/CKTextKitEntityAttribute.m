// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBTextKit/FBTextKitEntityAttribute.h>

@implementation FBTextKitEntityAttribute

- (instancetype)initWithEntity:(id<NSObject>)entity
{
  if (self = [super init]) {
    _entity = entity;
  }
  return self;
}

- (NSUInteger)hash
{
  return [_entity hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  FBTextKitEntityAttribute *other = (FBTextKitEntityAttribute *)object;
  return _entity == other.entity || [_entity isEqual:other.entity];
}

@end
