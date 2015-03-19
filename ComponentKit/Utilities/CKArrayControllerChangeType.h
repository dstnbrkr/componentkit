// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CKArrayControllerChangeType) {
  CKArrayControllerChangeTypeUnknown = 0,
  CKArrayControllerChangeTypeInsert = 1,
  CKArrayControllerChangeTypeDelete,
  CKArrayControllerChangeTypeMove,
  CKArrayControllerChangeTypeUpdate,
};
