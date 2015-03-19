// Copyright 2004-present Facebook. All Rights Reserved.

#import <string>
#import <unordered_map>

#import <UIKit/UIKit.h>

#import <FBComponentKit/ComponentMountContext.h>
#import <FBComponentKit/ComponentViewManager.h>
#import <FBComponentKit/ComponentViewReuseUtilities.h>
#import <FBComponentKit/FBComponentAccessibility.h>
#import <FBComponentKit/FBComponentViewAttribute.h>

class FBComponentDebugConfiguration;

typedef void (^FBComponentViewReuseBlock)(UIView *);

struct FBComponentViewClass {

  /**
   The no-argument default constructor, which specifies that the component should not have a corresponding view.
   */
  FBComponentViewClass();

  /**
   Specifies that the component should have a view of the given class. The class will be instantiated with UIView's
   designated initializer -initWithFrame:.
   */
  FBComponentViewClass(Class viewClass);

  /**
   A variant that allows you to specify two selectors that are sent as a view is reused.
   @param didEnterReusePoolMessage Sent to the view just after it has been hidden for future reuse.
   @param willLeaveReusePool Sent to the view just before it is revealed after being reused.
   */
  FBComponentViewClass(Class viewClass, SEL didEnterReusePoolMessage, SEL willLeaveReusePoolMessage);

  /**
   Specifies a view class that cannot be instantiated with -initWithFrame:.
   @param factory A pointer to a function that returns a new instance of a view.
   @param didEnterReusePool Executed after a view has been hidden for future reuse.
   @param willLeaveReusePool Executed just before a view is revealed after being reused.
   */
  FBComponentViewClass(UIView *(*factory)(void),
                       FBComponentViewReuseBlock didEnterReusePool = nil,
                       FBComponentViewReuseBlock willLeaveReusePool = nil);

  /**
   Soon to be deprecated and removed constructor using a string indentifier and block-based view factory.
   Preferred constructor (located right above this comment) uses pure C function,
   since that makes accidental object capture and incorrect view reuse much harder.
   */
  FBComponentViewClass(const std::string &ident,
                       UIView *(^factory)(void),
                       FBComponentViewReuseBlock didEnterReusePool = nil,
                       FBComponentViewReuseBlock willLeaveReusePool = nil);

  /** Invoked by the infrastructure to create a new instance of the view. You should not call this directly. */
  UIView *createView() const;

  /** Invoked by the infrastructure to determine if this will create a view or not. */
  BOOL hasView() const;

  bool operator==(const FBComponentViewClass &other) const { return other.identifier == identifier; }
  bool operator!=(const FBComponentViewClass &other) const { return other.identifier != identifier; }

  const std::string &getIdentifier() const { return identifier; }
private:
  std::string identifier;
  UIView *(^factory)(void);
  FBComponentViewReuseBlock didEnterReusePool;
  FBComponentViewReuseBlock willLeaveReusePool;
  friend class FB::Component::ViewReuseUtilities;
};

namespace std {
  template<> struct hash<FBComponentViewClass>
  {
    size_t operator()(const FBComponentViewClass &cl) const
    {
      return hash<std::string>()(cl.getIdentifier());
    }
  };
}

/**
 A FBComponentViewConfiguration specifies the class of a view and the attributes that should be applied to it.
 Initialize a configuration with brace syntax, for example:

 {[UIView class]}
 {[UIView class], {{@selector(setBackgroundColor:), [UIColor redColor]}, {@selector(setAlpha:), @0.5}}}
 */
struct FBComponentViewConfiguration {

  FBComponentViewConfiguration();

  FBComponentViewConfiguration(FBComponentViewClass &&cls,
                               FBViewComponentAttributeValueMap &&attrs = {});

  FBComponentViewConfiguration(FBComponentViewClass &&cls,
                               FBViewComponentAttributeValueMap &&attrs,
                               FBComponentAccessibilityContext &&accessibilityCtx);

  ~FBComponentViewConfiguration();
  bool operator==(const FBComponentViewConfiguration &other) const;

  const FBComponentViewClass &viewClass() const;
  std::shared_ptr<const FBViewComponentAttributeValueMap> attributes() const;
  const FBComponentAccessibilityContext &accessibilityContext() const;

private:
  struct Repr {
    FBComponentViewClass viewClass;
    std::shared_ptr<const FBViewComponentAttributeValueMap> attributes;
    FBComponentAccessibilityContext accessibilityContext;
    FB::Component::PersistentAttributeShape attributeShape;
  };

  static std::shared_ptr<const Repr> singletonViewConfiguration();
  std::shared_ptr<const Repr> rep; // const is important for the singletonViewConfiguration optimization.

  friend class FB::Component::ViewReusePoolMap;    // uses attributeShape
};
