// Copyright 2004-present Facebook. All Rights Reserved.

#import <FBComponentKit/FBDimension.h>
#import <FBComponentKit/FBInsetComponent.h>

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#define CK_AT_LEAST_IOS7_1 (kCFCoreFoundationVersionNumber >= 847.24)
#define CK_AT_LEAST_IOS8 (kCFCoreFoundationVersionNumber > 847.27)

#if __LP64__
#define CK_64 1
#else
#define CK_64 0
#endif

@class FBComponent;

/**
 Similar to our much-loved XCTAssert() macros. Use this to perform your test. No need to write an explanation, though.
 @param component The component to snapshot
 @param sizeRange An FBSizeRange specifying the size the component should be mounted at
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define FBSnapshotVerifyComponent(component__, sizeRange__, identifier__) \
{ \
NSError *error__ = nil; \
NSString *referenceImagesDirectorySuffix__ = @""; \
if (CK_AT_LEAST_IOS8) { \
referenceImagesDirectorySuffix__ = @"_IOS8"; \
} else if (CK_AT_LEAST_IOS7_1) { \
referenceImagesDirectorySuffix__ = @"_IOS7.1"; \
} \
if (CK_64) referenceImagesDirectorySuffix__ = [referenceImagesDirectorySuffix__ stringByAppendingString:@"_64"]; \
NSString *referenceImagesDirectory__ = [NSString stringWithFormat:@"%s%@", FB_REFERENCE_IMAGE_DIR, referenceImagesDirectorySuffix__]; \
BOOL comparisonSuccess__ = [self compareSnapshotOfComponent:(component__) sizeRange:(sizeRange__) referenceImagesDirectory:referenceImagesDirectory__ identifier:(identifier__) error:&error__]; \
XCTAssertTrue(comparisonSuccess__, @"Snapshot comparison failed: %@", error__); \
}

/**
 A convenience macro for snapshotting a component with some additional insets so that borders/shadows can be captured.
 @param component The component to snapshot
 @param sizeRange An FBSizeRange specifying the size the component should be mounted at
 @param insets A UIEdgeInsets struct to specify the insets around the component being snapshotted.
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define FBSnapshotVerifyComponentWithInsets(component__, sizeRange__, insets__, identifier__) \
{ \
FBSnapshotVerifyComponent([FBInsetComponent newWithInsets:insets__ component:component__], sizeRange__, identifier__) \
}

/**
 Similar FBSnapshotVerifyComponent except it allows you to test a component with a particular state (i.e. FBComponentScope state).
 Rather than passing in a component, pass in a block that returns a component. Also, pass in a block that returns state.
 You need to pass in a block rather than just a component because the lifecycle manager creates a scope, and we need to defer
 creation of that component until after that scope exists.
 @param componentBlock A block that returns a component to snapshot
 @param updateStateBlock An update state block for the component. Returns the state you want the component to be tested with.
 @param sizeRange An FBSizeRange specifying the size the component should be mounted at
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define FBSnapshotVerifyComponentBlockWithState(componentBlock__, updateStateBlock__, sizeRange__, identifier__) \
{ \
NSError *error__ = nil; \
NSString *referenceImagesDirectorySuffix__ = @""; \
if (CK_AT_LEAST_IOS8) { \
referenceImagesDirectorySuffix__ = @"_IOS8"; \
} else if (CK_AT_LEAST_IOS7_1) { \
referenceImagesDirectorySuffix__ = @"_IOS7.1"; \
} \
if (CK_64) referenceImagesDirectorySuffix__ = [referenceImagesDirectorySuffix__ stringByAppendingString:@"_64"]; \
NSString *referenceImagesDirectory__ = [NSString stringWithFormat:@"%s%@", FB_REFERENCE_IMAGE_DIR, referenceImagesDirectorySuffix__]; \
BOOL comparisonSuccess__ = [self compareSnapshotOfComponentBlock:(componentBlock__) updateStateBlock:(updateStateBlock__) sizeRange:(sizeRange__) referenceImagesDirectory:referenceImagesDirectory__ identifier:(identifier__) error:&error__]; \
XCTAssertTrue(comparisonSuccess__, @"Snapshot comparison failed: %@", error__); \
}

@interface FBComponentSnapshotTestCase : FBSnapshotTestCase

/**
 Performs the comparison or records a snapshot of the view if recordMode is YES.
 @param component The component to snapshot
 @param referenceImagesDirectory The directory in which reference images are stored.
 @param identifier An optional identifier, used is there are muliptle snapshot tests in a given -test method.
 @param error An error to log in an XCTAssert() macro if the method fails (missing reference image, images differ, etc).
 @returns YES if the comparison (or saving of the reference image) succeeded.
 */
- (BOOL)compareSnapshotOfComponent:(FBComponent *)component
                         sizeRange:(FBSizeRange)sizeRange
          referenceImagesDirectory:(NSString *)referenceImagesDirectory
                        identifier:(NSString *)identifier
                             error:(NSError **)errorPtr;

/**
 Performs the comparison or records a snapshot of the view if recordMode is YES.
 Allows you to test a component with a particular state (i.e. FBComponentScope state).
 @param componentBlock A block that returns a component to snapshot
 @param updateStateBlock An update state block for the component. Returns the state you want the component to be tested with.
 @param referenceImagesDirectory The directory in which reference images are stored.
 @param identifier An optional identifier, used is there are muliptle snapshot tests in a given -test method.
 @param error An error to log in an XCTAssert() macro if the method fails (missing reference image, images differ, etc).
 @returns YES if the comparison (or saving of the reference image) succeeded.
 */
- (BOOL)compareSnapshotOfComponentBlock:(FBComponent *(^)())componentBlock
                       updateStateBlock:(id (^)(id))updateStackBlock
                              sizeRange:(FBSizeRange)sizeRange
               referenceImagesDirectory:(NSString *)referenceImagesDirectory
                             identifier:(NSString *)identifier
                                  error:(NSError **)errorPtr;

@end
