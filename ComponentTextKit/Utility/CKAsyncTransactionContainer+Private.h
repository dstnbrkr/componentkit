// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/CKAsyncTransactionContainer.h>

@interface CALayer (CKAsyncTransactionContainerTransactions)
@property (nonatomic, retain, setter = ck_setAsyncLayerTransactions:) NSHashTable *ck_asyncLayerTransactions;
@property (nonatomic, retain, setter = ck_setCurrentAsyncLayerTransaction:) CKAsyncTransaction *ck_currentAsyncLayerTransaction;

- (void)ck_asyncTransactionContainerWillBeginTransaction:(CKAsyncTransaction *)transaction;
- (void)ck_asyncTransactionContainerDidCompleteTransaction:(CKAsyncTransaction *)transaction;
@end
