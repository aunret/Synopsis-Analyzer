//
//  SynSession.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/18/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SynOp;
@class PresetObject;




typedef NS_ENUM(NSUInteger, SessionStatus)	{
	SessionStatus_Pending,	//	session hasn't been started yet
	SessionStatus_InProgress,	//	session is processing its operations
	SessionStatus_Complete	//	all ops in session have been attempted, session is complete
};




@interface SynSession : NSObject <NSCoding>	{
}

+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n;
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

@property (strong) NSMutableArray<SynOp*> * ops;
@property (strong) NSURL * outputDir;
@property (strong) NSURL * tmpDir;
@property (strong) NSURL * opScriptURL;
@property (strong) NSURL * sessionScriptURL;
@property (strong) PresetObject * preset;

@property (atomic,readwrite) SessionStatus status;

- (SynOp *) createOpForSrcURL:(NSURL *)n;

@end


