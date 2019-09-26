//
//  SynOp.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SynOp.h"
#import "SessionController.h"
#import "SynSession.h"
#import "PrefsController.h"

#import <AVFoundation/AVFoundation.h>
#import <HapInAVFoundation/HapInAVFoundation.h>




@interface SynOp()
@property (atomic,weak,nullable) NSObject<SynOpDelegate> * delegate;
@property (assign,readwrite,atomic) BOOL paused;
- (void) _beginPreflight;
- (void) _beginJob;
- (void) _beginCleanup;
- (void) _populateTypeProperty;
- (void) _populateThumb;
@end




@implementation SynOp


#pragma mark - NSCoding protocol


- (instancetype) initWithSrcURL:(NSURL *)inSrc	{
	self = [super init];
	if (self != nil)	{
		self.src = [inSrc path];
		self.dst = nil;
		self.tmpFile = nil;
		self.thumb = nil;
		//self.type = OpType_Other;
		[self _populateTypeProperty];
		self.status = OpStatus_Pending;
		self.errString = nil;
		self.job = nil;
		self.delegate = [SessionController global];
	}
	return self;
}
- (instancetype) initWithSrcPath:(NSString *)inSrc	{
	self = [super init];
	if (self != nil)	{
		self.src = inSrc;
		self.dst = nil;
		self.tmpFile = nil;
		self.thumb = nil;
		//self.type = OpType_Other;
		[self _populateTypeProperty];
		self.status = OpStatus_Pending;
		self.errString = nil;
		self.job = nil;
		self.delegate = [SessionController global];
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder *)coder	{
	NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		if ([coder allowsKeyedCoding])	{
			self.src = (![coder containsValueForKey:@"src"]) ? nil : [coder decodeObjectForKey:@"src"];
			self.dst = (![coder containsValueForKey:@"dst"]) ? nil : [coder decodeObjectForKey:@"dst"];
			self.thumb = nil;
			//if (![coder containsValueForKey:@"type"])
			//	self.type = [self _populateTypeProperty];
			//else
			//	self.type = (OpType)[coder decodeIntForKey:@"type"];
			[self _populateTypeProperty];
			self.status = (![coder containsValueForKey:@"status"]) ? OpStatus_Pending : (OpStatus)[coder decodeInt64ForKey:@"status"];
			self.errString = nil;
			self.job = nil;
			self.delegate = [SessionController global];
		}
	}
	return self;
}
- (void) encodeWithCoder:(NSCoder *)coder	{
	if ([coder allowsKeyedCoding])	{
		if (self.src != nil)
			[coder encodeObject:self.src forKey:@"src"];
		if (self.dst != nil)
			[coder encodeObject:self.dst forKey:@"dst"];
		//	don't encode the 'type' property
		[coder encodeInt64:(NSInteger)self.status forKey:@"status"];
	}
}


#pragma mark - misc


- (NSString *) description	{
	return [NSString stringWithFormat:@"<SynOp: %@>",self.src.lastPathComponent];
}
//	synthesize using a different name so we avoid recursion (we're overriding the setter/getter so we only populate the thumb when appropriate)
@synthesize session=mySession;
- (void) setSession:(SynSession *)n	{
	mySession = n;
	if (self.session.type == SessionType_List)
		[self _populateThumb];
}
- (SynSession *) session	{
	return mySession;
}


#pragma mark - backend


- (void) _populateTypeProperty	{
	//NSLog(@"%s",__func__);
	if (self.src == nil)
		self.type = OpType_Other;
	else	{
		AVAsset			*asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.src]];
		if (asset == nil)	{
			self.type = OpType_Other;
		}
		else	{
			//	if it's a simple AVF asset...
			if ([asset isPlayable])	{
				self.type = OpType_AVFFile;
			}
			//	else if the AVF asset has a hap track...
			else if ([asset containsHapVideoTrack])	{
				self.type = OpType_AVFFile;
			}
			//	else it's not recognizable as an AVF asset (even though you could make an AVAsset from it)
			else	{
				self.type = OpType_Other;
			}
		}
	}
	
}
- (void) _populateThumb	{
	//NSLog(@"%s",__func__);
	if (self.type == OpType_AVFFile)	{
		AVAsset			*asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.src]];
		if (asset == nil)	{
			//	do nothing- don't make a thumb for a non-avf asset
		}
		else	{
			if ([asset isPlayable])	{
				AVAssetImageGenerator		*gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
				NSError				*nsErr = nil;
				//CMTime				time = CMTimeMake(1,60);
				CGImageRef			imgRef = [gen copyCGImageAtTime:CMTimeMake(1,60) actualTime:NULL error:&nsErr];
				NSImage				*img = (imgRef==NULL) ? nil : [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(CGImageGetWidth(imgRef),CGImageGetHeight(imgRef))];
				self.thumb = img;
			}
			else if ([asset containsHapVideoTrack])	{
				NSArray				*assetHapTracks = [asset hapVideoTracks];
				AVAssetTrack		*hapTrack = assetHapTracks[0];
				//	make a hap output item- doesn't actually need a player...
				AVPlayerItemHapDXTOutput	*hapOutput = [[AVPlayerItemHapDXTOutput alloc] initWithHapAssetTrack:hapTrack];
				[hapOutput setSuppressesPlayerRendering:YES];
				[hapOutput setOutputAsRGB:YES];
				//	decode a frame
				HapDecoderFrame		*decodedFrame = [hapOutput allocFrameForTime:CMTimeMakeWithSeconds(0.0,[hapTrack naturalTimeScale])];
				//	make a bitmap rep & NSImage from the decoded frame
				unsigned char		*rgbPixels = (unsigned char *)[decodedFrame rgbData];
				size_t				rgbPixelsLength = [decodedFrame rgbDataSize];
				NSSize				rgbPixelsSize = [decodedFrame rgbImgSize];
				NSBitmapImageRep	*bitRep = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes:&rgbPixels
					pixelsWide:rgbPixelsSize.width
					pixelsHigh:rgbPixelsSize.height
					bitsPerSample:8
					samplesPerPixel:4
					hasAlpha:YES
					isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace
					//bitmapFormat:0	//	premultiplied, but alpha is last
					bitmapFormat:NSAlphaNonpremultipliedBitmapFormat	//	can't use this- graphics contexts cant use non-premultiplied bitmap reps as a backing
					bytesPerRow:rgbPixelsLength/rgbPixelsSize.height
					bitsPerPixel:32];	
				if (bitRep==nil)
					NSLog(@"\t\terr: couldn't make bitmap rep, %s, asset was %@",__func__,asset);
				else	{
					NSImage				*tmpImg = [[NSImage alloc] initWithSize:rgbPixelsSize];
					[tmpImg addRepresentation:bitRep];
					self.thumb = tmpImg;
				}
			}
			else	{
				//	do nothing: the asset is neither playable, nor hap
			}
		}
	}
	else if (self.type == OpType_Other)	{
		//	do nothing- don't make a thumb for a non-avf asset
	}
}


- (NSString *) createStatusString	{
	switch (self.status)	{
	case OpStatus_Pending:
		return @"Pending";
	case OpStatus_PreflightErr:
		return @"Preflight Err";
	case OpStatus_Analyze:
		return @"Analyzing";
	case OpStatus_Cleanup:
		return @"Cleaning up";
	case OpStatus_Complete:
		return @"Completed";
	case OpStatus_Err:
		return @"Error";
	}
	return @"???";
}
- (NSAttributedString *) createAttributedStatusString	{
	NSMutableAttributedString		*returnMe = nil;
	NSMutableParagraphStyle			*ps = nil;
	switch (self.status)	{
	case OpStatus_Pending:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Pending"];
		break;
	case OpStatus_PreflightErr:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Preflight Err"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(0,returnMe.length)];
		break;
	case OpStatus_Analyze:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Analyzing"];
		break;
	case OpStatus_Cleanup:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Cleaning up"];
		break;
	case OpStatus_Complete:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Completed"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:NSMakeRange(0,returnMe.length)];
		break;
	case OpStatus_Err:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Error"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(0,returnMe.length)];
		break;
	}
	if (returnMe == nil)
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"???"];
	ps = [[NSMutableParagraphStyle alloc] init];
	[ps setAlignment:NSTextAlignmentCenter];
	[returnMe addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0,returnMe.length)];
	return returnMe;
}


#pragma mark - control


- (void) start	{
	NSLog(@"%s ... %@",__func__,self);
	@synchronized (self)	{
		self.paused = NO;
		dispatch_async(dispatch_get_main_queue(), ^{
			[self _beginPreflight];
		});
	}
}
- (void) pause	{
	@synchronized (self)	{
		self.paused = YES;
		
		switch (self.status)	{
		case OpStatus_Pending:
			//	do nothing
			break;
		case OpStatus_PreflightErr:
			//	do nothing
			break;
		case OpStatus_Analyze:
			if (self.job != nil)	{
				[self.job setPaused:YES];
			}
			break;
		case OpStatus_Cleanup:
			//	should never happen- we only set this state inside self's synch lock, and it's set to another status (complete or err) before relinquishing the lock...
			break;
		case OpStatus_Complete:
			break;
		case OpStatus_Err:
			break;
		}
	}
}
- (void) resume	{
	@synchronized (self)	{
		self.paused = NO;
		
		switch (self.status)	{
		case OpStatus_Pending:
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self _beginPreflight];
				});
			}
			break;
		case OpStatus_PreflightErr:
			//	should never really happen?  status only set to this inside our synch lock, and we always call the delegate method immediately after?
			break;
		case OpStatus_Analyze:
			if (self.job != nil)	{
				[self.job setPaused:NO];
			}
			break;
		case OpStatus_Cleanup:
			break;
		case OpStatus_Complete:
			break;
		case OpStatus_Err:
			//	should never really happen? status only set to this inside our synch lock, and we always call the delegate method immediately after?
			break;
		}
	}
}
- (void) _beginPreflight	{
	NSLog(@"%s ... %@",__func__,self);
	@synchronized (self)	{
		__weak SynOp			*bss = self;
		//	if i don't have a session, something's wrong: bail (call my delegate 'finished' method)
		if (self.session == nil)	{
			self.status = OpStatus_PreflightErr;
			self.errString = @"Session not found!";
			dispatch_async(dispatch_get_main_queue(), ^{
				NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
				if (tmpDelegate != nil)
					[tmpDelegate synOpStatusFinished:bss];
			});
			return;
		}
	
		//	first collect some vals we're going to need for all of these permutations...
		NSFileManager		*fm = [NSFileManager defaultManager];
		BOOL				isDir = NO;
		NSString			*srcPathExtension = self.src.pathExtension;
		NSString			*srcFileName = [self.src.lastPathComponent stringByDeletingPathExtension];
		NSString			*dstFilename = [srcFileName stringByAppendingString:@"_analyzed"];
		NSString			*srcDir = [[[NSURL fileURLWithPath:self.src] URLByDeletingLastPathComponent] path];
	
		//	if my session is a dir-type
		if (self.session.type == SessionType_Dir)	{
			//	if my session has an outputDir, we need to recreate the hierarchy of the src dir within the outputDir
			if (self.session.outputDir != nil)	{
				//	this gets a little complicated.  we need to remove all shared path components between the session's src directory, and the src file this op needs to process
				NSMutableArray		*sessionSrcDirComps = [[[NSURL fileURLWithPath:self.session.srcDir isDirectory:YES] pathComponents] mutableCopy];
				NSMutableArray		*srcDirComps = [[[NSURL fileURLWithPath:srcDir isDirectory:YES] pathComponents] mutableCopy];
				do	{
					[sessionSrcDirComps removeObjectAtIndex:0];
					[srcDirComps removeObjectAtIndex:0];
				} while (sessionSrcDirComps.count>0 && srcDirComps.count>0 && [sessionSrcDirComps[0] isEqualToString:srcDirComps[0]]);
			
				//	...at this point, 'srcDirComps' contains the path components "inside the session's srcDir"- these are the subdirectories in the session's 'outputDir' that we need to create the file for this op inside.
				//	use these components to create the path inside the session's "outputDir"
				NSURL				*dstDirURL = [NSURL fileURLWithPath:self.session.outputDir isDirectory:YES];
				for (NSString * srcDirComp in srcDirComps)	{
					dstDirURL = [dstDirURL URLByAppendingPathComponent:srcDirComp isDirectory:YES];
				}
				//	now append the filename + extension...
				self.dst = [[[dstDirURL URLByAppendingPathComponent:dstFilename] URLByAppendingPathExtension:srcPathExtension] path];
			}
			//	else there's no outputDir- we're creating the dst files alongside their src files
			else	{
				self.dst = [[[[NSURL fileURLWithPath:srcDir isDirectory:YES]
					URLByAppendingPathComponent:dstFilename]
						URLByAppendingPathExtension:srcPathExtension]
							path];
			}
		
			//	if my session has a tempDir, the op will do the analysis to the tempDir, then copy it to the appropriate location during cleanup
			if (self.session.tempDir != nil)	{
				self.tmpFile = [[[[NSURL fileURLWithPath:self.session.tempDir isDirectory:YES]
					URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
						URLByAppendingPathExtension:srcPathExtension]
							path];
			}
		}
		//	else my session is a list-type
		else	{
			//	if my session has an outputDir, the dst files will all be in the output dir
			if (self.session.outputDir != nil)	{
				NSString		*outputDir = [[NSURL fileURLWithPath:self.session.outputDir isDirectory:YES] path];
				self.dst = [[[[NSURL fileURLWithPath:outputDir]
					URLByAppendingPathComponent:dstFilename]
						URLByAppendingPathExtension:srcPathExtension]
							path];
			}
			//	else there's no outputDir- we're creating the dst files alongside their src files
			else	{
				self.dst = [[[[NSURL fileURLWithPath:srcDir isDirectory:YES]
					URLByAppendingPathComponent:dstFilename]
						URLByAppendingPathExtension:srcPathExtension]
							path];
			}
		
			//	if my session has a tempDir, the op will do the analysis to the tempDir, then copy it to the appropriate location during cleanup
			if (self.session.tempDir != nil)	{
				self.tmpFile = [[[[NSURL fileURLWithPath:self.session.tempDir isDirectory:YES]
					URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
						URLByAppendingPathExtension:srcPathExtension]
							path];
			}
		}
	
		//	if there's a tmpFile...
		if (self.tmpFile != nil)	{
			//	check the tmpFile's parent directory- if it doesn't exist, create it (if we can't, bail with error)
			NSString		*tmpFileParentDir = [[[NSURL fileURLWithPath:self.tmpFile isDirectory:NO] URLByDeletingLastPathComponent] path];
			if (![fm fileExistsAtPath:tmpFileParentDir isDirectory:&isDir])	{
				if (![fm createDirectoryAtPath:tmpFileParentDir withIntermediateDirectories:YES attributes:nil error:nil])	{
					self.status = OpStatus_PreflightErr;
					self.errString = @"Couldn't create temp output directory";
					dispatch_async(dispatch_get_main_queue(), ^{
						NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
						if (tmpDelegate != nil)
							[tmpDelegate synOpStatusFinished:bss];
					});
					return;
				}
			}
		
			if (!isDir)	{
				self.status = OpStatus_PreflightErr;
				self.errString = @"Temp output directory not a directory";
				dispatch_async(dispatch_get_main_queue(), ^{
					NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
					if (tmpDelegate != nil)
						[tmpDelegate synOpStatusFinished:bss];
				});
				return;
			}
		
			//	if the tmpFile's parent directory isn't writable, bail with error
			if (![fm isWritableFileAtPath:tmpFileParentDir])	{
				self.status = OpStatus_PreflightErr;
				self.errString = @"Temp output directory not writable";
				dispatch_async(dispatch_get_main_queue(), ^{
					NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
					if (tmpDelegate != nil)
						[tmpDelegate synOpStatusFinished:bss];
				});
				return;
			}
		}
	
		//	if there's no dstFile...
		if (self.dst == nil)	{
			//	err out, something's wrong
			self.status = OpStatus_PreflightErr;
			self.errString = @"Couldn't find dst file!";
			dispatch_async(dispatch_get_main_queue(), ^{
				NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
				if (tmpDelegate != nil)
					[tmpDelegate synOpStatusFinished:bss];
			});
			return;
		}
		//	else there's a dstFile...
		else	{
			//	check the dstFile's parent directory- if it doesn't exist, create it (if we can't, bail with error)
			NSString		*dstFileParentDir = [[[NSURL fileURLWithPath:self.dst isDirectory:NO] URLByDeletingLastPathComponent] path];
			if (![fm fileExistsAtPath:dstFileParentDir isDirectory:&isDir])	{
				if (![fm createDirectoryAtPath:dstFileParentDir withIntermediateDirectories:YES attributes:nil error:nil])	{
					self.status = OpStatus_PreflightErr;
					self.errString = @"Couldn't create output directory";
					dispatch_async(dispatch_get_main_queue(), ^{
						NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
						if (tmpDelegate != nil)
							[tmpDelegate synOpStatusFinished:bss];
					});
					return;
				}
			}
		
			if (!isDir)	{
				self.status = OpStatus_PreflightErr;
				self.errString = @"Output directory not a directory";
				dispatch_async(dispatch_get_main_queue(), ^{
					NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
					if (tmpDelegate != nil)
						[tmpDelegate synOpStatusFinished:bss];
				});
				return;
			}
		
			//	if the dstFile's parent directory isn't writable, bail with error
			if (![fm isWritableFileAtPath:dstFileParentDir])	{
				self.status = OpStatus_PreflightErr;
				self.errString = @"Output directory not writable";
				dispatch_async(dispatch_get_main_queue(), ^{
					NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
					if (tmpDelegate != nil)
						[tmpDelegate synOpStatusFinished:bss];
				});
				return;
			}
		}
	
	
		//	...if we're here, preflight checked out, everything's ready to go...
	
	
		dispatch_async(dispatch_get_main_queue(), ^{
			[self _beginJob];
		});
	}
}
- (void) _beginJob	{
	NSLog(@"%s",__func__);
	
	@synchronized (self)	{
		//	if this isn't an AVF file, proceed directly to cleanup
		if (self.type != OpType_AVFFile)	{
			[self _beginCleanup];
			return;
		}
	
		//	...if we're here, we actually have some analyzing/transcoding to do!
		__weak SynOp		*bss = self;
		PresetObject		*sessionPreset = self.session.preset;
		if (sessionPreset == nil)	{
			self.status = OpStatus_PreflightErr;
			self.errString = @"Preset not found";
			dispatch_async(dispatch_get_main_queue(), ^{
				NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
				if (tmpDelegate != nil)
					[tmpDelegate synOpStatusFinished:bss];
			});
			return;
		}
	
		//PrefsController		*pc = [PrefsController global];
		//NSURL				*tempFolderURL = [pc tempFolderURL];
		NSDictionary			*synopsisOpts = @{
			kSynopsisAnalysisSettingsQualityHintKey : @( SynopsisAnalysisQualityHintMedium ),
			kSynopsisAnalysisSettingsEnabledPluginsKey : @[ @"StandardAnalyzerPlugin" ],
			kSynopsisAnalysisSettingsEnableConcurrencyKey : @YES,
			kSynopsisAnalyzedMetadataExportOptionKey: @( sessionPreset.metadataExportOption )
		};
		NSMutableDictionary		*videoOpts = (sessionPreset.videoSettings.settingsDictionary==nil) ? [NSMutableDictionary new] : [sessionPreset.videoSettings.settingsDictionary mutableCopy];
		if (!sessionPreset.useVideo)
			videoOpts[kSynopsisStripTrackKey] = @YES;
		NSMutableDictionary		*audioOpts = (sessionPreset.audioSettings.settingsDictionary==nil) ? [NSMutableDictionary new] : [sessionPreset.audioSettings.settingsDictionary mutableCopy];
		if (!sessionPreset.useAudio)
			audioOpts[kSynopsisStripTrackKey] = @YES;
	
		//NSLog(@"\tpreset: %@",sessionPreset);
		//NSLog(@"\tvideo: %@",videoOpts);
		//NSLog(@"\taudio: %@",audioOpts);
		//NSLog(@"\tsynopsis: %@",synopsisOpts);
	
		self.status = OpStatus_Analyze;
	
		self.job = [[SynopsisJobObject alloc]
			initWithSrcFile:(self.src==nil) ? nil : [NSURL fileURLWithPath:self.src]
			dstFile:(self.tmpFile!=nil) ? [NSURL fileURLWithPath:self.tmpFile] : [NSURL fileURLWithPath:self.dst]
			videoTransOpts:videoOpts
			audioTransOpts:audioOpts
			synopsisOpts:synopsisOpts
			completionBlock:^(SynopsisJobObject *finished)	{
				//NSLog(@"\tjob finished, status is %@",[SynopsisJobObject stringForStatus:finished.jobStatus]);
				//NSLog(@"\tjob err is %@",[SynopsisJobObject stringForErrorType:finished.jobErr]);
				//NSLog(@"\tjob err string is %@",finished.jobErrString);
				switch (finished.jobStatus)	{
				case JOStatus_Unknown:
				case JOStatus_NotStarted:
				case JOStatus_InProgress:
				case JOStatus_Paused:
					break;
				case JOStatus_Err:
					bss.status = OpStatus_Err;
					bss.errString = [SynopsisJobObject stringForErrorType:finished.jobErr];
					break;
				case JOStatus_Complete:
					//	intentionally blank- fall through, we want to run cleanup next
					break;
				case JOStatus_Cancel:
					bss.status = OpStatus_Pending;
					bss.errString = nil;
					break;
				}
			
				//	this block gets executed even if you cancel
				dispatch_async(dispatch_get_main_queue(), ^{
					[bss _beginCleanup];
				});
			}];
	
		[self.job start];
	}
}
- (void) _beginCleanup	{
	NSLog(@"%s ... %@",__func__,self);
	@synchronized (self)	{
		NSFileManager			*fm = [NSFileManager defaultManager];
		NSError					*nsErr = nil;
		__weak SynOp			*bss = self;
	
		//	if my status is 'error' (error during analysis) or 'pending' (user cancelled)
		if (self.status == OpStatus_Err || self.status == OpStatus_Pending)	{
			//	move tmp file to trash
			if (self.tmpFile != nil)	{
				[fm trashItemAtURL:[NSURL fileURLWithPath:self.tmpFile isDirectory:NO] resultingItemURL:nil error:&nsErr];
			}
			//	move dst file to trash
			if (self.dst != nil)	{
				[fm trashItemAtURL:[NSURL fileURLWithPath:self.dst isDirectory:NO] resultingItemURL:nil error:&nsErr];
			}
			//	bail- tell delegate we're done...
			dispatch_async(dispatch_get_main_queue(), ^{
				NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
				if (tmpDelegate != nil)
					[tmpDelegate synOpStatusFinished:bss];
			});
			return;
		}
	
	
		//	...if we're here, our status was something other than 'error'/'pending'- update my status property...
		self.status = OpStatus_Cleanup;
	
	
		//	if this is an AVF file...
		if (self.type == OpType_AVFFile)	{
			//	if there's a temp file, copy it to the dest file and then move the tmp file to the trash
			if (self.tmpFile != nil)	{
				if (![fm copyItemAtPath:self.tmpFile toPath:self.dst error:&nsErr])	{
					self.status = OpStatus_Err;
					self.errString = [NSString stringWithFormat:@"Couldn't copy tmp file to destination (%@)",nsErr.localizedDescription];
					dispatch_async(dispatch_get_main_queue(), ^{
						NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
						if (tmpDelegate != nil)
							[tmpDelegate synOpStatusFinished:bss];
					});
					return;
				}
			}
		
			//	if there's a script, run it on the dst file
			if (self.session.opScript != nil)	{
				NSLog(@"SHOULD BE RUNNING PYTHON SCRIPT HERE");
			}
		}
		//	else it's not an AVF file...
		else	{
			//	copy the src file to the dst file
			if (![fm copyItemAtPath:self.src toPath:self.dst error:&nsErr])	{
				self.status = OpStatus_Err;
				self.errString = [NSString stringWithFormat:@"Couldn't copy tmp file to destination (%@)",nsErr.localizedDescription];
				dispatch_async(dispatch_get_main_queue(), ^{
					NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
					if (tmpDelegate != nil)
						[tmpDelegate synOpStatusFinished:bss];
				});
				return;
			}
		}
	
	
		//	...if we're here, everything's done- update our status, and then notify the delegate that we're finished
	
	
		self.status = OpStatus_Complete;
	
		dispatch_async(dispatch_get_main_queue(), ^{
			NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
			if (tmpDelegate != nil)
				[tmpDelegate synOpStatusFinished:bss];
		});
	}
}
- (void) stop	{
	@synchronized (self)	{
		self.paused = NO;
		[self.job cancel];
	}
}
/*
- (void) running	{
}
*/


@end
