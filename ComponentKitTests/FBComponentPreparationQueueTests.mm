// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKit/FBComponent.h>
#import <FBComponentKit/FBComponentPreparationQueue.h>
#import <FBComponentKit/FBComponentPreparationQueueInternal.h>
#import <FBComponentKit/FBComponentProvider.h>

using namespace CK::ArrayController;

@interface FBCPQTestModel : NSObject
@end

@implementation FBCPQTestModel
@end

// OCMock doesn't support stubbing class methods on protocol mocks
@interface FBCPQTestComponentProvider : NSObject <FBComponentProvider>
@end

@implementation FBCPQTestComponentProvider

static FBComponent *(^_componentBlock)(void);

+ (void)setComponentBlock:(FBComponent *(^)(void))block
{
  _componentBlock = block;
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return _componentBlock ?  _componentBlock() : nil;
}

@end

@interface FBStubLayoutComponent : NSObject
@property (readwrite, nonatomic, copy) FBComponentLayout (^layoutBlock)(FBSizeRange);
- (FBComponentLayout)layoutThatFits:(FBSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize;
@end

@implementation FBStubLayoutComponent
- (FBComponentLayout)layoutThatFits:(FBSizeRange)constrainedSize
                         parentSize:(CGSize)parentSize
{
  return _layoutBlock(constrainedSize);
}
@end


@interface FBComponentPreparationQueueSyncTests : XCTestCase
@end

@implementation FBComponentPreparationQueueSyncTests

- (void)testPrepareInsertion
{
  FBStubLayoutComponent *component = [[FBStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(FBSizeRange s) {
    return (FBComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [FBCPQTestComponentProvider setComponentBlock:^FBComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBCPQTestComponentProvider class]
                                                                               context:nil];

  id model = [[FBCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeInsert;

  FBComponentPreparationInputItem *input = [[FBComponentPreparationInputItem alloc] initWithReplacementModel:model
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  FBComponentPreparationOutputItem *output = [FBComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  FBComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertEqualObjects(state.model, model);
}

- (void)testPrepareUpdate
{
  FBStubLayoutComponent *component = [[FBStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(FBSizeRange s) {
    return (FBComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [FBCPQTestComponentProvider setComponentBlock:^FBComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBCPQTestComponentProvider class]
                                                                               context:nil];

  id newModel = [[FBCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeUpdate;

  FBComponentPreparationInputItem *input = [[FBComponentPreparationInputItem alloc] initWithReplacementModel:newModel
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  FBComponentPreparationOutputItem *output = [FBComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  FBComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertEqualObjects(state.model, newModel);
}

- (void)testPrepareDeletion
{
  FBStubLayoutComponent *component = [[FBStubLayoutComponent alloc] init];
  __weak id weakComponent = component;
  component.layoutBlock = ^(FBSizeRange s) {
    return (FBComponentLayout){(id)weakComponent, CGSizeZero};
  };
  [FBCPQTestComponentProvider setComponentBlock:^FBComponent *{
    return (id)component;
  }];
  id lifecycleManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBCPQTestComponentProvider class]
                                                                               context:nil];

  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeDelete;

  FBComponentPreparationInputItem *input = [[FBComponentPreparationInputItem alloc] initWithReplacementModel:nil
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:NO];

  FBComponentPreparationOutputItem *output = [FBComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertNil([output lifecycleManager]);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));

  FBComponentLifecycleManagerState state = [output lifecycleManagerState];
  XCTAssertNil(state.model);
  XCTAssertNil(state.layout.component);
}

/**
 "Passthrough": A model is not component-compliant. We construct a dummy FBComponentLayoutManager, but do not construct
 a component for it.
 */
- (void)testPreparePassThrough
{
  [FBCPQTestComponentProvider setComponentBlock:^FBComponent *{
    XCTFail(@"Should not be called");
    return nil;
  }];
  id lifecycleManager = [[FBComponentLifecycleManager alloc] initWithComponentProvider:[FBCPQTestComponentProvider class]
                                                                               context:nil];

  id model = [[FBCPQTestModel alloc] init];
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:1];
  CKArrayControllerChangeType changeType = CKArrayControllerChangeTypeInsert;

  FBComponentPreparationInputItem *input = [[FBComponentPreparationInputItem alloc] initWithReplacementModel:model
                                                                                            lifecycleManager:lifecycleManager
                                                                                             constrainedSize:{{0,0}, {10, 20}}
                                                                                                     oldSize:{320, 100}
                                                                                                        UUID:@"foo"
                                                                                                   indexPath:indexPath
                                                                                                  changeType:changeType
                                                                                                 passthrough:YES];

  FBComponentPreparationOutputItem *output = [FBComponentPreparationQueue prepare:input];

  XCTAssertNotNil(output);
  XCTAssertEqual([output changeType], changeType);
  XCTAssertEqualObjects([output indexPath], indexPath);
  XCTAssertEqualObjects(output.replacementModel, input.replacementModel);
  XCTAssertEqualObjects([output UUID], [input UUID]);
  XCTAssertTrue(CGSizeEqualToSize([input oldSize], [output oldSize]));
}

@end
