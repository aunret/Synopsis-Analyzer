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
		self.src = inSrc;
		self.dst = nil;
		self.thumb = nil;
		//self.type = OpType_Other;
		[self _populateTypePropertyAndThumb];
		self.status = OpStatus_Pending;
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
		AVAsset			*asset = [AVAsset assetWithURL:self.src];
		if (asset == nil)	{
			self.type = OpType_Other;
			NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
			NSImage			*tmpImg = [ws iconForFile:self.src.path];
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
				NSImage			*tmpImg = [ws iconForFile:self.src.path];
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


#pragma mark - control


- (void) start	{
}
- (void) stop	{
}
/*
- (void) running	{
}
*/


@end
