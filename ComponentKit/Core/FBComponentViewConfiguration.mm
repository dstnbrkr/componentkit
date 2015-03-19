// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentViewConfiguration.h"

#import <objc/runtime.h>

#import <FBComponentKit/CKAssert.h>

#import "CKInternalHelpers.h"

FBComponentViewClass::FBComponentViewClass() : factory(nil) {}

FBComponentViewClass::FBComponentViewClass(Class viewClass) :
identifier(class_getName(viewClass)),
factory(^{return [[viewClass alloc] init];}) {}

static FBComponentViewReuseBlock blockFromSEL(SEL sel)
{
  if (sel) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return ^(UIView *v){ [v performSelector:sel]; };
#pragma clang diagnostic pop
  }
  return nil;
}

FBComponentViewClass::FBComponentViewClass(Class viewClass, SEL enter, SEL leave) :
identifier(std::string(class_getName(viewClass)) + "-" + sel_getName(enter) + "-" + sel_getName(leave)),
factory(^{return [[viewClass alloc] init];}),
didEnterReusePool(blockFromSEL(enter)),
willLeaveReusePool(blockFromSEL(leave)) {}

FBComponentViewClass::FBComponentViewClass(UIView *(*fact)(void),
                                           void (^enter)(UIView *),
                                           void (^leave)(UIView *))
: identifier(CKStringFromPointer((const void *)fact)), factory(^UIView*(void) {return fact();}), didEnterReusePool(enter), willLeaveReusePool(leave)
{
}

FBComponentViewClass::FBComponentViewClass(const std::string &i,
                                           UIView *(^fact)(void),
                                           void (^enter)(UIView *),
                                           void (^leave)(UIView *))
: identifier(i), factory(fact), didEnterReusePool(enter), willLeaveReusePool(leave)
{
#if DEBUG
  CKCAssertNil(objc_getClass(i.c_str()), @"You may not use a class name as the identifier; it would conflict with "
               "the constructor variant that takes a viewClass.");
#endif
}

// It would be ideal to use std::unique_ptr here and give this class move semantics, but it already has value semantics
// and there are a few complicated flows.
std::shared_ptr<const FBComponentViewConfiguration::Repr> FBComponentViewConfiguration::singletonViewConfiguration()
{
  static std::shared_ptr<const FBComponentViewConfiguration::Repr> p = FBComponentViewConfiguration(FBComponentViewClass()).rep;
  return p;
}

FBComponentViewConfiguration::FBComponentViewConfiguration()
  :rep(singletonViewConfiguration()) {}

// Prefer overloaded constructors to default arguments to prevent code bloat; with default arguments
// the compiler must insert initialization of each default value inline at the callsite.
FBComponentViewConfiguration::FBComponentViewConfiguration(
    FBComponentViewClass &&cls,
    FBViewComponentAttributeValueMap &&attrs)
: FBComponentViewConfiguration(std::move(cls), std::move(attrs), {}) {}

FBComponentViewConfiguration::FBComponentViewConfiguration(FBComponentViewClass &&cls,
                                                           FBViewComponentAttributeValueMap &&attrs,
                                                           FBComponentAccessibilityContext &&accessibilityCtx)
{
  // Need to use attrs before we move it below.
  FB::Component::PersistentAttributeShape attributeShape(attrs);
  rep.reset(new Repr({
    .viewClass = std::move(cls),
    .attributes = std::make_shared<FBViewComponentAttributeValueMap>(std::move(attrs)),
    .accessibilityContext = std::move(accessibilityCtx),
    .attributeShape = std::move(attributeShape)}));
}

// Constructors and destructors are defined out-of-line to prevent code bloat.
FBComponentViewConfiguration::~FBComponentViewConfiguration() {}

bool FBComponentViewConfiguration::operator==(const FBComponentViewConfiguration &other) const
{
  if (other.rep == rep) {
    return true;
  }
  if (!(other.rep->attributeShape == rep->attributeShape
        && other.rep->viewClass == rep->viewClass
        && other.rep->accessibilityContext == rep->accessibilityContext)) {
    return false;
  }

  const auto &otherAttributes = other.rep->attributes;
  if (otherAttributes == rep->attributes) {
    return true;
  } else if (otherAttributes->size() == rep->attributes->size()) {
    return std::find_if(rep->attributes->begin(),
                        rep->attributes->end(),
                        [&](std::pair<const FBComponentViewAttribute &, id> elem) {
                          const auto otherElem = otherAttributes->find(elem.first);
                          return otherElem == otherAttributes->end() || !CKObjectIsEqual(otherElem->second, elem.second);
                        }) == rep->attributes->end();
  } else {
    return false;
  }
}

const FBComponentViewClass &FBComponentViewConfiguration::viewClass() const
{
  return rep->viewClass;
}

std::shared_ptr<const FBViewComponentAttributeValueMap> FBComponentViewConfiguration::attributes() const
{
  return rep->attributes;
}

const FBComponentAccessibilityContext &FBComponentViewConfiguration::accessibilityContext() const
{
  return rep->accessibilityContext;
}

UIView *FBComponentViewClass::createView() const
{
  return factory ? factory() : nil;
}

BOOL FBComponentViewClass::hasView() const
{
  return factory != nil;
}
