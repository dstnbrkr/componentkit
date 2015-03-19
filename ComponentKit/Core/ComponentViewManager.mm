// Copyright 2004-present Facebook. All Rights Reserved.

#include "ComponentViewManager.h"

#import <objc/runtime.h>
#import <unordered_map>

#import "CKMutex.h"

#import <FBComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"
#import "CKMutex.h"
#import "ComponentUtilities.h"
#import "ComponentViewReuseUtilities.h"
#import "FBComponentInternal.h"
#import "FBComponentSubclass.h"
#import "FBComponentViewConfiguration.h"
#import "FBOptimisticViewMutations.h"

using namespace FB::Component;

namespace FB {
  namespace Component {
    struct PersistentAttributeShapeKey {
      /** Identifiers in sorted order. For the small sizes we use, this is faster than set or unordered_set. */
      std::vector<std::string> identifiers;
      /** Cumulative hash of all identifiers */
      size_t hash;

      /** Initialize the hash field to 0; remember that C++ doesn't initialize POD fields by default. */
      PersistentAttributeShapeKey() : hash(0) {};

      void addString(const std::string &s)
      {
        identifiers.insert(std::lower_bound(identifiers.begin(), identifiers.end(), s), s);
        // XOR'ing hashes is often a bad idea. Two of the reasons why are that two identical values will cancel each
        // other out, and that ordering information is lost (a ^ b == b ^ a). Since we don't expect identical values and
        // ordering doesn't matter (indeed *must not* matter), go ahead and use XOR here.
        hash ^= std::hash<std::string>()(s);
      }

      bool operator==(const FB::Component::PersistentAttributeShapeKey &k) const
      {
        return identifiers == k.identifiers;
      }
    };
  }
}

namespace std {
  template <> struct hash<const FB::Component::PersistentAttributeShapeKey>
  {
    size_t operator()(const FB::Component::PersistentAttributeShapeKey &k) const { return k.hash; }
  };
}

int32_t PersistentAttributeShape::computeIdentifier(const FBViewComponentAttributeValueMap &attributes)
{
  FB::Component::PersistentAttributeShapeKey key;
  for (const auto &it : attributes) {
    if (it.first.unapplicator == nil) {
      key.addString(it.first.identifier);
    }
  }

  static CK::StaticMutex lock = CK_MUTEX_INITIALIZER; // protects identifierMap
  CK::StaticMutexLocker l(lock);
  static auto *identifierMap = new std::unordered_map<const FB::Component::PersistentAttributeShapeKey, const int32_t>();

  static int32_t nextIdentifier = 0;
  const auto it = identifierMap->find(key);
  if (it == identifierMap->end()) {
    // We don't need fancy OSAtomicIncrement64 here because we're already under the StaticMutex (for identifierMap).
    int32_t identifier = nextIdentifier++;
    identifierMap->emplace(std::move(key), identifier);
    return identifier;
  } else {
    return it->second;
  }
}

@interface FBComponentAttributeSetWrapper : NSObject
{
@public
  std::shared_ptr<const FBViewComponentAttributeValueMap> _attributes;
}
@end

@interface FBComponentViewReusePoolMapWrapper : NSObject {
@public
  ViewReusePoolMap _viewReusePoolMap;
}
@end

UIView *ViewReusePool::viewForClass(const FBComponentViewClass &viewClass, UIView *container)
{
  if (position == pool.end()) {
    UIView *v = viewClass.createView();
    CKCAssertNotNil(v, @"Expected non-nil view to be created for view class %s", viewClass.getIdentifier().c_str());
    [container addSubview:v];
    pool.push_back(v);
    position = pool.end();
    ViewReuseUtilities::createdView(v, viewClass, container);
    return v;
  } else {
    return *position++;
  }
}

void ViewReusePool::reset()
{
  for (auto it = pool.begin(); it != position; ++it) {
    ViewReuseUtilities::willUnhide(*it);
    [*it setHidden:NO];
  }
  for (auto it = position; it != pool.end(); ++it) {
    [*it setHidden:YES];
    ViewReuseUtilities::didHide(*it);
  }
  position = pool.begin();
}

const char kComponentViewReusePoolMapAssociatedObjectKey = ' ';

ViewReusePoolMap &ViewReusePoolMap::viewReusePoolMapForView(UIView *v)
{
  FBComponentViewReusePoolMapWrapper *wrapper = objc_getAssociatedObject(v, &kComponentViewReusePoolMapAssociatedObjectKey);
  if (!wrapper) {
    wrapper = [[FBComponentViewReusePoolMapWrapper alloc] init];
    objc_setAssociatedObject(v, &kComponentViewReusePoolMapAssociatedObjectKey, wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return wrapper->_viewReusePoolMap;
}

void ViewReusePoolMap::reset(UIView *container)
{
  for (auto &it : map) {
    it.second.reset();
  }

  // Now we need to ensure that the ordering of container.subviews matches vendedViews.
  NSMutableArray *subviews = [[container subviews] mutableCopy];
  std::vector<UIView *>::const_iterator nextVendedViewIt = vendedViews.cbegin();

  // Can't use NSFastEnumeration since we mutate subviews during enumeration.
  for (NSUInteger i = 0; i < [subviews count]; i++) {
    UIView *subview = subviews[i];

    // We use linear search here. We could create a std::unordered_set of vended views, but given the typical size of
    // the list of vended views, I guessed a linear search would probably be faster considering constant factors.
    const auto &vendedViewIt = std::find(nextVendedViewIt, vendedViews.cend(), subview);

    if (vendedViewIt == vendedViews.cend()) {
      // Ignore subviews not created by components infra, or that were not vended during this pass (they are hidden).
      continue;
    }

    if (vendedViewIt != nextVendedViewIt) {
      NSUInteger swapIndex = [subviews indexOfObjectIdenticalTo:*nextVendedViewIt];
      CKCAssert(swapIndex != NSNotFound, @"Expected to find subview %@ in %@",
                [*nextVendedViewIt class], [container class]);

      // This naive algorithm does not do the minimal number of swaps. But it's simple, and swaps should be relatively
      // rare in any case, so let's go with it.
      [subviews exchangeObjectAtIndex:i withObjectAtIndex:swapIndex];
      [container exchangeSubviewAtIndex:i withSubviewAtIndex:swapIndex];
    }

    ++nextVendedViewIt;
  }

  vendedViews.clear();
}

UIView *ViewReusePoolMap::viewForConfiguration(Class componentClass,
                                               const FBComponentViewConfiguration &config,
                                               UIView *container)
{
  if (!config.viewClass().hasView()) {
    return nil;
  }

  const Component::ViewKey key = {
    componentClass,
    config.viewClass().getIdentifier(),
    config.rep->attributeShape
  };
  // Note that operator[] creates a new ViewReusePool if one doesn't exist yet. This is what we want.
  UIView *v = map[key].viewForClass(config.viewClass(), container);
  vendedViews.push_back(v);
  return v;
}

UIView *ViewManager::viewForConfiguration(Class componentClass, const FBComponentViewConfiguration &config)
{
  return viewReusePoolMap.viewForConfiguration(componentClass, config, view);
}

static char kPersistentAttributesViewKey = ' ';

void AttributeApplicator::apply(UIView *view, const FBComponentViewConfiguration &config)
{
  // Reset optimistic mutations so that applicators see they see the state they expect.
  FBResetOptimisticMutationsForView(view);

  // Why a pointer? https://our.intern.facebook.com/intern/dex/qa/657083164365634/
  static const auto *empty = new FBViewComponentAttributeValueMap();

  FBComponentAttributeSetWrapper *wrapper = objc_getAssociatedObject(view, &kPersistentAttributesViewKey);
  if (wrapper == nil) {
    wrapper = [[FBComponentAttributeSetWrapper alloc] init];
    objc_setAssociatedObject(view, &kPersistentAttributesViewKey,
                             wrapper,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  const FBViewComponentAttributeValueMap &oldAttributes = wrapper->_attributes ? *wrapper->_attributes : *empty;
  const FBViewComponentAttributeValueMap &newAttributes = *config.attributes();

  // First, tear down any attributes that appear in the *old* set but not the new set, and *do* have an unapplicator.
  for (const auto &oldAttr : oldAttributes) {
    if (oldAttr.first.unapplicator) {
      const auto &newAttr = newAttributes.find(oldAttr.first);
      if (newAttr == newAttributes.end()) {
        // There is no new attribute, so we always must call "unapplicator".
        oldAttr.first.unapplicator(view, oldAttr.second);
      } else if (!CKObjectIsEqual(newAttr->second, oldAttr.second)) {
        // If the attribute has an updater, don't call the unapplicator; instead, the updater will be called below.
        if (newAttr->first.updater == nil) {
          oldAttr.first.unapplicator(view, oldAttr.second);
        }
      }
    }
  }

  // Now apply the applicators for all attributes in the *new* set, except those that haven't changed in value.
  for (const auto &newAttr : newAttributes) {
    const auto &oldAttr = oldAttributes.find(newAttr.first);
    if (oldAttr == oldAttributes.end()) {
      // There is no old attribute, so we always must call "applicator".
      newAttr.first.applicator(view, newAttr.second);
    } else if (!CKObjectIsEqual(oldAttr->second, newAttr.second)) {
      // If the attribute has an "updater", call that. Otherwise, call the applicator.
      if (newAttr.first.updater) {
        newAttr.first.updater(view, oldAttr->second, newAttr.second);
      } else {
        newAttr.first.applicator(view, newAttr.second);
      }
    }
  }

  // Update the wrapper to reference the new attributes. Don't do this before now since it changes oldAttributes.
  wrapper->_attributes = config.attributes();
}

@implementation FBComponentAttributeSetWrapper
@end

@implementation FBComponentViewReusePoolMapWrapper
@end
