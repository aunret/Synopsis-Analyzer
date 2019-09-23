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
#import "PrefsController.h"




@interface SynSession ()
- (instancetype) initWithFiles:(NSArray<NSURL*> *)n;
- (instancetype) initWithDir:(NSURL *)n recursively:(BOOL)isRecursive;
@end




@implementation SynSession


+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n	{
	SynSession		*returnMe = (n==nil || [n count]<1) ? nil : [[SynSession alloc] initWithFiles:n];
	return returnMe;
}
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive	{
	SynSession		*returnMe = (n==nil) ? nil : [[SynSession alloc] initWithDir:n recursively:isRecursive];
	return returnMe;
}


- (instancetype) initWithFiles:(NSArray<NSURL*> *)n	{
	self = [super init];
	if (self != nil)	{
		PrefsController			*pc = [PrefsController global];
		
		self.enabled = YES;
		self.ops = [[NSMutableArray alloc] init];
		
		//	set outputDir from prefs
		self.outputDir = [pc outputFolderURL];
		//	set tmpDir from prefs
		self.tmpDir = [pc tempFolderURL];
		//	set opScriptURL from prefs
		self.opScriptURL = [pc opScriptURL];
		//	set sessionScriptURL from prefs
		self.sessionScriptURL = [pc sessionScriptURL];
		//	set preset from prefs
		self.preset = [pc defaultPreset];
		
		//	make ops from the passed files, add them to my array
		for (NSURL *tmpURL in n)	{
			SynOp		*newOp = [self createOpForSrcURL:tmpURL];
			if (newOp != nil)
				[self.ops addObject:newOp];
		}
		
		//self.status = SessionStatus_Pending;
	}
	return self;
}
- (instancetype) initWithDir:(NSURL *)inDir recursively:(BOOL)isRecursive	{
	NSFileManager		*fm = [NSFileManager defaultManager];
	BOOL				isDir = NO;
	if (![fm fileExistsAtPath:[inDir path] isDirectory:&isDir] || !isDir)
		return nil;
	
	self = [super init];
	if (self != nil)	{
		PrefsController			*pc = [PrefsController global];
		
		self.enabled = YES;
		self.ops = [[NSMutableArray alloc] init];
		
		//	set the outputDir from prefs
		self.outputDir = [pc outputFolderURL];
		//	set tmpDir from prefs
		self.tmpDir = [pc tempFolderURL];
		//	set opScriptURL from prefs
		self.opScriptURL = [pc opScriptURL];
		//	set sessionScriptURL from prefs
		self.sessionScriptURL = [pc sessionScriptURL];
		//	set preset from prefs
		self.preset = [pc defaultPreset];
		
		
		//	run through the passed dir recursively, creating ops for the passed files
		NSFileManager			*fm = [NSFileManager defaultManager];
		NSDirectoryEnumerationOptions		iterOpts = NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
		//if (!isRecursive)	{
			iterOpts = iterOpts | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
		//}
		if (isRecursive)
			NSLog(@"ERR: recursive is disabled right now!");
		NSDirectoryEnumerator				*dirIt = [fm
			enumeratorAtURL:inDir
			includingPropertiesForKeys:@[ NSURLIsDirectoryKey ]
			options:iterOpts
			errorHandler:nil];
		for (NSURL *fileURL in dirIt)	{
			NSError			*nsErr = nil;
			NSNumber		*isDir = nil;
			if (![fileURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&nsErr])	{
			}
			else if (![isDir boolValue])	{
				SynOp			*newOp = [self createOpForSrcURL:fileURL];
				if (newOp != nil)
					[self.ops addObject:newOp];
			}
		}
		
		//self.status = SessionStatus_Pending;
	}
	return self;
}


#pragma mark - NSCoding protocol


- (instancetype) initWithCoder:(NSCoder *)coder	{
	NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		if ([coder allowsKeyedCoding])	{
			PrefsController			*pc = [PrefsController global];
			
			//self.src = (![coder containsValueForKey:@"src"]) ? nil : [coder decodeObjectForKey:@"src"];
			//self.dst = (![coder containsValueForKey:@"dst"]) ? nil : [coder decodeObjectForKey:@"dst"];
			//self.status = (![coder containsValueForKey:@"status"]) ? OpStatus_Pending : (OpStatus)[coder decodeIntForKey:@"status"];
			
			self.enabled = (![coder containsValueForKey:@"enabled"])
				? YES
				: [coder decodeBoolForKey:@"enabled"];
			
			self.outputDir = (![coder containsValueForKey:@"outputDir"])
				? [pc outputFolderURL]
				: [coder decodeObjectForKey:@"outputDir"];
			
			self.tmpDir = (![coder containsValueForKey:@"tmpDir"])
				? [pc tempFolderURL]
				: [coder decodeObjectForKey:@"tmpDir"];
			
			self.opScriptURL = (![coder containsValueForKey:@"opScriptURL"])
				? [pc opScriptURL]
				: [coder decodeObjectForKey:@"opScriptURL"];
			
			self.sessionScriptURL = (![coder containsValueForKey:@"sessionScriptURL"])
				? [pc sessionScriptURL]
				: [coder decodeObjectForKey:@"sessionScriptURL"];
			
			self.preset = (![coder containsValueForKey:@"preset"])
				? [pc defaultPreset]
				: [pc presetForUUID:[coder decodeObjectForKey:@"preset"]];
			//if (self.preset == nil)
			//	self.preset = [pc defaultPreset];
			
			//	load the ops last so we can use self's properties to populate the op's properties
			NSArray		*tmpArray = (![coder containsValueForKey:@"ops"]) ? [[NSMutableArray alloc] init] : [coder decodeObjectForKey:@"ops"];
			self.ops = [tmpArray mutableCopy];
		}
	}
	return self;
}
- (void) encodeWithCoder:(NSCoder *)coder	{
	if ([coder allowsKeyedCoding])	{
		if (self.ops!=nil && [self.ops count]>0)
			[coder encodeObject:self.ops forKey:@"ops"];
		
		[coder encodeBool:self.enabled forKey:@"enabled"];
		
		if (self.outputDir != nil)
			[coder encodeObject:self.outputDir forKey:@"outputDir"];
		
		if (self.tmpDir != nil)
			[coder encodeObject:self.tmpDir forKey:@"tmpDir"];
		
		if (self.opScriptURL != nil)
			[coder encodeObject:self.opScriptURL forKey:@"opScriptURL"];
		
		if (self.sessionScriptURL != nil)
			[coder encodeObject:self.sessionScriptURL forKey:@"sessionScriptURL"];
		
		if (self.preset.uuid != nil)
			[coder encodeObject:self.preset.uuid forKey:@"preset"];
		
		//[coder encodeInt:(NSInteger)self.status forKey:@"status"];
	}
}


#pragma mark - misc


- (NSString *) description	{
	return [NSString stringWithFormat:@"<SynSession, %d SynOps>",self.ops.count];
}


#pragma mark - backend


- (SynOp *) createOpForSrcURL:(NSURL *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return nil;
	SynOp			*returnMe = [[SynOp alloc] initWithSrcURL:n];
	//returnMe.delegate = [SessionController global];
	returnMe.session = self;
	//NSLog(@"\t\tnew op is %@",returnMe);
	
	//	get the path extension & orig filename
	NSString		*pathExtension = n.pathExtension;
	NSString		*origFileName = [[n URLByDeletingPathExtension] lastPathComponent];
	//	new file name has "_analyzed" appended + path extension
	NSString		*newFileName = [NSString stringWithFormat:@"%@_analyzed",origFileName];
	if (pathExtension!=nil && [pathExtension length]>0)
		newFileName = [newFileName stringByAppendingPathExtension:pathExtension];
	
	
	NSFileManager	*fm = [NSFileManager defaultManager];
	BOOL			isDir = NO;
	//	if there's an output dir, we're putting the file in there
	if (self.outputDir != nil && [fm fileExistsAtPath:self.outputDir.path isDirectory:&isDir] && isDir)	{
		NSURL			*dstURL = [self.outputDir URLByAppendingPathComponent:newFileName isDirectory:NO];
		returnMe.dst = dstURL;
	}
	//	else we're putting the file in the same dir it came from
	else	{
		NSURL			*dstURL = [[returnMe.src URLByDeletingLastPathComponent] URLByAppendingPathComponent:newFileName isDirectory:NO];
		returnMe.dst = dstURL;
	}
	
	return returnMe;
}
- (NSString *) createDescriptionString	{
	int				totalCount = 0;
	int				analyzeCount = 0;
	@synchronized (self)	{
		for (SynOp *op in self.ops)	{
			if (op.type == OpType_AVFFile)
				++analyzeCount;
			++totalCount;
		}
	}
	if (totalCount == 0)
		return [NSString stringWithFormat:@"(No files)"];
	if (totalCount == 1)	{
		if (analyzeCount == 0)
			return @"(1 file, 0 files to analyze)";
		else
			return @"(1 file, 1 files to analyze)";
	}
	else	{
		if (analyzeCount == 0)
			return [NSString stringWithFormat:@"(%d files, 0 files to analyze)",totalCount];
		else if (analyzeCount == 1)
			return [NSString stringWithFormat:@"(%d files, 1 file to analyze)",totalCount];
		else
			return [NSString stringWithFormat:@"(%d files, %d files to analyze)",totalCount,analyzeCount];
	}
}


#pragma mark - control


- (void) stopAllOps	{
}
- (SynOp *) startAnOp	{
	if (!self.enabled)
		return nil;
	SynOp		*returnMe = nil;
	@synchronized (self.ops)	{
		//	run through the array of ops until we find one we can start
		for (SynOp * op in self.ops)	{
			switch (op.status)	{
			case OpStatus_Pending:
				returnMe = op;
				break;
			case OpStatus_PreflightErr:
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
			case OpStatus_Complete:
			case OpStatus_Err:
				break;
			}
			if (returnMe != nil)
				break;
		}
	}
	
	//	start the op
	if (returnMe != nil)
		[returnMe start];
	
	return returnMe;
}
- (double) calculateProgress	{
	double		returnMe = -1.0;
	@synchronized (self.ops)	{
		double		totalOpCount = self.ops.count;
		double		inProgressOpCount = 0.0;
		double		finishedOpCount = 0.0;
		for (SynOp *op in self.ops)	{
			switch (op.status)	{
			case OpStatus_Pending:
				break;
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
				++inProgressOpCount;
				break;
			case OpStatus_PreflightErr:
			case OpStatus_Complete:
			case OpStatus_Err:
				++finishedOpCount;
				break;
			}
		}
		//	if no ops have been started, or all the ops have been finished (in any state), return -1
		if ((inProgressOpCount+finishedOpCount==0.0) ||
		(inProgressOpCount+finishedOpCount==totalOpCount))	{
			returnMe = -1.0;
		}
		//	else some ops in this session are being processed...
		else	{
			returnMe = (inProgressOpCount/2.0 + finishedOpCount) / totalOpCount;
		}
	}
	return returnMe;
}


/*
#pragma mark - SynOpDelegate protocol


- (void) synOpStatusChanged:(SynOp *)n	{
	NSLog(@"%s ... %@",__func__,n);
	
	switch (n.status)	{
	case OpStatus_Pending:
	case OpStatus_PreflightErr:
	case OpStatus_Cleanup:
		break;
	case OpStatus_Complete:
	case OpStatus_Err:
		//	
		break;
	case OpStatus_Analyze:
		break;
	}
	
	//if (self.delegate != nil)
	//	[self.delegate synOpStatusChanged:n];
}
*/


@end













