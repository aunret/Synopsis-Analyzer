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
//#import <Synopsis/Synopsis.h>
#import "FSDirectoryWatcher.h"
#import "SessionController.h"
#import "InspectorViewController.h"
#import <UserNotifications/UserNotifications.h>




@interface SynSession ()
- (instancetype) initWithFiles:(NSArray<NSURL*> *)n;
- (instancetype) initWithDir:(NSURL *)n recursively:(BOOL)isRecursive;
@property (strong,readwrite,nullable) FSDirectoryWatcher * watcher;
@property (atomic,strong,readwrite) NSUUID * dragUUID;	//	literally only used for drag-and-drop.
@property (atomic,readwrite) BOOL firedNotification;	//	whether or not the session fired a notification that it has completed all its files
- (void) createDirectoryWatcher;
- (void) destroyDirectoryWatcher;
@end




@implementation SynSession


+ (instancetype) createWithFiles:(NSArray<NSURL*> *)n	{
	SynSession		*returnMe = [[SynSession alloc] initWithFiles:n];
	return returnMe;
}
+ (instancetype) createWithDir:(NSURL *)n recursively:(BOOL)isRecursive	{
	SynSession		*returnMe = (n==nil) ? nil : [[SynSession alloc] initWithDir:n recursively:isRecursive];
	return returnMe;
}


- (instancetype) initWithFiles:(NSArray<NSURL*> *)n	{
	//NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		PrefsController			*pc = [PrefsController global];
		
		self.enabled = YES;
		self.title = @"Files";
		self.ops = [[NSMutableArray alloc] init];
		self.srcDir = nil;
		
		//	set outputDir from prefs
		self.outputDir = ([pc outputFolderEnabled] && [pc outputFolder]!=nil) ? [pc outputFolder] : nil;
		//	set tempDir from prefs
		self.tempDir = ([pc tempFolderEnabled] && [pc tempFolder]!=nil) ? [pc tempFolder] : nil;
		//	set opScript from prefs
		self.opScript = [pc opScript];
		//	set sessionScript from prefs
		self.sessionScript = [pc sessionScript];
		//	set preset from prefs
		self.preset = [pc defaultPreset];
		
		self.copyNonMediaFiles = NO;
		self.watchFolder = NO;
		self.watcher = nil;
		self.dragUUID = [NSUUID UUID];
		self.firedNotification = NO;
		
		self.type = SessionType_List;
		self.state = SessionState_Inactive;
		
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
	//NSLog(@"%s",__func__);
	NSFileManager		*fm = [NSFileManager defaultManager];
	BOOL				isDir = NO;
	if (![fm fileExistsAtPath:[inDir path] isDirectory:&isDir] || !isDir)
		return nil;
	
	self = [super init];
	if (self != nil)	{
		PrefsController			*pc = [PrefsController global];
		
		self.enabled = YES;
		self.title = [NSString stringWithFormat:@"Folder: %@",[inDir lastPathComponent]];
		self.ops = [[NSMutableArray alloc] init];
		self.srcDir = [inDir path];
		
		//	set the outputDir from prefs
		self.outputDir = ([pc outputFolderEnabled] && [pc outputFolder]!=nil) ? [pc outputFolder] : nil;
		//	set tempDir from prefs
		self.tempDir = ([pc tempFolderEnabled] && [pc tempFolder]!=nil) ? [pc tempFolder] : nil;
		//	set opScript from prefs
		self.opScript = [pc opScript];
		//	set sessionScript from prefs
		self.sessionScript = [pc sessionScript];
		//	set preset from prefs
		self.preset = [pc defaultPreset];
		
		self.copyNonMediaFiles = NO;
		self.watchFolder = NO;
		self.watcher = nil;
		self.dragUUID = [NSUUID UUID];
		self.firedNotification = NO;
		
		self.type = SessionType_Dir;
		self.state = SessionState_Inactive;
		
		//	run through the passed dir recursively, creating ops for the passed files
		NSFileManager			*fm = [NSFileManager defaultManager];
		NSDirectoryEnumerationOptions		iterOpts = NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
		if (!isRecursive)	{
			iterOpts = iterOpts | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
		}
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
	}
	return self;
}
- (void) dealloc	{
	[self destroyDirectoryWatcher];
	[[InspectorViewController global] uninspectItem:self];
}


#pragma mark - NSCoding protocol


- (instancetype) initWithCoder:(NSCoder *)coder	{
	//NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		if ([coder allowsKeyedCoding])	{
			PrefsController			*pc = [PrefsController global];
			
			self.enabled = (![coder containsValueForKey:@"enabled"])
				? YES
				: [coder decodeBoolForKey:@"enabled"];
			
			self.srcDir = (![coder containsValueForKey:@"srcDir"])
				? nil
				: [coder decodeObjectForKey:@"srcDir"];
			
			self.title = (![coder containsValueForKey:@"title"])
				? ((self.srcDir == nil) ? @"Files" : [NSString stringWithFormat:@"Folder: %@",self.srcDir.lastPathComponent])
				: [coder decodeObjectForKey:@"title"];
			
			self.outputDir = (![coder containsValueForKey:@"outputDir"])
				? nil
				: [coder decodeObjectForKey:@"outputDir"];
			
			self.tempDir = (![coder containsValueForKey:@"tempDir"])
				? nil
				: [coder decodeObjectForKey:@"tempDir"];
			
			self.opScript = (![coder containsValueForKey:@"opScript"])
				? nil
				: [coder decodeObjectForKey:@"opScript"];
			
			self.sessionScript = (![coder containsValueForKey:@"sessionScript"])
				? nil
				: [coder decodeObjectForKey:@"sessionScript"];
			
			self.preset = (![coder containsValueForKey:@"preset"])
				? [pc defaultPreset]
				: [pc presetForUUID:[coder decodeObjectForKey:@"preset"]];
			
			//	'type' must be loaded before 'copyNonMediaFiles' and 'watchFolder'
			self.type = (![coder containsValueForKey:@"type"])
				? SessionType_List
				: (SessionType)[coder decodeInt64ForKey:@"type"];
			
			self.state = SessionState_Inactive;
			
			self.copyNonMediaFiles = (![coder containsValueForKey:@"copyNonMediaFiles"])
				? NO
				: [coder decodeBoolForKey:@"copyNonMediaFiles"];
			
			self.watchFolder = (![coder containsValueForKey:@"watchFolder"])
				? NO
				: [coder decodeBoolForKey:@"watchFolder"];
			
			self.dragUUID = [NSUUID UUID];
			self.firedNotification = NO;
			
			//	load the ops last so we can use self's properties to populate the op's properties
			NSArray		*tmpArray = (![coder containsValueForKey:@"ops"]) ? [[NSMutableArray alloc] init] : [coder decodeObjectForKey:@"ops"];
			self.ops = [tmpArray mutableCopy];
			//	don't forget to set the parent session of the ops i loaded
			for (SynOp *op in self.ops)	{
				op.session = self;
			}
		}
	}
	return self;
}
- (void) encodeWithCoder:(NSCoder *)coder	{
	if ([coder allowsKeyedCoding])	{
		//	IMPORTANT: ONLY SAVE OPS IF WE ARE ***NOT*** A WATCH FOLDER
		if (!self.watchFolder && self.ops!=nil && [self.ops count]>0)	{
			//	we don't want to encode all the ops, just the ones that are pending/errors
			NSArray			*opsToSave = [self opsToSave];
			if (opsToSave != nil)
				[coder encodeObject:opsToSave forKey:@"ops"];
		}
		
		[coder encodeBool:self.enabled forKey:@"enabled"];
		
		if (self.srcDir != nil)
			[coder encodeObject:self.srcDir forKey:@"srcDir"];
		
		if (self.title != nil)
			[coder encodeObject:self.title forKey:@"title"];
		
		if (self.outputDir != nil)
			[coder encodeObject:self.outputDir forKey:@"outputDir"];
		
		if (self.tempDir != nil)
			[coder encodeObject:self.tempDir forKey:@"tempDir"];
		
		if (self.opScript != nil)
			[coder encodeObject:self.opScript forKey:@"opScript"];
		
		if (self.sessionScript != nil)
			[coder encodeObject:self.sessionScript forKey:@"sessionScript"];
		
		if (self.preset.uuid != nil)
			[coder encodeObject:self.preset.uuid forKey:@"preset"];
		
		//	'type' must be loaded before 'copyNonMediaFiles' and 'watchFolder'
		[coder encodeInt64:(NSInteger)self.type forKey:@"type"];
		
		[coder encodeBool:self.copyNonMediaFiles forKey:@"copyNonMediaFiles"];
		[coder encodeBool:self.watchFolder forKey:@"watchFolder"];
	}
}
- (NSMutableArray *) opsToSave;	{
	NSMutableArray		   *returnMe = [NSMutableArray arrayWithCapacity:0];
	
	for (SynOp *op in self.ops)	{
		if (op.status == OpStatus_Pending || op.status == OpStatus_PreflightErr || op.status == OpStatus_Err)
			[returnMe addObject:op];
	}
	
	if (returnMe != nil && [returnMe count] < 1)
		returnMe = nil;
	
	return returnMe;
}


#pragma mark - misc


- (NSString *) description	{
	if (self.watchFolder)
		return [NSString stringWithFormat:@"<SynSession, WF %@>",self.srcDir.lastPathComponent];
	return [NSString stringWithFormat:@"<SynSession, %ld SynOps>",(unsigned long)self.ops.count];
	//return [NSString stringWithFormat:@"<SynSession, %@>",self.dragUUID.UUIDString];
}


#pragma mark - backend


- (SynOp *) createOpForSrcURL:(NSURL *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return nil;
	
	SynOp			*returnMe = [[SynOp alloc] initWithSrcURL:n];
	
	if (returnMe != nil)	{
		if (returnMe.type == OpType_Other && !self.copyNonMediaFiles)	{
			returnMe = nil;
		}
		else
			returnMe.session = self;
	}
	
	//returnMe.delegate = [SessionController global];
	//if (returnMe != nil)
	//	returnMe.session = self;
	//NSLog(@"\t\tnew op is %@",returnMe);
	
	/*
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
	if (self.outputDir != nil && [fm fileExistsAtPath:self.outputDir isDirectory:&isDir] && isDir)	{
		NSURL			*dstURL = [[NSURL fileURLWithPath:self.outputDir] URLByAppendingPathComponent:newFileName isDirectory:NO];
		returnMe.dst = [dstURL path];
	}
	//	else we're putting the file in the same dir it came from
	else	{
		NSURL			*dstURL = [[[NSURL fileURLWithPath:returnMe.src] URLByDeletingLastPathComponent] URLByAppendingPathComponent:newFileName isDirectory:NO];
		returnMe.dst = [dstURL path];
	}
	*/
	
	return returnMe;
}
- (NSString *) createDescriptionString	{
	int			toBeAnalyzedCount = 0;
	int			doneAnalyzingCount = 0;
	
	@synchronized (self)	{
		for (SynOp *op in self.ops)	{
			if (op.type == OpType_AVFFile)	{
				++toBeAnalyzedCount;
				switch (op.status)	{
				case OpStatus_Preflight:
				case OpStatus_Pending:
				case OpStatus_Cleanup:
				case OpStatus_Analyze:
					break;
				case OpStatus_PreflightErr:
				case OpStatus_Complete:
				case OpStatus_Err:
					++doneAnalyzingCount;
					break;
				}
			}
		}
	}
	int			analyzeCount = toBeAnalyzedCount - doneAnalyzingCount;
	if (toBeAnalyzedCount == 0)
		return [NSString stringWithFormat:@"(No files)"];
	if (toBeAnalyzedCount == 1)	{
		if (analyzeCount == 0)
			return @"(1 file, 0 files to analyze)";
		else
			return @"(1 file, 1 files to analyze)";
	}
	else	{
		if (analyzeCount == 0)
			return [NSString stringWithFormat:@"(%d files, 0 files to analyze)",toBeAnalyzedCount];
		else if (analyzeCount == 1)
			return [NSString stringWithFormat:@"(%d files, 1 file to analyze)",toBeAnalyzedCount];
		else
			return [NSString stringWithFormat:@"(%d files, %d files to analyze)",toBeAnalyzedCount,analyzeCount];
	}
	
	
	
	/*
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
	*/
}

@synthesize copyNonMediaFiles=myCopyNonMediaFiles;
- (void) setCopyNonMediaFiles:(BOOL)n	{
	@synchronized (self)	{
		BOOL			changed = (myCopyNonMediaFiles==n) ? NO : YES;
		myCopyNonMediaFiles = n;
		//	if we're enabling this 'copyNonMediaFiles'...
		if (changed)	{
			if (self.srcDir != nil)	{
				//	enumerate everything in 'srcDir'- make sure that ops exist for all the non-AVF files that haven't already been added...
				NSFileManager		*fm = [NSFileManager defaultManager];
				NSDirectoryEnumerationOptions		iterOpts = NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
				NSDirectoryEnumerator				*dirIt = [fm
					enumeratorAtURL:[NSURL fileURLWithPath:self.srcDir]
					includingPropertiesForKeys:@[ NSURLIsDirectoryKey ]
					options:iterOpts
					errorHandler:nil];
				for (NSURL *fileURL in dirIt)	{
					//NSLog(@"\tchecking url %@",fileURL.path);
					NSError			*nsErr = nil;
					NSNumber		*isDir = nil;
					if (![fileURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&nsErr])	{
					}
					else if (![isDir boolValue])	{
						//	if 'copyNonMediaFiles' is enabled, make sure that an op exists for this file (even if it's not an AVF file)
						if (n)	{
							if ([self getOpWithSrcFile:[fileURL path]] == nil)	{
								SynOp			*newOp = [self createOpForSrcURL:fileURL];
								if (newOp != nil)	{
									[self.ops addObject:newOp];
								}
							}
						}
						//	else 'copyNonMediaFiles' is disabled- try to find an op for this file, and if it's not an AVF file, delete it
						else	{
							SynOp		*existingOp = [self getOpWithSrcFile:[fileURL path]];
							if (existingOp != nil && existingOp.type != OpType_AVFFile)	{
								[self.ops removeObjectIdenticalTo:existingOp];
							}
						}
						
					}
				}
			
			}
			
			//	if we added or removed files we need to update the outline view...
			[[SessionController global] reloadRowForItem:self];
		}
	}
}
- (BOOL) copyNonMediaFiles	{
	return myCopyNonMediaFiles;
}

@synthesize watchFolder=myWatchFolder;
- (void) setWatchFolder:(BOOL)n	{
	@synchronized (self)	{
		BOOL			changed = (myWatchFolder==n) ? NO : YES;
		myWatchFolder = n;
		if (changed)	{
			if (n)	{
				[self.ops removeAllObjects];
				[self createDirectoryWatcher];
			}
			else	{
				[self destroyDirectoryWatcher];
			}
		}
	}
}
- (BOOL) watchFolder	{
	return myWatchFolder;
}
- (double) calculateProgress	{
	double		returnMe = -1.0;
	@synchronized (self.ops)	{
		double		maxVal = 0.0;
		double		currentVal = 0.0;
		//BOOL		hideProgressBar = YES;
		for (SynOp *op in self.ops)	{
			switch (op.status)	{
			case OpStatus_Pending:
				maxVal += 1.0;
				break;
			case OpStatus_Preflight:
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
				//hideProgressBar = NO;
				if (op.job != nil)
					currentVal += op.job.jobProgress;
				maxVal += 1.0;
				break;
			case OpStatus_PreflightErr:
			case OpStatus_Complete:
			case OpStatus_Err:
				maxVal += 1.0;
				currentVal += 1.0;
				break;
			}
		}
		returnMe = currentVal/maxVal;
		//if (hideProgressBar)
		//	returnMe = -1.0;
	}
	return returnMe;
}
- (void) createDirectoryWatcher	{
	@synchronized (self)	{
		if (self.watcher != nil)
			self.watcher = nil;
		if (self.watchFolder && self.srcDir != nil && [[NSFileManager defaultManager] fileExistsAtPath:self.srcDir])	{
			//	make a watcher for the top-level directory
			//NSLog(@"\tmaking directory watcher for %@",self.srcDir);
			
			/*
			self.watcher = [[VVKQueue alloc] init];
			self.watcher.delegate = self;
			[self.watcher watchPath:self.srcDir];
			*/
			
			
			__weak SynSession		*bss = self;
			self.watcher = [[FSDirectoryWatcher alloc]
				initWithDirectory:self.srcDir
				notificationBlock:^(NSArray<NSString*> * changedPaths)	{
					NSLog(@"watched paths changed! %@",changedPaths);
					
					//	run through the URLs (they may be files or folders, we don't know at this point)
					SessionController		*sc = [SessionController global];
					NSFileManager			*fm = [NSFileManager defaultManager];
					BOOL					needsToStart = NO;
					for (NSString *changedPath in changedPaths)	{
						BOOL			isDir = NO;
						//	if the file doesn't exist at this path, try to remove any ops with this as a src
						if (![fm fileExistsAtPath:changedPath isDirectory:&isDir])	{
							BOOL			foundMatch;
							do	{
								int				tmpIndex = 0;
								foundMatch = NO;
								for (SynOp *op in bss.ops)	{
									if (op.src != nil && [op.src isEqualToString:changedPath])	{
										[bss.ops removeObjectAtIndex:tmpIndex];
										foundMatch = YES;
										break;
									}
									++tmpIndex;
								}
							} while (foundMatch);
						}
						//	else if the file exists and it isn't a directory, make an op for it and add it to this session
						else if (!isDir)	{
							needsToStart = YES;
							
							SynOp		*newOp = [bss createOpForSrcURL:[NSURL fileURLWithPath:changedPath]];
							if (newOp != nil)	{
								@synchronized (bss)	{
									[bss.ops addObject:newOp];
									bss.firedNotification = NO;
								}
							}
						}
					}
					
					//	now that my ops have been updated, i need to reload my row in the outline view
					//[sc reloadRowForItem:bss];
					//	...actually, i need to reload data entirely, as the outline view may need to display new rows for the new ops!
					[sc reloadData];
					
					//	if we added ops we need to start...
					if (needsToStart)	{
						if ([sc processingFiles])
							[sc makeSureRunningMaxPossibleOps];
						else
							[sc startButDontChangeSessionStates];
					}
				}];
			
		}
	}
}
- (BOOL) processedAllOps	{
	//NSLog(@"%s",__func__);
	BOOL			returnMe = YES;
	@synchronized (self)	{
		for (SynOp *op in self.ops)	{
			//NSLog(@"\top %@ has status %ld",op,op.status);
			switch (op.status)	{
			case OpStatus_Pending:
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
			case OpStatus_Preflight:
				returnMe = NO;
				break;
			case OpStatus_PreflightErr:
			case OpStatus_Complete:
			case OpStatus_Err:
				break;
			}
			if (!returnMe)
				break;
		}
	}
	return returnMe;
}
- (BOOL) processedAllOpsSuccessfully	{
	BOOL			returnMe = YES;
	@synchronized (self)	{
		for (SynOp *op in self.ops)	{
			switch (op.status)	{
			case OpStatus_Pending:
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
			case OpStatus_PreflightErr:
			case OpStatus_Err:
			case OpStatus_Preflight:
				returnMe = NO;
				break;
			case OpStatus_Complete:
				break;
			}
			if (!returnMe)
				break;
		}
	}
	return returnMe;
}
- (void) fireNotificationIfAppropriate	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		
		//	if we already fired the notification, bail immediately
		if (self.firedNotification)
			return;
		
		int			errorCount = 0;
		int			successfulCount = 0;
		int			unfinishedCount = 0;
		for (SynOp *op in self.ops)	{
			switch (op.status)	{
			case OpStatus_Pending:
			case OpStatus_Preflight:
			case OpStatus_Analyze:
			case OpStatus_Cleanup:
				++unfinishedCount;
				break;
			case OpStatus_Complete:
				++successfulCount;
				break;
			case OpStatus_PreflightErr:
			case OpStatus_Err:
				++errorCount;
				break;
			}
		}
		
		//	if we haven't finished processing any files, bail immediately
		if (unfinishedCount > 0)
			return;
		
		//	assemble the content string
		NSString					*contentString = nil;
		
		if (errorCount == 0)	{
			if (successfulCount < 2)
				contentString = [NSString stringWithFormat:@"Session %@ finished analyzing the file",self.title];
			else
				contentString = [NSString stringWithFormat:@"Session %@ finished analyzing %d files",self.title,successfulCount];
		}
		else if (successfulCount == 0)	{
			if (errorCount < 2)
				contentString = [NSString stringWithFormat:@"Session %@ finished analyzing the file, but it had an error",self.title];
			else
				contentString = [NSString stringWithFormat:@"Session %@ finished analyzing %d files, but they all had errors",self.title,errorCount];
		}
		else	{
			contentString = [NSString stringWithFormat:@"Session %@ finished analyzing",self.title];
			
			if (successfulCount + errorCount < 2)
				contentString = [contentString stringByAppendingString:@" a file, with"];
			else
				contentString = [contentString stringByAppendingFormat:@" %d files, with",successfulCount+errorCount];
			
			if (errorCount < 2)
				contentString = [contentString stringByAppendingString:@" 1 error"];
			else
				contentString = [contentString stringByAppendingFormat:@" %d errors",errorCount];
		}
		
		if (@available(macOS 10.14, *))	{
			UNMutableNotificationContent		*content = [[UNMutableNotificationContent alloc] init];
			content.title = @"Session Complete!";
			content.body = contentString;
			content.badge = nil;
			content.sound = nil;
			content.categoryIdentifier = @"SessionComplete";
		
			NSString			*requestID = [[NSUUID UUID] UUIDString];
			UNNotificationRequest		*req = [UNNotificationRequest
				requestWithIdentifier:requestID
				content:content
				trigger:nil];
		
			[[UNUserNotificationCenter currentNotificationCenter]
				addNotificationRequest:req
				withCompletionHandler:^(NSError *err)	{
					//	close the notification automatically after 3 seconds
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						[[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[requestID]];
					});
				}];
		
			self.firedNotification = YES;
		}
	}
}
- (void) destroyDirectoryWatcher	{
	@synchronized (self)	{
		self.watcher = nil;
	}
}
- (SynOp *) getOpWithSrcFile:(NSString *)n	{
	if (n == nil)
		return nil;
	SynOp			*returnMe = nil;
	@synchronized (self)	{
		for (SynOp *op in self.ops)	{
			if (op.src!=nil && [op.src isEqualToString:n])	{
				returnMe = op;
				break;
			}
		}
	}
	return returnMe;
}


@end













