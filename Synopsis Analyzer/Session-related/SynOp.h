//
//  SynOp.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SynSession;




typedef NS_ENUM(NSUInteger, OpErr)	{
	OpErr_None = 0,
	OpErr_Src,	//	problem with src file (doesn't exist/can't be read)
	OpErr_Job,	//	problem with job (consult job object error for more info)
	OpErr_DstWrite,	//	problem copying file to dst location
	OpErr_Script	//	problem executing script
};

typedef NS_ENUM(NSUInteger, OpType)	{
	OpType_AVFFile = 0,	//	file is AVF-compatible: will be analyzed/transcoded
	OpType_Other,	//	file is NOT AVF-compatible: if session has outputDir, will be copied there.  if session's outputDir is nil, will be ignored.  no scripts will be run on it
};

typedef NS_ENUM(NSUInteger, OpStatus)	{
	OpStatus_Pending = 0,	//	hasn't been started yet
	OpStatus_PreflightErr,	//	err encountered before starting (won't be started)
	OpStatus_Analyze,	//	analyzing
	OpStatus_Cleanup,	//	cleaning up (copying/moving files, executing scripts)
	OpStatus_Complete,	//	everything finished successfully
	OpStatus_Err	//	err encountered somewhere during processing (resolve the error and process again)
};




@interface SynOp : NSObject <NSCoding>

- (id) initWithSrcURL:(NSURL *)inSrc;

@property (atomic,readwrite,strong,nullable) NSURL * src;
@property (atomic,readwrite,strong,nullable) NSURL * dst;

@property (atomic,readwrite) OpType type;
@property (atomic,readwrite) OpStatus status;

@property (atomic,weak) SynSession *parent;

@end


