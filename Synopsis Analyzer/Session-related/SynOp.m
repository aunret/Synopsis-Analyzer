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
- (void) _populateTypePropertyAndThumb;
@end




@implementation SynOp


#pragma mark - NSCoding protocol


- (instancetype) initWithSrcURL:(NSURL *)inSrc	{
	self = [super init];
	if (self != nil)	{
		self.src = [inSrc path];
		self.dst = nil;
		self.thumb = nil;
		//self.type = OpType_Other;
		[self _populateTypePropertyAndThumb];
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
		self.thumb = nil;
		//self.type = OpType_Other;
		[self _populateTypePropertyAndThumb];
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
			[self _populateTypePropertyAndThumb];
			self.status = (![coder containsValueForKey:@"status"]) ? OpStatus_Pending : (OpStatus)[coder decodeIntForKey:@"status"];
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
		[coder encodeInt:(NSInteger)self.status forKey:@"status"];
	}
}


#pragma mark - misc


- (NSString *) description	{
	return [NSString stringWithFormat:@"<SynOp: %@>",self.src.lastPathComponent];
}


#pragma mark - backend


- (void) _populateTypePropertyAndThumb	{
	if (self.src == nil)
		self.type = OpType_Other;
	else	{
		AVAsset			*asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.src]];
		if (asset == nil)	{
			self.type = OpType_Other;
			NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
			NSImage			*tmpImg = [ws iconForFile:self.src];
			self.thumb = tmpImg;
		}
		else	{
			//	if it's a simple AVF asset...
			if ([asset isPlayable])	{
				self.type = OpType_AVFFile;
				AVAssetImageGenerator		*gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
				NSError				*nsErr = nil;
				CMTime				time = CMTimeMake(1,60);
				CGImageRef			imgRef = [gen copyCGImageAtTime:CMTimeMake(1,60) actualTime:NULL error:&nsErr];
				NSImage				*img = (imgRef==NULL) ? nil : [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(CGImageGetWidth(imgRef),CGImageGetHeight(imgRef))];
				self.thumb = img;
			}
			//	else if the AVF asset has a hap track...
			else if ([asset containsHapVideoTrack])	{
				self.type = OpType_AVFFile;
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
			//	else it's not recognizable as an AVF asset (even though you could make an AVAsset from it)
			else	{
				self.type = OpType_Other;
				NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
				NSImage			*tmpImg = [ws iconForFile:self.src];
				self.thumb = tmpImg;
			}
		}
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
- (NSAttributedString *_Nonnull) createAttributedStatusString	{
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
	PresetObject		*sessionPreset = self.session.preset;
	if (sessionPreset == nil)	{
		self.status = OpStatus_PreflightErr;
		[self.delegate synOpStatusFinished:self];
		return;
	}
	
	PrefsController		*pc = [PrefsController global];
	NSURL				*tempFolderURL = [pc tempFolderURL];
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
	
	__weak SynOp			*bss = self;
	self.job = [[SynopsisJobObject alloc]
		initWithSrcFile:(self.src==nil) ? nil : [NSURL fileURLWithPath:self.src]
		dstFile:(self.dst==nil) ? nil : [NSURL fileURLWithPath:self.dst]
		tmpDir:(tempFolderURL==nil) ? nil : tempFolderURL
		videoTransOpts:videoOpts
		audioTransOpts:audioOpts
		synopsisOpts:synopsisOpts
		completionBlock:^(SynopsisJobObject *finished)	{
			NSLog(@"\tjob finished, status is %@",[SynopsisJobObject stringForStatus:finished.jobStatus]);
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
				bss.status = OpStatus_Complete;
				bss.errString = nil;
				break;
			case JOStatus_Cancel:
				bss.status = OpStatus_Pending;
				bss.errString = nil;
				break;
			}
			
			//	this block gets executed even if you cancel
			dispatch_async(dispatch_get_main_queue(), ^{
				NSObject<SynOpDelegate>		*tmpDelegate = [bss delegate];
				if (tmpDelegate != nil)
					[tmpDelegate synOpStatusFinished:bss];
			});
		}];
	
	[self.job start];
	
}
- (void) stop	{
	[self.job cancel];
}
/*
- (void) running	{
}
*/


@end
