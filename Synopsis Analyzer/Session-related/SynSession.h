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



@interface SynSession : NSObject <NSCoding>	{
}

+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n;
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

@property (assign,readwrite) BOOL enabled;

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

- (SynOp *) createOpForSrcURL:(NSURL *_Nonnull)n;
- (NSString *_Nonnull) createDescriptionString;

//	returns -1 if session isn't being processed yet, for any reason (disabled, all pending, all complete/err, etc)
- (double) calculateProgress;

- (SynOp *) getOpWithSrcFile:(NSString *)n;

@end





NS_ASSUME_NONNULL_END

