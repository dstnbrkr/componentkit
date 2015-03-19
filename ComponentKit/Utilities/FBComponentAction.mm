// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBComponentAction.h"

#import <unordered_map>

#import <FBComponentKit/CKAssert.h>

#import "CKMutex.h"
#import "FBComponent.h"
#import "FBComponentViewInterface.h"

// This method returns a friendly-print of a responder chain. Used for debug purposes.
static NSString *_debugResponderChain(id responder) {
  if (!responder) {
    return @"nil";
  } else {
    return [NSString stringWithFormat:@"%@ -> %@", responder, _debugResponderChain([responder nextResponder])];
  }
}

void FBComponentActionSend(FBComponentAction action, FBComponent *sender, id context, FBComponentActionSendBehavior behavior)
{
  id initialResponder = (behavior == FBComponentActionSendBehaviorStartAtSender) ? sender : [sender nextResponder];
  id responder = [initialResponder targetForAction:action withSender:sender];
  CKCAssertNotNil(responder, @"Unhandled component action %@ following responder chain %@",
                  NSStringFromSelector(action), _debugResponderChain(sender));

  // ARC is worried that the selector might have a return value it doesn't know about, or be annotated with ns_consumed.
  // Neither is the case for our action handlers, so ignore the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [responder performSelector:action withObject:sender withObject:context];
#pragma clang diagnostic pop
}

@interface FBComponentActionControlForwarder : NSObject
- (instancetype)initWithAction:(FBComponentAction)action;
- (void)handleControlEventFromSender:(UIControl *)sender;
@end

typedef std::unordered_map<FBComponentAction, FBComponentActionControlForwarder *> ForwarderMap;

FBComponentViewAttributeValue FBComponentActionAttribute(FBComponentAction action,
                                                         UIControlEvents controlEvents)
{
  CKCAssertNotNil(action, @"Can't pass a NULL action to FBComponentActionAttribute");

  static ForwarderMap *map = new ForwarderMap(); // never destructed to avoid static destruction fiasco
  static CK::StaticMutex lock = CK_MUTEX_INITIALIZER;   // protects map

  // We need a target for the control event. (We can't use the responder chain because we need to jump in and change the
  // sender from the UIControl to the FBComponent.)
  // Control event targets are __unsafe_unretained. We can't rely on the block to keep the target alive, since the block
  // is merely an "applicator"; if the attributes compare the same (say, two equivalent attributes used across two
  // versions of the same component) then the block may be deallocated on the first one without removing the attribute.
  // Thus we create a map from component action to forwarders and never release the forwarders.
  // If this turns out to have memory overhead, we could capture a "token" in the blocks and have those tokens as ref-
  // counts on the forwarder, and when the number of outstanding tokens goes to zero, release the forwarder.
  // However I expect the number of actions to be O(200) at most and so the memory overhead is not a concern.
  FBComponentActionControlForwarder *forwarder;
  {
    CK::StaticMutexLocker l(lock);
    auto it = map->find(action);
    if (it == map->end()) {
      forwarder = [[FBComponentActionControlForwarder alloc] initWithAction:action];
      map->insert({action, forwarder});
    } else {
      forwarder = it->second;
    }
  }

  std::string identifier = std::string("FBComponentActionAttribute-")
                         + std::string(sel_getName(action))
                         + "-" + std::to_string(controlEvents);
  return {
    {
      identifier,
      ^(UIControl *control, id value){
        [control addTarget:forwarder
                    action:@selector(handleControlEventFromSender:)
          forControlEvents:controlEvents];
      },
      ^(UIControl *control, id value){
        [control removeTarget:forwarder
                       action:@selector(handleControlEventFromSender:)
             forControlEvents:controlEvents];
      }
    },
    // Use a bogus value for the attribute's "value". All the information is encoded in the attribute itself.
    @YES
  };
}

@implementation FBComponentActionControlForwarder
{
  FBComponentAction _action;
}

- (instancetype)initWithAction:(FBComponentAction)action
{
  if (self = [super init]) {
    _action = action;
  }
  return self;
}

- (void)handleControlEventFromSender:(UIControl *)sender
{
  // If the action can be handled by the sender itself, send it there instead of looking up the chain.
  FBComponentActionSend(_action, sender.fb_component, nil, FBComponentActionSendBehaviorStartAtSender);
}

@end
