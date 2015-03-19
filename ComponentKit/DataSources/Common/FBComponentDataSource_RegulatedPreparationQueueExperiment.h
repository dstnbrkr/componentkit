// Copyright 2004-present Facebook. All Rights Reserved.

@interface FBComponentDataSource(RegulatedPreparationQueueExperimentContext)

- (instancetype)initWithComponentProvider:(Class<FBComponentProvider>)componentProvider
                                  context:(id<NSObject>)context
                                  decider:(id<FBComponentDeciding>)decider
                    preparationQueueWidth:(NSUInteger)preparationQueueWidth;
@end
