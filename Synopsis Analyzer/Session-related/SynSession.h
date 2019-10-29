//
//  SynSession.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/18/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SynOp.h"
#import "PresetObject.h"

NS_ASSUME_NONNULL_BEGIN



typedef NS_ENUM(NSUInteger, SessionType)	{
	SessionType_Dir = 0,
	SessionType_List
};

//	session state is only really considered if the session is NOT a watch folder (watch folders are basically "always active")
typedef NS_ENUM(NSUInteger, SessionState)	{
	SessionState_Inactive = 0,	//	ops from inactive sessions will not be processed
	SessionState_Active	//	ops from active sessions will be processed
};



@interface SynSession : NSObject <NSCoding>	{
}

+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n;
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

@property (assign,readwrite) BOOL enabled;
@property (strong,readwrite,atomic) NSString * title;

@property (atomic,readwrite,strong,nullable) NSMutableArray<SynOp*> * ops;
@property (atomic,readwrite,strong,nullable) NSString * srcDir;	//	only non-nil if this is a SessionType_Dir!
@property (atomic,readwrite,strong,nullable) NSString * outputDir;
@property (atomic,readwrite,strong,nullable) NSString * tempDir;
@property (atomic,readwrite,strong,nullable) NSString * opScript;
@property (atomic,readwrite,strong,nullable) NSString * sessionScript;
@property (atomic,readwrite,strong,nullable) PresetObject * preset;
@property (atomic,readwrite) BOOL copyNonMediaFiles;
@property (atomic,readwrite) BOOL watchFolder;

@property (atomic,readwrite) SessionType type;
@property (atomic,readwrite) SessionState state;

@property (atomic,strong,readonly) NSUUID * dragUUID;	//	literally only used for drag-and-drop.

- (SynOp *) createOpForSrcURL:(NSURL *_Nonnull)n;
- (NSString *_Nonnull) createDescriptionString;

- (double) calculateProgress;
//	returns a YES only if all ops have been processed (all ops' states are either an err or complete)
- (BOOL) processedAllOps;
- (BOOL) processedAllOpsSuccessfully;
//	fires a notification center notification if it has finished all its ops (and hasn't yet fired its notification)
- (void) fireNotificationIfAppropriate;

- (SynOp *) getOpWithSrcFile:(NSString *)n;
//	returns an array of the ops that should be saved/encoded (only ops that are pending or have errored out)
- (NSMutableArray *) opsToSave;

@end





NS_ASSUME_NONNULL_END

