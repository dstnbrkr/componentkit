// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBThreadLocalComponentScope.h"

#import <pthread.h>
#import <stack>

#import <FBComponentKit/CKAssert.h>

#import "FBComponentScopeFrame.h"
#import "FBComponentScopeInternal.h"

void FBComponentScopeCursor::pushFrameAndEquivalentPreviousFrame(FBComponentScopeFrame *frame, FBComponentScopeFrame *equivalentFrame)
{
  _frames.push({frame, equivalentFrame});
}

void FBComponentScopeCursor::popFrame()
{
  _frames.pop();
}

FBComponentScopeFrame *FBComponentScopeCursor::currentFrame() const
{
  return _frames.empty() ? nullptr :  _frames.top().frame;
}

FBComponentScopeFrame *FBComponentScopeCursor::equivalentPreviousFrame() const
{
  return _frames.empty() ? nullptr : _frames.top().equivalentPreviousFrame;
}

static pthread_key_t thread_key;
static pthread_once_t key_once = PTHREAD_ONCE_INIT;

static void _valueDestructor(void *context)
{
  FBComponentScopeCursor *ptr = (FBComponentScopeCursor *)context;
  delete ptr;
}

static void _makeThreadKey()
{
  (void)pthread_key_create(&thread_key, _valueDestructor);
}

FBComponentScopeCursor *FBThreadLocalComponentScope::cursor()
{
  // Return the TLS, allocating if this is the first time through.
  (void)pthread_once(&key_once, _makeThreadKey);
  FBComponentScopeCursor *cursor = (FBComponentScopeCursor *)pthread_getspecific(thread_key);
  if (!cursor) {
    cursor = new FBComponentScopeCursor;
    pthread_setspecific(thread_key, cursor);
  }
  return cursor;
}

FBThreadLocalComponentScope::FBThreadLocalComponentScope(id<FBComponentStateListener> listener,
                                                         FBComponentScopeFrame *previousRootFrame)
{
  CKCAssert(cursor()->empty(), @"FBThreadLocalStateScope already exists. You cannot create two at the same time.");
  cursor()->pushFrameAndEquivalentPreviousFrame([FBComponentScopeFrame rootFrameWithListener:listener], previousRootFrame);
}

FBThreadLocalComponentScope::~FBThreadLocalComponentScope() throw(...)
{
  cursor()->popFrame();
  CKCAssert(cursor()->empty(), @"");
}
