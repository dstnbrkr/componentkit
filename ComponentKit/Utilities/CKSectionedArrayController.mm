// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKSectionedArrayController.h>

#import <UIKit/UIKit.h>

#import <FBBase/FBArgumentPrecondition.h>
#import <FBBase/NSObject+FBBase.h>

using namespace CK::ArrayController;

@implementation FBSectionedArrayController
{
  NSMutableArray *_sections;
}

- (instancetype)init
{
  if (self = [super init]) {
    _sections = [NSMutableArray array];
  }
  return self;
}

#pragma mark -

- (NSString *)description
{
  const NSInteger numberOfSections = [self numberOfSections];
  NSMutableString *sectionSummaries = [[NSMutableString alloc] init];
  for (NSInteger section = 0; section < numberOfSections; ++section) {
    [sectionSummaries appendFormat:@"{section:%zd, objects:%tu}", section, [self numberOfObjectsInSection:section]];
    if (section != (numberOfSections - 1)) {
      [sectionSummaries appendFormat:@"\n"];
    }
  }
  return [self fb_description:@{
                                @"summary": [NSString stringWithFormat:@"sections:%zd, %@", numberOfSections, sectionSummaries],
                                @"contents": _sections
                                }];
}

- (NSInteger)numberOfSections
{
  return (NSInteger)[_sections count];
}

- (NSInteger)numberOfObjectsInSection:(NSInteger)section
{
  FBArgumentPreconditionCheckIf(section >= 0, @"");
  return (NSInteger)[_sections[(NSUInteger)section] count];
}

- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath
{
  FBArgumentPreconditionCheckIf(indexPath != nil, @"");
  return (id<NSObject>)_sections[(NSUInteger)[indexPath section]][(NSUInteger)[indexPath item]];
}

typedef void (^SectionEnumerator)(NSInteger sectionIndex, NSArray *section, FBSectionedArrayControllerEnumerator enumerator, BOOL *stop);

NS_INLINE SectionEnumerator _sectionEnumeratorBlock(void)
{
  return ^(NSInteger sectionIndex, NSArray *section, FBSectionedArrayControllerEnumerator enumerator, BOOL *stop) {
    NSInteger i = 0;
    for (id<NSObject> object in section) {
      const NSUInteger indexes[] = {(NSUInteger)sectionIndex, (NSUInteger)i++};
      NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndexes:indexes length:ARRAY_COUNT(indexes)];
      enumerator(object, indexPath, stop);
      if (stop) {
        if (*stop) { break; }
      }
    }
  };
}

- (void)enumerateObjectsUsingBlock:(FBSectionedArrayControllerEnumerator)enumerator
{
  if (enumerator) {
    NSInteger s = 0;
    BOOL stop = NO;
    for (NSMutableArray *section in _sections) {
      _sectionEnumeratorBlock()(s, section, enumerator, &stop);
      if (stop) { break; }
      s++;
    }
  }
}

- (void)enumerateObjectsInSectionAtIndex:(NSInteger)sectionIndex usingBlock:(FBSectionedArrayControllerEnumerator)enumerator
{
  if (enumerator) {
    BOOL stop = NO;
    _sectionEnumeratorBlock()(sectionIndex, _sections[(NSUInteger)sectionIndex], enumerator, &stop);
  }
}

- (std::pair<id<NSObject>, NSIndexPath *>)firstObjectPassingTest:(FBSectionedArrayControllerPredicate)predicate
{
  __block id<NSObject> object;
  __block NSIndexPath *indexPath;
  if (predicate) {
    [self enumerateObjectsUsingBlock:^(id<NSObject> o, NSIndexPath *iP, BOOL *stop) {
      if (predicate(o, iP, stop)) {
        object = o;
        indexPath = iP;
        *stop = YES;
      }
    }];
  }
  return {object, indexPath};
}

NS_INLINE NSArray *_createEmptySections(NSUInteger count)
{
  NSMutableArray *emptySections = [[NSMutableArray alloc] init];
  for (NSUInteger i = 0 ; i < count ; ++i) {
    [emptySections addObject:[[NSMutableArray alloc] init]];
  }
  return emptySections;
}

/**
 Returns a block that inserts/removes sections.

 @param sections Same pointer as our _sections ivar.
 @param outputChangeset On return contains all the commands for the outuput changeset.
 @returns A block that mutates the passed in array and builds the outputChangeset.
 */
NS_INLINE Sections::Enumerator sectionEnumerator(NSMutableArray *sections, Sections &outputSections)
{
  return ^(NSIndexSet *indexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {

      [indexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *s) {
        outputSections.remove((NSInteger)itemIndex);
      }];

      [sections removeObjectsAtIndexes:indexes];

    } else if (type == CKArrayControllerChangeTypeInsert) {

      [indexes enumerateIndexesUsingBlock:^(NSUInteger sectionIndex, BOOL *s) {
        outputSections.insert((NSInteger)sectionIndex);
      }];

      NSArray *emptySections = _createEmptySections([indexes count]);
      [sections insertObjects:emptySections atIndexes:indexes];

    }
  };
}

/**
 Returns a block that inserts/removes/updates items within a section.

 @param sections Same pointer as our _sections ivar.
 @param outputChangeset On return contains all the commands for the outuput changeset.
 @returns A block that mutates the passed in array and builds the outputChangeset.
 */
NS_INLINE Input::Items::Enumerator itemEnumerator(NSMutableArray *sections, Output::Items &outputItems)
{
  return ^(NSInteger sectionIndex, NSIndexSet *itemIndexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {

    NSMutableArray *section = sections[(NSUInteger)sectionIndex];

    if (type == CKArrayControllerChangeTypeUpdate) {

      // We need the current state of the section.
      NSArray *originals = [section objectsAtIndexes:itemIndexes];

      // Build up the output commands using the current state of the section and the replacement objects.
      __block NSUInteger i = 0;
      [itemIndexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *s) {
        outputItems.update({
          {(NSInteger)itemIndex, sectionIndex},
          originals[i],
          objects[i]
        });
        i++;
      }];

      // Then update the section.
      [section replaceObjectsAtIndexes:itemIndexes withObjects:objects];

    } else if (type == CKArrayControllerChangeTypeInsert) {

      // Build up the output commands.
      __block NSUInteger i = 0;
      [itemIndexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *s) {
        outputItems.insert({
          {(NSInteger)itemIndex, sectionIndex},
          objects[i++],
        });
      }];

      // Then update the section.
      [section insertObjects:objects atIndexes:itemIndexes];

    } else if (type == CKArrayControllerChangeTypeDelete) {

      // We need the current state of the section.
      NSArray *removed = [section objectsAtIndexes:itemIndexes];

      // Build up the output commands.
      __block NSUInteger i = 0;
      [itemIndexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *s) {
        outputItems.remove({
          {(NSInteger)itemIndex, sectionIndex},
          removed[i++],
        });
      }];

      // Then update the section.
      [section removeObjectsAtIndexes:itemIndexes];

    }
  };
}

- (CKArrayControllerOutputChangeset)applyChangeset:(CKArrayControllerInputChangeset)changeset
{
  Sections outputSections;
  Sections::Enumerator sectionsBlock = sectionEnumerator(_sections, outputSections);

  Output::Items outputItems;
  Input::Items::Enumerator itemsBlock = itemEnumerator(_sections, outputItems);

  /**
   See the header docs for enumerate(). There we detail the order of block invocation.
   */
  changeset.enumerate(sectionsBlock, itemsBlock);

  return {outputSections, outputItems};
}

@end
