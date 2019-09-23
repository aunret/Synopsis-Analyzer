//
//  SynSession.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/18/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

//@class SynOp;
//@class PresetObject;	//	can't fwd declare protocol (d'oh)
#import "SynOp.h"
#import "PresetObject.h"




@protocol SynSessionDelegate
- (void) synSessionStatusChanged:(SynSession *_Nonnull)n;
- (void) synOpStatusChanged:(SynOp *_Nonnull)n;
@end




@interface SynSession : NSObject <NSCoding>	{
}

+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n;
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

@property (assign,readwrite) BOOL enabled;

@property (atomic,readwrite,strong,nullable) NSMutableArray<SynOp*> * ops;
@property (atomic,readwrite,strong,nullable) NSURL * outputDir;
@property (atomic,readwrite,strong,nullable) NSURL * tmpDir;
@property (atomic,readwrite,strong,nullable) NSURL * opScriptURL;
@property (atomic,readwrite,strong,nullable) NSURL * sessionScriptURL;
@property (atomic,readwrite,strong,nullable) PresetObject * preset;

//@property (atomic,readwrite) SessionStatus status;

//@property (atomic,weak,nullable) NSObject<SynSessionDelegate> * delegate;

- (SynOp *) createOpForSrcURL:(NSURL *_Nonnull)n;
- (NSString *_Nonnull) createDescriptionString;

- (void) stopAllOps;
- (SynOp *) startAnOp;
//	returns -1 if session isn't being processed yet, for any reason (disabled, all pending, all complete/err, etc)
- (double) calculateProgress;

@end


