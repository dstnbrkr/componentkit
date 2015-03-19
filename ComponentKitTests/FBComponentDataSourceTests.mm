// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTest/XCTest.h>

#import <FBComponentKit/FBComponentConstantDecider.h>
#import <FBComponentKit/FBComponentDataSource.h>
#import <FBComponentKit/FBComponentDataSourceOutputItem.h>
#import <FBComponentKit/FBComponentProvider.h>
#import <FBComponentKit/FBComponentSuspendable.h>

#import <FBComponentKitTestLib/CKTestRunLoopRunnning.h>
#import <FBComponentKitTestLib/FBComponentDataSourceTestDelegate.h>

#import "FBComponentLifecycleManagerAsynchronousUpdateHandler.h"

using namespace CK::ArrayController;

namespace FB {

  namespace ComponentDataSource {

    struct Item {
      id<NSObject> object;

      Item(id<NSObject> o) : object(o) {};

      Item() : object(nil) {};

      bool operator==(const Item &other) const {
        return FBObjectIsEqual(object, other.object);
      }
    };

    typedef std::vector<Item> Items;

    struct Section {
      Items items;

      Section(Items it) : items(it) {};

      Section() : items({}) {};

      bool operator==(const Section &other) const {
        return items == other.items;
      }
    };

    typedef std::vector<Section> State;

    // Returns the state of all the empty and non-empty sections in the data source.
    // Useful to compare expected state with actual state in tests. Expected state can be declared inline in the test.
    static State state(FBComponentDataSource *dataSource) {
      __block State state;
      const NSInteger numberOfSections = [dataSource numberOfSections];
      for (NSInteger section = 0 ; section < numberOfSections ; ++section) {
        if ([dataSource numberOfObjectsInSection:section] > 0) {
          __block Items items;
          [dataSource enumerateObjectsInSectionAtIndex:section
                                            usingBlock:^(FBComponentDataSourceOutputItem *outputItem, NSIndexPath *indexPath, BOOL *stop) {
                                              items.push_back({[outputItem model]});
                                            }];
          state.push_back({items});
        } else {
          state.push_back({});
        }
      }
      return state;
    }

  }

}

#pragma mark -

@interface FBComponentDataSourceTests : XCTestCase <FBComponentProvider>
@end

/**
 Basic tests for state, initialization, etc.
 */
@implementation FBComponentDataSourceTests
{
  FBComponentDataSource *_dataSource;
}

+ (FBComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context
{
  return nil;
}

- (void)setUp
{
  [super setUp];
  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];
  dataSource.state = FBSuspensionControllerStateNotSuspended;
  _dataSource = dataSource;
}

- (void)tearDown
{
  _dataSource = nil;
  [super tearDown];
}

- (void)testInitialState
{
  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];
  XCTAssertNotNil(dataSource);
  XCTAssertEqual([dataSource state], FBSuspensionControllerStateFullySuspended);
  XCTAssertEqual([dataSource numberOfSections], 1, @"Currently there is only one section");
  XCTAssertEqual([dataSource numberOfObjectsInSection:0], 0);
  XCTAssertThrowsSpecificNamed([dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]],
                               NSException,
                               NSRangeException);
  XCTAssertFalse([dataSource hasPendingChanges]);
}

@end

static const FBSizeRange constrainedSize = {{320, 0}, {320, INFINITY}};

#pragma mark -

@interface FBComponentDataSourceSectionTests : XCTestCase
@end

@implementation FBComponentDataSourceSectionTests
{
  FBComponentDataSource *_dataSource;
  FBComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  FBComponentDataSourceTestDelegate *delegate = [[FBComponentDataSourceTestDelegate alloc] init];

  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];

  dataSource.state = FBSuspensionControllerStateNotSuspended;
  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)configureWithSingleSectionWithSingleItem
{
  Sections sections;
  sections.insert(0);
  Input::Items items;
  items.insert({0, 0}, @"Hello");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertionOfSingleSection
{
  Sections sections;
  sections.insert(0);

  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testAppendOfMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(1);
  sections.insert(2);
  sections.insert(3);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"}
      }
    },
    {},
    {},
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependOfMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {},
    {},
    {},
    {
      {
        {@"Hello"}
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependAndAppendMultipleSections
{
  [self configureWithSingleSectionWithSingleItem];

  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(3);
  sections.insert(4);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {},
    {},
    {
      {
        {@"Hello"}
      }
    },
    {},
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testEmptyDataSourceThrowsOnRemovalOfSection
{
  Sections sections;
  sections.remove(0);
  Input::Changeset changeset = {sections, {}};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSRangeException);
}

- (void)testRemovalOfSingleEmptySectionLeavesDataSourceEmpty
{
  [self configureWithSingleEmptySection];

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {};

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleEmptySections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalOfMultipleEmptySectionsFromHead
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(0);
  sections.remove(1);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalOfMultipleEmptySectionsFromTail
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(1);
  sections.remove(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalOfEmptySectionsFromHeadAndTail
{
  [self configureWithMultipleEmptySections];

  Sections sections;
  sections.remove(0);
  sections.remove(2);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

@end

#pragma mark -

@interface FBComponentDataSourceItemTests : XCTestCase
@end

@implementation FBComponentDataSourceItemTests
{
  FBComponentDataSource *_dataSource;
  FBComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  FBComponentDataSourceTestDelegate *delegate = [[FBComponentDataSourceTestDelegate alloc] init];

  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];

  dataSource.state = FBSuspensionControllerStateNotSuspended;
  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertion
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"}
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testEmptySectionThrowsOnRemovalOfItem
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.remove({0, 0});
  Input::Changeset changeset = {{}, items};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSRangeException);
}

- (void)testRemovalOfLastItemLeavesSectionEmpty
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {}
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testInsertionOfMultipleItemsInEmptySection
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({1, 0}, @"World");
  items.insert({2, 0}, @"Batman");
  items.insert({3, 0}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
        {@"Batman"},
        {@"Robin"}
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithSingleItemInSingleSection
{
  [self configureWithSingleEmptySection];
  Input::Items items;
  items.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testPrependOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({0, 0}, @"World");
  items.insert({1, 0}, @"Batman");
  items.insert({2, 0}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
        {@"Batman"},
        {@"Robin"},
        {@"Hello"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testAppendOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({1, 0}, @"World");
  items.insert({2, 0}, @"Batman");
  items.insert({3, 0}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
        {@"Batman"},
        {@"Robin"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testPrependAndAppendOfMultipleItemsInNonEmptySection
{
  [self configureWithSingleItemInSingleSection];

  Input::Items items;
  items.insert({0, 0}, @"World");
  items.insert({2, 0}, @"Batman");
  items.insert({3, 0}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
        {@"Hello"},
        {@"Batman"},
        {@"Robin"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleItemsInSingleSection
{
  [self configureWithSingleEmptySection];

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({1, 0}, @"World");
  items.insert({2, 0}, @"Batman");
  items.insert({3, 0}, @"Robin");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalAtHeadOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  items.remove({1, 0});
  items.remove({2, 0});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Robin"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalAtTailOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({1, 0});
  items.remove({2, 0});
  items.remove({3, 0});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testRemovalAtHeadAndTailOfNonEmptySection
{
  [self configureWithMultipleItemsInSingleSection];

  Input::Items items;
  items.remove({0, 0});
  items.remove({2, 0});
  items.remove({3, 0});
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
      }
    }
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testInsertionOfItemsInMultipleSections
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({1, 0}, @"World");
  items.insert({0, 1}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"World"},
      }
    },
    {
      {
        {@"Batman"},
        {@"Robin"},
      }
    },
    {},
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)configureWithMultipleSectionsAndItems
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({1, 0}, @"World");
  items.insert({0, 1}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testRemovalOfItemsInMultipleSections
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items items;
  items.remove({0, 0});
  items.remove({0, 1});

  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"World"},
      }
    },
    {
      {
        {@"Robin"},
      }
    },
    {},
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testUpdateOfMultipleItems
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items items;
  items.update({1, 0}, @"Universe");
  items.update({0, 1}, @"Joker");
  items.update({1, 1}, @"Harley");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
        {@"Universe"},
      }
    },
    {
      {
        {@"Joker"},
        {@"Harley"},
      }
    },
    {},
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

- (void)testUpdateOfItemInEmptySectionThrows
{
  [self configureWithSingleEmptySection];
  Input::Items items;
  items.update({0, 0}, @"nonsense");
  Input::Changeset changeset = {{}, items};
  XCTAssertThrowsSpecificNamed([_dataSource enqueueChangeset:changeset constrainedSize:constrainedSize],
                               NSException,
                               NSRangeException);
}

- (void)testTailInsertionOnMergeSuspended
{
  [self configureWithSingleItemInSingleSection];
  _dataSource.state = FBSuspensionControllerStateMergeSuspended;

  Input::Items items;
  items.insert({0, 0}, @"Hello2");
  [_dataSource enqueueChangeset:{{}, items} constrainedSize:constrainedSize];

  Input::Items items2;
  items2.insert({2, 0}, @"Hello3");
  items2.insert({3, 0}, @"Hello4");
  items2.insert({4, 0}, @"Hello5");
  [_dataSource enqueueChangeset:{{}, items2} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:1];
  XCTAssertEqual([_dataSource numberOfObjectsInSection:0], 4,
                 @"The number of objects in the datasource under suspension is not what's expected");
}

- (void)testEnqueueReload
{
  [self configureWithSingleItemInSingleSection];
  [_dataSource enqueueReload];

  [self waitUntilChangeCountIs:1];

  FB::ComponentDataSource::State expectedState = {
    {
      {
        {@"Hello"},
      }
    },
  };

  FB::ComponentDataSource::State state = FB::ComponentDataSource::state(_dataSource);
  XCTAssertTrue(state == expectedState);
}

@end

#pragma mark -

@interface FBComponentDataSourceInflightChangesTests : XCTestCase
@end

@implementation FBComponentDataSourceInflightChangesTests
{
  FBComponentDataSource *_dataSource;
  FBComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  FBComponentDataSourceTestDelegate *delegate = [[FBComponentDataSourceTestDelegate alloc] init];

  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];

  dataSource.state = FBSuspensionControllerStateNotSuspended;
  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return _delegate.changeCount == changeCount;
  }), @"timeout");
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
                      onChange:(void(^)(NSUInteger changeCount, FB::ComponentDataSource::State state))onChange
{
  id dataSource = _dataSource; // Stop ARC complaining about a retain-cycle.
  _delegate.onChange = ^(NSUInteger count) {
    onChange(count, FB::ComponentDataSource::state(dataSource));
  };
  [self waitUntilChangeCountIs:changeCount];
}

- (void)configureWithSingleEmptySection
{
  Sections sections;
  sections.insert(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testInsertionOfSectionsInSeparateChangesets
{
  Sections sections1;
  sections1.insert(0);
  sections1.insert(1);
  [_dataSource enqueueChangeset:{sections1, {}} constrainedSize:constrainedSize];

  Sections sections2;
  sections2.insert(2);
  sections2.insert(3);
  [_dataSource enqueueChangeset:{sections2, {}} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, FB::ComponentDataSource::State state) {
    if (changeCount == 1) {
      FB::ComponentDataSource::State expectedState = {
        {},
        {},
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      FB::ComponentDataSource::State expectedState = {
        {},
        {},
        {},
        {}
      };
      XCTAssertTrue(state == expectedState);
    } else {
      XCTFail(@"%lu", (unsigned long)changeCount);
    }
  }];
}

- (void)testInsertionThenUpdateOfItemInSeparateChangesets
{
  [self configureWithSingleEmptySection];

  Input::Items items1;
  items1.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items1} constrainedSize:constrainedSize];

  Input::Items items2;
  items2.update({0, 0}, @"Batman");
  [_dataSource enqueueChangeset:{{}, items2} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, FB::ComponentDataSource::State state) {
    if (changeCount == 1) {
      FB::ComponentDataSource::State expectedState = {
        {
          {
            {@"Hello"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      FB::ComponentDataSource::State expectedState = {
        {
          {
            {@"Batman"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else {
      XCTFail(@"%lu", (unsigned long)changeCount);
    }
  }];
}

- (void)testInsertionThenRemovalOfItemInSeparateChangesets
{
  [self configureWithSingleEmptySection];

  Input::Items items1;
  items1.insert({0, 0}, @"Hello");
  [_dataSource enqueueChangeset:{{}, items1} constrainedSize:constrainedSize];

  Input::Items items2;
  items2.remove({0, 0});
  [_dataSource enqueueChangeset:{{}, items2} constrainedSize:constrainedSize];

  [self waitUntilChangeCountIs:2 onChange:^(NSUInteger changeCount, FB::ComponentDataSource::State state) {
    if (changeCount == 1) {
      FB::ComponentDataSource::State expectedState = {
        {
          {
            {@"Hello"}
          }
        }
      };
      XCTAssertTrue(state == expectedState);
    } else if (changeCount == 2) {
      FB::ComponentDataSource::State expectedState = {
        {}
      };
      XCTAssertTrue(state == expectedState);
    }
  }];
}

@end

@interface FBComponentDataSourceEnumerationTests : XCTestCase
@end

@implementation FBComponentDataSourceEnumerationTests
{
  FBComponentDataSource *_dataSource;
  FBComponentDataSourceTestDelegate *_delegate;
}

- (void)setUp
{
  [super setUp];

  FBComponentDataSourceTestDelegate *delegate = [[FBComponentDataSourceTestDelegate alloc] init];

  FBComponentConstantDecider *decider = [[FBComponentConstantDecider alloc] initWithEnabled:NO];
  FBComponentDataSource *dataSource = [[FBComponentDataSource alloc] initWithComponentProvider:nil
                                                                                       context:nil
                                                                                       decider:decider];

  dataSource.state = FBSuspensionControllerStateNotSuspended;
  dataSource.delegate = delegate;

  _dataSource = dataSource;
  _delegate = delegate;

  Sections sections;
  sections.remove(0);
  [_dataSource enqueueChangeset:{sections, {}} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)tearDown
{
  _dataSource = nil;
  _delegate = nil;
  [super tearDown];
}

- (void)waitUntilChangeCountIs:(NSUInteger)changeCount
{
  XCTAssertTrue(CKRunRunLoopUntilBlockIsTrue(^BOOL(void){
    if (_delegate.changeCount > changeCount) {
      XCTFail(@"%lu", (unsigned long)_delegate.changeCount);
    }
    return (_delegate.changeCount == changeCount);
  }), @"timeout");
}

- (void)configureWithMultipleSectionsAndItems
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  sections.insert(2);

  Input::Items items;
  items.insert({0, 0}, @"Hello");
  items.insert({1, 0}, @"World");
  items.insert({0, 1}, @"Batman");
  items.insert({1, 1}, @"Robin");

  [_dataSource enqueueChangeset:{sections, items} constrainedSize:constrainedSize];
  [self waitUntilChangeCountIs:1];
  [_delegate reset];
}

- (void)testObjectForUUIDWithNilUUIDReturnsNil
{
  [self configureWithMultipleSectionsAndItems];

  auto pair = [_dataSource objectForUUID:nil];
  XCTAssertNil(pair.first);
  XCTAssertNil(pair.second);
}

- (void)testObjectForUUIDWithNotFoundUUIDReturnsNil
{
  [self configureWithMultipleSectionsAndItems];

  auto pair = [_dataSource objectForUUID:@"123456789"];
  XCTAssertNil(pair.first);
  XCTAssertNil(pair.second);
}

- (void)testObjectForUUIDReturnsObjectWhenFound
{
  [self configureWithMultipleSectionsAndItems];

  FBComponentDataSourceOutputItem *item = [_dataSource objectAtIndexPath:IndexPath(0, 1).toNSIndexPath()];
  auto pair = [_dataSource objectForUUID:[item UUID]];

  XCTAssertEqualObjects([pair.first model], @"Batman");
  XCTAssertEqualObjects(pair.second, IndexPath(0, 1).toNSIndexPath());
}

- (void)DISABLED_testHandleAsynchronousUpdateForComponentLifecycleManagerProperlyEnqueueAnUpdate // Flaky; task #5619986 tracks re-enabling
{
  //Configuration
  [self configureWithMultipleSectionsAndItems];
  [_delegate reset];
  NSIndexPath *indexPath = IndexPath(0,1).toNSIndexPath();
  FBComponentDataSourceOutputItem *outputItem = [_dataSource objectAtIndexPath:indexPath];
  FBComponentLifecycleManager *lifecycleManager = [outputItem lifecycleManager];

  //Expected change
  FBComponentDataSourceTestDelegateChange *expectedChange = [[FBComponentDataSourceTestDelegateChange alloc] init];
  expectedChange.dataSourcePair = outputItem;
  expectedChange.oldDataSourcePair = outputItem;
  expectedChange.changeType = CKArrayControllerChangeTypeUpdate;
  expectedChange.beforeIndexPath = indexPath;
  expectedChange.afterIndexPath = indexPath;

  [(id<FBComponentLifecycleManagerAsynchronousUpdateHandler>)_dataSource handleAsynchronousUpdateForComponentLifecycleManager:lifecycleManager];
  [self waitUntilChangeCountIs:1];
  XCTAssertEqualObjects(_delegate.changes[0], expectedChange);
}

- (void)testIsComputingChanges
{
  [self configureWithMultipleSectionsAndItems];

  Input::Items batch1;
  batch1.insert({2, 0}, @"Catwoman");
  batch1.insert({0, 2}, @"Penguin");
  batch1.update({1, 1}, @"Joker");

  Input::Items batch2;
  batch2.remove({0,2});
  batch2.update({0,1}, {@"Alfred"});

  XCTAssertFalse([_dataSource isComputingChanges]);
  [_dataSource enqueueChangeset:{batch1} constrainedSize:constrainedSize];
  XCTAssertTrue([_dataSource isComputingChanges]);
  [_dataSource enqueueChangeset:{batch2} constrainedSize:constrainedSize];
  XCTAssertTrue([_dataSource isComputingChanges]);
  [self waitUntilChangeCountIs:2];
  XCTAssertFalse([_dataSource isComputingChanges]);
}

@end
