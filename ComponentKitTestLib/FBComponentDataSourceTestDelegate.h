// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKArrayControllerChangeType.h>

#import <FBComponentKit/FBComponentDataSource.h>
#import <FBComponentKit/FBComponentDataSourceOutputItem.h>

@interface FBComponentDataSourceTestDelegate : NSObject <FBComponentDataSourceDelegate>

@property (nonatomic, readonly) NSUInteger changeCount;
@property (nonatomic, readonly) NSArray *changes;

@property (nonatomic, copy) void (^onChange)(NSUInteger changeCount);

- (void)reset;

@end

@interface FBComponentDataSourceTestDelegateChange : NSObject

@property (nonatomic, strong) FBComponentDataSourceOutputItem *dataSourcePair;
@property (nonatomic, strong) FBComponentDataSourceOutputItem *oldDataSourcePair;
@property (nonatomic, assign) CKArrayControllerChangeType changeType;
@property (nonatomic, strong) NSIndexPath *beforeIndexPath;
@property (nonatomic, strong) NSIndexPath *afterIndexPath;

@end
