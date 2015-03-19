// Copyright 2004-present Facebook. All Rights Reserved.

#import <map>
#import <set>
#import <vector>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <FBComponentKit/CKArrayControllerChangeType.h>

#import <FBBase/FBEqualityHelpers.h>
#import <FBBase/FBMath.h>

/**
 FBSectionedArrayController is mutated via an -applyChanges: method which takes an CK::ArrayController::Input::Changeset
 and returns an CK::ArrayController::Output::Changeset.

 The input is a list of commands to apply to the array controller: insert this section, update this object, etc. While
 the output can be enumerated such that the changes can be applied to a UITableView or UICollectionView.

 In order for changes to be "UI{Table|Collection|}View compliant" the index paths for updates and removals (of both
 sections and items) should be relative to the initial state of the array controller, while insertions should be
 relative to the state **after** removals have been applied. FBSectionedArrayController is written with the same
 constraints. In doing so we don't need to do any index-munging while were inserting or removing items or sections.
 */

namespace CK {

  namespace ArrayController {

    /**
     More concise than using NSIndexPaths all over the place, and doesn't require heap allocations.
     */
    struct IndexPath {
      NSInteger section;
      NSInteger item;

      IndexPath(void) : item(NSNotFound), section(NSNotFound) {};

      IndexPath(NSInteger i, NSInteger s) : item(i), section(s) {};

      IndexPath(NSIndexPath *indexPath) : item(indexPath ? [indexPath item] : NSNotFound), section(indexPath ? [indexPath section] : NSNotFound) {};

      NSIndexPath *toNSIndexPath(void) const NS_RETURNS_RETAINED {
        const NSUInteger indexes[] = {(NSUInteger)section, (NSUInteger)item};
        return [[NSIndexPath alloc] initWithIndexes:indexes length:ARRAY_COUNT(indexes)];
      }

      bool operator==(const IndexPath &other) const {
        return section == other.section && item == other.item;
      }

      bool operator<(const IndexPath &other) const {
        if (section < other.section) {
          return true;
        }
        if (section == other.section) {
          return item < other.item;
        }
        return false;
      }
    };

    class Sections final {
    public:
      ~Sections();
      void insert(NSInteger index);
      void remove(NSInteger index);

      const std::set<NSInteger> &insertions(void) const;
      const std::set<NSInteger> &removals(void) const;

      bool operator==(const Sections &other) const;

      size_t size() const noexcept;

      /**
       Called by Changeset::enumerate(). Note that by passing an NSIndexSet the **order** that clients have called
       Sections::insert() is irrelevant. See CKArrayControllerInputChangesetTests for an example. The indexes and objects
       parameters will always have the same number of elements.

       In doing so we can, for example, simply call -[NSArray removeObjectsAtIndexes:] and let NSArray do the
       hard work of index-munging.
       */
      typedef void(^Enumerator)(NSIndexSet *sectionIndexes,
                                CKArrayControllerChangeType type,
                                BOOL *stop);

    private:
      std::set<NSInteger> _insertions;
      std::set<NSInteger> _removals;
    };

  }

}

namespace CK {

  namespace ArrayController {

    namespace Input {

      /**
       Describes the insertions, removal and update commands for items in an FBSectionedArrayController.
       */
      class Items final {
      public:
        ~Items();
        void update(const IndexPath &indexPath, id<NSObject> object);
        void remove(const IndexPath &indexPath);
        void insert(const IndexPath &indexPath, id<NSObject> object);

        size_t size() const noexcept;

        bool operator==(const Items &other) const;

        /**
         Called by Changeset::enumerate(). Note that by passing an NSIndexSet the **order** that clients have called
         Items::insert() is irrelevant. See CKArrayControllerInputChangesetTests for an example. The indexes and objects
         parameters will always have the same number of elements.

         In doing so we can, for example, simply call -[NSArray insertObjects:atIndexes:] and let NSArray do the
         hard work of index-munging.
         */
        typedef void(^Enumerator)(NSInteger section,
                                  NSIndexSet *indexes,
                                  NSArray *objects,
                                  CKArrayControllerChangeType type,
                                  BOOL *stop);

      private:
        friend class Changeset;

        typedef std::map<NSInteger, id<NSObject>> ItemIndexToObjectMap;
        typedef std::map<NSInteger, ItemIndexToObjectMap> ItemsBucketizedBySection;

        void bucketizeObjectBySection(ItemsBucketizedBySection &m, const IndexPath &indexPath, id<NSObject> object);
        bool commandExistsForIndexPath(const IndexPath &indexPath,
                                       const std::vector<ItemsBucketizedBySection> &bucketsToCheck) const;

        ItemsBucketizedBySection _updates;
        ItemsBucketizedBySection _removals;
        ItemsBucketizedBySection _insertions;
      };

      class Changeset final {
      public:
        Changeset(const Sections &s) : items({}), sections(s) {}
        Changeset(const Items &i) : items(i), sections({}) {}
        Changeset(const Sections &s, const Items &i) : sections(s), items(i) {}
        ~Changeset();

        const Sections sections;
        const Items items;

        /**
         Called by FBSectionedArrayController. Enumeration vends "commands" that the array controller applies to its
         internal array-of-arrays.

         The order of block invocation allows us to apply these commands directly to the arrays without having to deal
         with adjusting/offsetting indexes or index paths.

         1) item updates
         2) item removals
         3) section removals
         4) section insertions
         5) item insertions

         Note that Items::Enumerate is invoked once for each section in which we need to insert/update/remove objects.
         If there are insertions into N sections it is invoked N times.
         */
        void enumerate(Sections::Enumerator sectionEnumerator, Items::Enumerator itemEnumerator) const;

        typedef id<NSObject> (^Mapper)(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop);

        Changeset map(Mapper mapper) const;

        bool operator==(const Changeset &other) const;
      };
    }
  }
}

namespace CK {

  namespace ArrayController {

    /**
     Only FBSectionedArrayController (and unit tests) should be constructing these. Client code is solely required to
     call CK::ArrayController::Output::Changeset::enumerate() (see below).
     */
    namespace Output {

      struct Pair {
        IndexPath indexPath;
        id<NSObject> object;

        Pair(const IndexPath &iP, id<NSObject> o) : indexPath(iP), object(o) {};

        bool operator==(const Pair &other) const {
          return indexPath == other.indexPath && FBObjectIsEqual(object, other.object);
        }
      };

      struct Change {
        IndexPath indexPath;
        id<NSObject> before;
        id<NSObject> after;

        Change(const IndexPath &iP, id<NSObject> b, id<NSObject> a) : indexPath(iP), before(b), after(a) {};

        bool operator==(const Change &other) const {
          return indexPath == other.indexPath && FBObjectIsEqual(before, other.before) && FBObjectIsEqual(after, other.after);
        }

        bool operator<(const Change &other) const {
          return indexPath < other.indexPath;
        }

        NSString *description() const {
          return [NSString stringWithFormat:@"indexPath: <%zd,%zd>, before: <%@>, after: <%@>", indexPath.section, indexPath.item, before, after];
        }
      };

      class Items final {
      public:
        void update(const Change &update);
        /**
         Note that we pass the removed object here, too. In doing so we can inform clients of what was removed as a
         result of an Input::Changeset
         */
        void remove(const Pair &removal);
        void insert(const Pair &insertion);

        typedef void(^Enumerator)(const Change &change,
                                  CKArrayControllerChangeType type,
                                  BOOL *stop);

        bool operator==(const Items &other) const;

      private:
        friend class Changeset;

        std::vector<Change> _updates;
        std::vector<Change> _removals;
        std::vector<Change> _insertions;
      };

      class Changeset final {
      public:
        Changeset(const Sections &s, const Items &i) : _sections(s), _items(i) {};

        /**
         Enumerates over section and item changes such that our mutation of a table view and collection view is trivial
         to implement.

         We follow a callback order identical to CK::ArrayController::Input::Changeset::enumerate().
         */
        void enumerate(Sections::Enumerator sectionsBlock,
                       Items::Enumerator itemsBlock) const;

        typedef std::pair<id<NSObject>, id<NSObject>> BeforeAfterPair;
        typedef BeforeAfterPair (^Mapper)(const Change &change, CKArrayControllerChangeType type, BOOL *stop);

        /**
         Enumerates over all the Change objects in the changeset and invokes Mapper on each. Returns a new instance
         of Changeset.

         Returns the receiver if mapper is NULL.
         */
        Changeset map(Mapper mapper) const;

        bool operator==(const Changeset &other) const;

        const Sections &getSections(void) const;

        NSString *description() const;

      private:
        Sections _sections;
        Items _items;
      };

    }

  }

}
