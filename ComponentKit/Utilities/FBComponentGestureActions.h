// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#import <FBComponentKit/FBComponentAction.h>

typedef void (*FBComponentGestureRecognizerSetupFunction)(UIGestureRecognizer *);

/**
 Returns a view attribute that creates and configures a tap gesture recognizer to send the given FBComponentAction.

 @param action Sent up the responder chain when a tap occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
FBComponentViewAttributeValue FBComponentTapGestureAttribute(FBComponentAction action);

/**
 Returns a view attribute that creates and configures a pan gesture recognizer to send the given FBComponentAction.

 @param action Sent up the responder chain when a pan occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
FBComponentViewAttributeValue FBComponentPanGestureAttribute(FBComponentAction action);

/**
 Returns a view attribute that creates and configures a long press gesture recognizer to send the given FBComponentAction.

 @param action Sent up the responder chain when a long press occurs. Sender is the component that created the view.
        Context is the gesture recognizer.
 */
FBComponentViewAttributeValue FBComponentLongPressGestureAttribute(FBComponentAction action);

/**
 Returns a view attribute that creates and configures a gesture recognizer.

 @param gestureRecognizerClass Must be a subclass of UIGestureRecognizer. Instantiated with -initWithTarget:action:.
 @param setupFunction Optional; pass nullptr if not needed. Called once for each new gesture recognizer; you may use
        this function to configure the new gesture recognizer.
 @param action Sent up the responder chain when the gesture recognizer recognizes a gesture. Sender is the component
        that created the view. Context is the gesture recognizer.
 */
FBComponentViewAttributeValue FBComponentGestureAttribute(Class gestureRecognizerClass,
                                                          FBComponentGestureRecognizerSetupFunction setupFunction,
                                                          FBComponentAction action);
