// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#define CKArgumentPreconditionCheckIf(condition, message) do { if (!(condition)) { @throw [NSException exceptionWithName:NSInvalidArgumentException reason:(message) userInfo:nil]; } } while (0)

#define CKInternalConsistencyCheckIf(condition, message) do { if (!(condition)) { @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:(message) userInfo:nil]; } } while (0)
