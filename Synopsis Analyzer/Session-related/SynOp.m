//
//	SynOp.m
//	Synopsis Analyzer
//
//	Created by testAdmin on 9/16/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import "SynOp.h"
#import "SessionController.h"
#import "SynSession.h"
#import "PrefsController.h"

#import <AVFoundation/AVFoundation.h>
#import <HapInAVFoundation/HapInAVFoundation.h>
#import "InspectorViewController.h"
#import <QuickLook/QuickLook.h>

#import "GPULoadBalancer.h"
#import "NSColor+SynopsisStatusColors.h"


static NSImage				*genericMovieImage = nil;




@interface SynOp()
@property (atomic,weak,nullable) NSObject<SynOpDelegate> * delegate;
@property (assign,readwrite,atomic) BOOL paused;
@property (atomic,readwrite,strong,nullable) NSString * tmpFile;
@property (atomic,strong,readwrite) NSUUID * dragUUID;	//	literally only used for drag-and-drop.
@property (atomic,strong,readwrite) SynopsisRemoteFileHelper * remoteFileHelper;
- (void) _beginPreflight;
- (void) _beginJob;
- (void) _beginCleanup;
- (void) _populateTypeProperty;
@end




@implementation SynOp


#pragma mark - NSCoding protocol


+ (NSImage *) genericMovieThumbnail	{
	return genericMovieImage;
}


- (instancetype) initWithSrcURL:(NSURL *)inSrc {
	//NSLog(@"%s ... %@",__func__,inSrc.path);
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
		self.dragUUID = [NSUUID UUID];
		self.remoteFileHelper = [[SynopsisRemoteFileHelper alloc] init];
		NSFileManager		*fm = [NSFileManager defaultManager];
		BOOL				isDir = NO;
		if (![fm fileExistsAtPath:[inSrc path] isDirectory:&isDir] || isDir)
			self = nil;
	}
	return self;
}
- (instancetype) initWithSrcPath:(NSString *)inSrc	{
	//NSLog(@"%s ... %@",__func__,inSrc);
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
		self.dragUUID = [NSUUID UUID];
		self.remoteFileHelper = [[SynopsisRemoteFileHelper alloc] init];
		NSFileManager		*fm = [NSFileManager defaultManager];
		BOOL				isDir = NO;
		if (![fm fileExistsAtPath:inSrc isDirectory:&isDir] || isDir)
			self = nil;
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder *)coder	{
	//NSLog(@"%s",__func__);
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
			//self.status = (![coder containsValueForKey:@"status"]) ? OpStatus_Pending : (OpStatus)[coder decodeInt64ForKey:@"status"];
			self.status = OpStatus_Pending;
			self.errString = nil;
			self.job = nil;
			self.delegate = [SessionController global];
			self.dragUUID = [NSUUID UUID];
			self.remoteFileHelper = [[SynopsisRemoteFileHelper alloc] init];
			NSFileManager		*fm = [NSFileManager defaultManager];
			BOOL				isDir = NO;
			if (![fm fileExistsAtPath:self.src isDirectory:&isDir] || isDir)
				self = nil;
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
		//[coder encodeInt64:(NSInteger)self.status forKey:@"status"];
	}
}
- (void) dealloc	{
	[[InspectorViewController global] uninspectItem:self];
}


#pragma mark - misc


- (NSString *) description	{
	return [NSString stringWithFormat:@"<SynOp: %@, %@>",self.src.lastPathComponent,[self createStatusString]];
}
/*
@synthesize thumb=myThumb;
- (void) setThumb:(NSImage *)n	{
	myThumb = n;
}
- (NSImage *) thumb	{
	if (myThumb == nil && self.session != nil && self.session.type == SessionType_List)	{
		//[self _populateThumb];
		//	generate thumbs on an async concurrent queue
		dispatch_async(iconGeneratorQueue, ^{
			[self _populateThumb];
		});
	}
	return myThumb;
}
*/
@synthesize session=mySession;
- (void) setSession:(SynSession *)n	{
	mySession = n;
	if (self.session.type == SessionType_List)	{
		//[self _populateThumb];
		/*
		//	generate thumbs on an async concurrent queue
		dispatch_async(iconGeneratorQueue, ^{
			[self _populateThumb];
		});
		*/
	}
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
			NSArray			*vidTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			BOOL			hasVidTracks = (vidTracks!=nil && vidTracks.count>0) ? YES : NO;
			//	if it's a simple AVF asset...
			if ([asset isPlayable] && hasVidTracks)	{
				self.type = OpType_AVFFile;
				//	if we haven't created the generic movie thumb yet, do so now
				if (genericMovieImage == nil)	{
					NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
					NSImage			*img = [ws iconForFile:self.src];
					genericMovieImage = img;
				}
			}
			//	else if the AVF asset has a hap track...
			else if ([asset containsHapVideoTrack])	{
				self.type = OpType_AVFFile;
				//	if we haven't created the generic movie thumb yet, do so now
				if (genericMovieImage == nil)	{
					NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
					NSImage			*img = [ws iconForFile:self.src];
					genericMovieImage = img;
				}
			}
			//	else it's not recognizable as an AVF asset (even though you could make an AVAsset from it)
			else	{
				self.type = OpType_Other;
			}
		}
	}
	
}
- (void) populateThumb	{
	//NSLog(@"%s ... %@",__func__,self);
	if (self.type == OpType_AVFFile)	{
		NSURL			*srcURL = [NSURL fileURLWithPath:self.src];
		AVAsset			*asset = [AVAsset assetWithURL:srcURL];
		if (asset == nil)	{
			//	non-avf asset: use finder icon
			NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
			NSImage			*img = [ws iconForFile:self.src];
			self.thumb = img;
		}
		else	{
			if ([asset containsHapVideoTrack])	{
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
					bitmapFormat:NSBitmapFormatAlphaNonpremultiplied	//	can't use this- graphics contexts cant use non-premultiplied bitmap reps as a backing
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
			else if ([asset isReadable])	{
				AVAssetImageGenerator		*gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
				gen.appliesPreferredTrackTransform = YES;
				gen.maximumSize = CGSizeMake(320, 240);
				NSError				*nsErr = nil;
				//CMTime				time = CMTimeMake(1,60);
				CGImageRef			imgRef = [gen copyCGImageAtTime:CMTimeMake(1,60) actualTime:NULL error:&nsErr];
				//NSImage				*img = (imgRef==NULL) ? nil : [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(CGImageGetWidth(imgRef),CGImageGetHeight(imgRef))];
				NSBitmapImageRep	*imgRep = (imgRef==NULL) ? nil : [[NSBitmapImageRep alloc] initWithCGImage:imgRef];
				NSImage				*img = (imgRep==nil) ? nil : [[NSImage alloc] initWithSize:[imgRep size]];
				if (img != nil)
					[img addRepresentation:imgRep];
				self.thumb = img;
			}
			else	{
				//	the asset is neither playable, nor hap: use a finder icon
				NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
				NSImage			*img = [ws iconForFile:self.src];
				self.thumb = img;
			}
		}
	}
	else if (self.type == OpType_Other)	{
		//	do nothing- don't make a thumb for a non-avf asset
	}
	
	//	if we successfully generated a thumb, we want to update any rows that are displaying me...
	if (self.thumb != nil)	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[[SessionController global] reloadRowForItem:self];
		});
	}
}


- (NSString *) createStatusString	{
	switch (self.status)	{
	case OpStatus_Pending:
		return @"Pending";
	case OpStatus_Preflight:
		return @"Preflight";
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
	case OpStatus_Preflight:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Preflight"];
		break;
	case OpStatus_PreflightErr:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Preflight Err"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor synopsisErrorColor] range:NSMakeRange(0,returnMe.length)];
		break;
	case OpStatus_Analyze:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Analyzing"];
		break;
	case OpStatus_Cleanup:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Cleaning up"];
		break;
	case OpStatus_Complete:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Completed"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor synopsisSuccessColor] range:NSMakeRange(0,returnMe.length)];
		break;
	case OpStatus_Err:
		returnMe = [[NSMutableAttributedString alloc] initWithString:@"Error"];
		[returnMe addAttribute:NSForegroundColorAttributeName value:[NSColor synopsisErrorColor] range:NSMakeRange(0,returnMe.length)];
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
	//NSLog(@"%s ... %@",__func__,self);
	@synchronized (self)	{
		self.paused = NO;
		self.status = OpStatus_Preflight;
		
		dispatch_async([[SessionController global] sessionQueue], ^{
			
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
		case OpStatus_Preflight:
			//	do nothing- but check 'paused' property before beginning job
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
				[self _beginPreflight];
			}
			break;
		case OpStatus_Preflight:
			{
				[self _beginJob];
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
	//NSLog(@"%s ... %@",__func__,self);
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
		
		self.status = OpStatus_Preflight;
	
		//	first collect some vals we're going to need for all of these permutations...
		NSFileManager		*fm = [NSFileManager defaultManager];
		BOOL				isDir = NO;
		//NSString			*srcPathExtension = self.src.pathExtension;
		NSString			*srcPathExtension = @"mov";	//	this app only exports quicktime movies (AVFoundation is not capable of writing metadata to mp4s)
		NSString			*srcFileName = [self.src.lastPathComponent stringByDeletingPathExtension];
		NSString			*dstFilename = (self.type==OpType_AVFFile) ? [srcFileName stringByAppendingString:@"_analyzed"] : srcFileName;
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
			
			//	if a file already exists at the tmp path, delete it
			if ([fm fileExistsAtPath:self.tmpFile isDirectory:NULL])	{
				NSError			*nsErr = nil;
				if (![fm removeItemAtPath:self.tmpFile error:&nsErr])	{
					self.status = OpStatus_PreflightErr;
					self.errString = [NSString stringWithFormat:@"Tmp file already exists, and cannot be deleted: %@",[nsErr localizedDescription]];
					dispatch_async(dispatch_get_main_queue(), ^{
						NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
						if (tmpDelegate != nil)
							[tmpDelegate synOpStatusFinished:bss];
					});
					return;
				}
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
			
			//	if a file already exists at the dst path, delete it
			if ([fm fileExistsAtPath:self.dst isDirectory:NULL])	{
				NSError			*nsErr = nil;
				if (![fm removeItemAtPath:self.dst error:&nsErr])	{
					self.status = OpStatus_PreflightErr;
					self.errString = [NSString stringWithFormat:@"Destination file already exists, and cannot be deleted: %@",[nsErr localizedDescription]];
					dispatch_async(dispatch_get_main_queue(), ^{
						NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
						if (tmpDelegate != nil)
							[tmpDelegate synOpStatusFinished:bss];
					});
					return;
				}
			}
		}
	
	
		//	...if we're here, preflight checked out, everything's ready to go...
	
	
		@synchronized (self)	{
			if (!self.paused)
				[self _beginJob];
		}
	}
}
- (void) _beginJob	{
	//NSLog(@"%s ... %@",__func__,self);
	
	@synchronized (self)	{
		//	if this isn't an AVF file, proceed directly to cleanup
		if (self.type != OpType_AVFFile)	{
			self.status = OpStatus_Analyze;
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
		NSDictionary			*synopsisOpts = (!sessionPreset.useAnalysis) ? nil : @{
			kSynopsisAnalysisSettingsQualityHintKey : @( SynopsisAnalysisQualityHintMedium ),
			kSynopsisAnalysisSettingsEnabledPluginsKey : @[ @"StandardAnalyzerPlugin" ],
			//kSynopsisAnalysisSettingsEnableConcurrencyKey : @YES,
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
	
		id<MTLDevice>device = [[GPULoadBalancer sharedBalancer] nextAvailableDevice];
		
		self.job = [[SynopsisJobObject alloc]
			initWithSrcFile:(self.src==nil) ? nil : [NSURL fileURLWithPath:self.src]
			dstFile:(self.tmpFile!=nil) ? [NSURL fileURLWithPath:self.tmpFile] : [NSURL fileURLWithPath:self.dst]
			videoTransOpts:videoOpts
			audioTransOpts:audioOpts
			synopsisOpts:synopsisOpts
			device:device
			completionBlock:^(SynopsisJobObject *finished)	{
				//NSLog(@"\tjob finished, status is %@",[SynopsisJobObject stringForStatus:finished.jobStatus]);
				//NSLog(@"\tjob err is %@",[SynopsisJobObject stringForErrorType:finished.jobErr]);
				//NSLog(@"\tjob err string is %@",finished.jobErrString);
				switch (finished.jobStatus) {
				case JOStatus_Unknown:
				case JOStatus_NotStarted:
				case JOStatus_InProgress:
				case JOStatus_Paused:
					break;
				case JOStatus_Err:
					bss.status = OpStatus_Err;
					//bss.errString = [SynopsisJobObject stringForErrorType:finished.jobErr];
					bss.errString = finished.jobErrString;
					break;
				case JOStatus_Complete:
					//	intentionally blank- fall through, we want to run cleanup next
					break;
				case JOStatus_Cancel:
					bss.status = OpStatus_Pending;
					bss.errString = nil;
					break;
				}
				
				[[GPULoadBalancer sharedBalancer] returnGPU:device from:finished];
				
				//	this block gets executed even if you cancel
				[bss _beginCleanup];
			}];
		
		[[GPULoadBalancer sharedBalancer] checkoutGPU:device forJob:self.job];
		
		[self.job start];
	}
}

- (void) _beginCleanup	{
	//NSLog(@"%s ... %@",__func__,self);
	@synchronized (self)	{
		NSFileManager			*fm = [NSFileManager defaultManager];
		NSError					*nsErr = nil;
		__weak SynOp			*bss = self;
		
		//	if my status is 'error' (error during analysis) or 'pending' (user cancelled)
		if (self.status == OpStatus_Err || self.status == OpStatus_Pending)	{
		
			// force dealloc of our expensive job object
			self.job = nil;
			
			NSLog(@"op %@ errored, tmpFile is %@, dstFile is %@",self,self.tmpFile.lastPathComponent,self.dst.lastPathComponent);
			//	move tmp file to trash
			if (self.tmpFile != nil)	{
				//[fm trashItemAtURL:[NSURL fileURLWithPath:self.tmpFile isDirectory:NO] resultingItemURL:nil error:&nsErr];
				[fm removeItemAtURL:[NSURL fileURLWithPath:self.tmpFile isDirectory:NO] error:&nsErr];
			}
			//	move dst file to trash
			if (self.dst != nil)	{
				//[fm trashItemAtURL:[NSURL fileURLWithPath:self.dst isDirectory:NO] resultingItemURL:nil error:&nsErr];
				[fm removeItemAtURL:[NSURL fileURLWithPath:self.dst isDirectory:NO] error:&nsErr];
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
		
		
		//	was our job object exporting a metadata sidecar file?
		BOOL			exportedSidecarFile = self.job.exportingToJSON;
		// force dealloc of our expensive job object
		self.job = nil;
		
		//	if this is an AVF file...
		if (self.type == OpType_AVFFile)	{
			//	if there's a temp file, move it to the dest file
			if (self.tmpFile != nil)	{
				NSURL			*tmpFileURL = [NSURL fileURLWithPath:self.tmpFile isDirectory:NO];
				NSURL			*dstFileURL = [NSURL fileURLWithPath:self.dst isDirectory:NO];
				BOOL			useRemotePath = [self.remoteFileHelper fileURLIsRemote:tmpFileURL] || [self.remoteFileHelper fileURLIsRemote:dstFileURL];
				//	if we're dealing with a remote file (network drive)
				if (useRemotePath)	{
					//	copy the tmp file to the dst location
					if (![self.remoteFileHelper safelyCopyFileURLOnRemoteFileSystem:tmpFileURL toURL:dstFileURL error:&nsErr])	{
						self.status = OpStatus_Err;
						self.errString = [NSString stringWithFormat:@"Couldn't copy tmp file to remote destination (%@)",nsErr.localizedDescription];
						dispatch_async(dispatch_get_main_queue(), ^{
							NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
							if (tmpDelegate != nil)
								[tmpDelegate synOpStatusFinished:bss];
						});
						return;
					}
					//	delete the tmp file
					if (![fm removeItemAtURL:tmpFileURL error:&nsErr])
					{
						self.status = OpStatus_Err;
						self.errString = [NSString stringWithFormat:@"Couldn't trash tmp file (%@)",nsErr.localizedDescription];
						dispatch_async(dispatch_get_main_queue(), ^{
							NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
							if (tmpDelegate != nil)
								[tmpDelegate synOpStatusFinished:bss];

						});
						return;
					}
				}
				//	else we're not dealing with a remote file- we're going to move the file instead of copying it...
				else	{
					//	move the tmp file to the dst location
					if (![fm moveItemAtPath:self.tmpFile toPath:self.dst error:&nsErr])	{
						self.status = OpStatus_Err;
						self.errString = [NSString stringWithFormat:@"Couldn't move tmp file to destination (%@)",nsErr.localizedDescription];
						dispatch_async(dispatch_get_main_queue(), ^{
							NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
							if (tmpDelegate != nil)
								[tmpDelegate synOpStatusFinished:bss];
						});
						return;
					}
				}
				
				//	if we're exporting a sidecar metadata file...
				if (exportedSidecarFile)	{
					NSURL			*tmpJSONFileURL = [NSURL fileURLWithPath:[self.tmpFile.stringByDeletingPathExtension stringByAppendingPathExtension:@"json"] isDirectory:NO];
					NSURL			*dstJSONFileURL = [NSURL fileURLWithPath:[self.dst.stringByDeletingPathExtension stringByAppendingPathExtension:@"json"] isDirectory:NO];
					//	if we're dealing with a remote file (network drive)
					if (useRemotePath)	{
						//	copy the tmp json file to the dst location
						if (![self.remoteFileHelper safelyCopyFileURLOnRemoteFileSystem:tmpJSONFileURL toURL:dstJSONFileURL error:&nsErr])	{
							self.status = OpStatus_Err;
							self.errString = [NSString stringWithFormat:@"Couldn't copy tmp JSON file to remote destination (%@)",nsErr.localizedDescription];
							dispatch_async(dispatch_get_main_queue(), ^{
								NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
								if (tmpDelegate != nil)
									[tmpDelegate synOpStatusFinished:bss];
							});
							return;
						}
						//	delete the tmp json file
						if (![fm removeItemAtURL:tmpJSONFileURL error:&nsErr])
						{
							self.status = OpStatus_Err;
							self.errString = [NSString stringWithFormat:@"Couldn't trash tmp JSON file (%@)",nsErr.localizedDescription];
							dispatch_async(dispatch_get_main_queue(), ^{
								NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
								if (tmpDelegate != nil)
									[tmpDelegate synOpStatusFinished:bss];

							});
							return;
						}
					}
					//	else we're not dealing with a remote file- we're going to move the file instead of copying it...
					else	{
						//	move the tmp json file to the dst location
						if (![fm moveItemAtPath:tmpJSONFileURL.path toPath:dstJSONFileURL.path error:&nsErr])	{
							self.status = OpStatus_Err;
							self.errString = [NSString stringWithFormat:@"Couldn't move tmp JSON file to destination (%@)",nsErr.localizedDescription];
							dispatch_async(dispatch_get_main_queue(), ^{
								NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
								if (tmpDelegate != nil)
									[tmpDelegate synOpStatusFinished:bss];
							});
							return;
						}
					}
				}
			}
			
			//	if there's a per-op script, run it on the dst file
			if (self.session.opScript != nil)	{
				NSLog(@"SHOULD BE RUNNING A SCRIPT HERE, %s",__func__);
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
- (void) checkForHang	{
	@synchronized (self)	{
		if (self.job != nil)
			[self.job checkForHang];
	}
}


#pragma mark - NSObject protocol


- (BOOL) isEqual:(id)n	{
	if (n == nil)
		return NO;
	if (![n isKindOfClass:[self class]])
		return NO;
	SynOp			*recast = (SynOp *)n;
	if (self.src != nil && recast.src != nil && [self.src isEqualToString:recast.src])
		return YES;
	return NO;
}


@end
