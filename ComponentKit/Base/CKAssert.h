// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#define CKAssert(condition, description, ...) NSAssert(condition, description, ##__VA_ARGS__)
#define CKCAssert(condition, description, ...) NSCAssert(condition, description, ##__VA_ARGS__)

#define CKAssertNil(condition, description, ...) CKAssert(!(condition), (description), ##__VA_ARGS__)
#define CKCAssertNil(condition, description, ...) CKCAssert(!(condition), (description), ##__VA_ARGS__)

#define CKAssertNotNil(condition, description, ...) CKAssert((condition), (description), ##__VA_ARGS__)
#define CKCAssertNotNil(condition, description, ...) CKCAssert((condition), (description), ##__VA_ARGS__)

#define CKAssertTrue(condition) CKAssert((condition), nil, nil)
#define CKCAssertTrue(condition) CKCAssert((condition), nil, nil)

#define CKAssertFalse(condition) CKAssert(!(condition), nil, nil)
#define CKCAssertFalse(condition) CKCAssert(!(condition), nil, nil)

#define CKAssertMainThread() CKAssert([NSThread isMainThread], nil, @"This method must be called on the main thread")
#define CKCAssertMainThread() CKCAssert([NSThread isMainThread], nil, @"This method must be called on the main thread")

#define CKFailAssert(description, ...) CKAssert(NO, nil, (description), ##__VA_ARGS__)
#define CKCFailAssert(description, ...) CKCAssert(NO, nil, (description), ##__VA_ARGS__)
