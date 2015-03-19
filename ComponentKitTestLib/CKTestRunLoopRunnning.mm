// Copyright 2004-present Facebook. All Rights Reserved.

#import "CKTestRunLoopRunnning.h"

#import <QuartzCore/QuartzCore.h>

#import <libkern/OSAtomic.h>

// Poll the condition 1000 times a second.
static CFTimeInterval kSingleRunLoopTimeout = 0.001;

// Time out after 30 seconds.
static CFTimeInterval kTimeoutInterval = 30.0f;

BOOL CKRunRunLoopUntilBlockIsTrue(BOOL (^block)(void))
{
  CFTimeInterval timeoutDate = CACurrentMediaTime() + kTimeoutInterval;
  BOOL passed = NO;
  while (true) {
    OSMemoryBarrier();
    passed = block();
    OSMemoryBarrier();
    if (passed) {
      break;
    }
    CFTimeInterval now = CACurrentMediaTime();
    if (now > timeoutDate) {
      break;
    }
    // Run until the poll timeout or until timeoutDate, whichever is first.
    CFTimeInterval runLoopTimeout = MIN(kSingleRunLoopTimeout, timeoutDate - now);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, runLoopTimeout, true);
  }
  return passed;
}
