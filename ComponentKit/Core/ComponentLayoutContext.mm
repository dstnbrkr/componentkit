// Copyright 2004-present Facebook. All Rights Reserved.

#import "ComponentLayoutContext.h"

#import <pthread.h>
#import <stack>

#import <FBComponentKit/CKAssert.h>

using namespace FB::Component;

static pthread_key_t kFBComponentLayoutContextThreadKey;

struct ThreadKeyInitializer {
  static void destroyStack(LayoutContextStack *p) { delete p; }
  ThreadKeyInitializer() { pthread_key_create(&kFBComponentLayoutContextThreadKey, (void (*)(void*))destroyStack); }
};

static LayoutContextStack &componentStack()
{
  static ThreadKeyInitializer threadKey;
  LayoutContextStack *contexts = static_cast<LayoutContextStack *>(pthread_getspecific(kFBComponentLayoutContextThreadKey));
  if (!contexts) {
    contexts = new LayoutContextStack;
    pthread_setspecific(kFBComponentLayoutContextThreadKey, contexts);
  }
  return *contexts;
}

static void removeComponentStackForThisThread()
{
  LayoutContextStack *contexts = static_cast<LayoutContextStack *>(pthread_getspecific(kFBComponentLayoutContextThreadKey));
  ThreadKeyInitializer::destroyStack(contexts);
  pthread_setspecific(kFBComponentLayoutContextThreadKey, nullptr);
}

LayoutContext::LayoutContext(FBComponent *c, FBSizeRange r) : component(c), sizeRange(r)
{
  auto &stack = componentStack();
  stack.push_back(this);
}

LayoutContext::~LayoutContext()
{
  auto &stack = componentStack();
  CKCAssert(stack.back() == this,
            @"Last component layout context %@ is not %@", stack.back()->component, component);
  stack.pop_back();
  if (stack.empty()) {
    removeComponentStackForThisThread();
  }
}

const FB::Component::LayoutContextStack &LayoutContext::currentStack()
{
  return componentStack();
}

NSString *LayoutContext::currentStackDescription()
{
  const auto &stack = componentStack();
  NSMutableString *s = [NSMutableString string];
  NSUInteger idx = 0;
  for (FB::Component::LayoutContext *c : stack) {
    if (idx != 0) {
      [s appendString:@"\n"];
    }
    [s appendString:[@"" stringByPaddingToLength:idx withString:@" " startingAtIndex:0]];
    [s appendString:NSStringFromClass([c->component class])];
    [s appendString:@": "];
    [s appendString:c->sizeRange.description()];
    idx++;
  }
  return s;
}
