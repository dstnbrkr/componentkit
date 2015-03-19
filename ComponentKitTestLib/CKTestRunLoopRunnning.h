// Copyright 2004-present Facebook. All Rights Reserved.

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 Runs the current thread's run loop until the block returns YES or a timeout is reached.  Returns YES if the block
 returns YES by the end of the timeout, NO otherwise.
 */
extern BOOL CKRunRunLoopUntilBlockIsTrue(BOOL (^block)(void));

#ifdef __cplusplus
}
#endif
