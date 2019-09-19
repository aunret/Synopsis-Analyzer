//
//  SynSession.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/18/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SynSession.h"
#import "SynOp.h"
#import "PresetObject.h"




@interface SynSession ()
- (instancetype) initWithFiles:(NSArray<NSURL*> *)n;
- (instancetype) initWithDir:(NSURL *)n;
@end




@implementation SynSession


+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n	{
	SynSession		*returnMe = (n==nil || [n count]<1) ? nil : [[SynSession alloc] initWithFiles:n];
	return returnMe;
}
+ (instancetype) createWithDir:(NSURL *)n	{
	SynSession		*returnMe = (n==nil) ? nil : [[SynSession alloc] initWithDir:n];
	return returnMe;
}


- (instancetype) initWithFiles:(NSArray<NSURL*> *)n	{
	self = [super init];
	if (self != nil)	{
		//	make ops from the passed files, add them to my array
		
		//	set tmpDir from prefs
		//	set opScriptURL from prefs
		//	set sessionScriptURL from prefs
		//	set preset from prefs
		
		self.status = SessionStatus_Pending;
	}
	return self;
}
- (instancetype) initWithDir:(NSURL *)n	{
	NSFileManager		*fm = [NSFileManager defaultManager];
	BOOL				isDir = NO;
	if (![fm fileExistsAtPath:[n path] isDirectory:&isDir] || !isDir)
		return nil;
	
	self = [super init];
	if (self != nil)	{
		//	run through the passed dir recursively, creating ops for the passed files
		
		//	set tmpDir from prefs
		//	set opScriptURL from prefs
		//	set sessionScriptURL from prefs
		//	set preset from prefs
		
		self.status = SessionStatus_Pending;
	}
	return self;
}


@end
