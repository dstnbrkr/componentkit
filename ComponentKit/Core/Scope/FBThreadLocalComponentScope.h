// Copyright 2004-present Facebook. All Rights Reserved.

#import <stack>

#import <Foundation/Foundation.h>

#import <FBComponentKit/CKAssert.h>

@class FBComponentScopeFrame;
@protocol FBComponentStateListener;

class FBComponentScopeCursor {
  struct FBComponentScopeCursorFrame {
    FBComponentScopeFrame *frame;
    FBComponentScopeFrame *equivalentPreviousFrame;
  };

  std::stack<FBComponentScopeCursorFrame> _frames;
 public:
  /** Push a new frame onto both state-trees. */
  void pushFrameAndEquivalentPreviousFrame(FBComponentScopeFrame *frame, FBComponentScopeFrame *equivalentPreviousFrame);

  /** Pop off one frame on both state trees.  */
  void popFrame();

  FBComponentScopeFrame *currentFrame() const;
  FBComponentScopeFrame *equivalentPreviousFrame() const;

  bool empty() const { return _frames.empty(); }
};

class FBThreadLocalComponentScope {
public:
  FBThreadLocalComponentScope(id<FBComponentStateListener> listener, FBComponentScopeFrame *previousRootFrame);
  ~FBThreadLocalComponentScope() throw(...);

  static FBComponentScopeCursor *cursor();
};
