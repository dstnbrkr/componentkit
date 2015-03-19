// Copyright 2004-present Facebook. All Rights Reserved.

#import <UIKit/UIKit.h>

#import <FBComponentKit/FBComponentViewAttribute.h>

@class FBComponent;

/**
 A component action is simply a selector. The selector may optionally take one argument: the sending component.

 Component actions provide a way for components to communicate to supercomponents using FBComponentActionSend. Since
 components are in the responder chain, the message will reach its supercomponents.
 */
typedef SEL FBComponentAction;

typedef NS_ENUM(NSUInteger, FBComponentActionSendBehavior) {
  /** Starts searching at the sender's next responder. Usually this is what you want to prevent infinite loops. */
  FBComponentActionSendBehaviorStartAtSenderNextResponder,
  /** If the sender itself responds to the action, invoke the action on the sender. */
  FBComponentActionSendBehaviorStartAtSender,
};

/**
 Sends a component action up the responder chain by crawling up the responder chain until it finds a responder that
 responds to the action's selector, then invokes it.

 @param action The action to send up the responder chain.
 @param sender The component sending the action. Traversal starts from the component itself, then its next responder.
 @param context An optional context-dependent second parameter to the component action. Defaults to nil.
 @param behavior @see FBComponentActionSendBehavior
 */
void FBComponentActionSend(FBComponentAction action, FBComponent *sender, id context = nil,
                           FBComponentActionSendBehavior behavior = FBComponentActionSendBehaviorStartAtSenderNextResponder);

/**
 Returns a view attribute that configures a component that creates a UIControl to send the given FBComponentAction.
 You can use this with e.g. FBButtonComponent.

 @param action Sent up the responder chain when an event occurs. Sender is the component that created the UIControl.
        The context parameter is always nil.
 @param controlEvents The events that should result in the action being sent. Default is touch up inside.
 */
FBComponentViewAttributeValue FBComponentActionAttribute(FBComponentAction action,
                                                         UIControlEvents controlEvents = UIControlEventTouchUpInside);

