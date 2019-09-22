//
//  SynOp.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SynOp.h"
#import "SynSession.h"

#import <AVFoundation/AVFoundation.h>
#import <HapInAVFoundation/HapInAVFoundation.h>




@interface SynOp()
- (void) _populateTypeProperty;
@end




@implementation SynOp


#pragma mark - NSCoding protocol


- (id) initWithSrcURL:(NSURL *)inSrc	{
	self = [super init];
	if (self != nil)	{
		self.src = inSrc;
		self.dst = nil;
		//self.type = OpType_Other;
		[self _populateTypeProperty];
		self.status = OpStatus_Pending;
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder *)coder	{
	self = [super init];
	if (self != nil)	{
		if ([coder allowsKeyedCoding])	{
			self.src = (![coder containsValueForKey:@"src"]) ? nil : [coder decodeObjectForKey:@"src"];
			self.dst = (![coder containsValueForKey:@"dst"]) ? nil : [coder decodeObjectForKey:@"dst"];
			//if (![coder containsValueForKey:@"type"])
			//	self.type = [self _populateTypeProperty];
			//else
			//	self.type = (OpType)[coder decodeIntForKey:@"type"];
			[self _populateTypeProperty];
			self.status = (![coder containsValueForKey:@"status"]) ? OpStatus_Pending : (OpStatus)[coder decodeIntForKey:@"status"];
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


- (void) _populateTypeProperty	{
	if (self.src == nil)
		self.type = OpType_Other;
	else	{
		AVAsset			*asset = [AVAsset assetWithURL:self.src];
		if (asset == nil)
			self.type = OpType_Other;
		else	{
			if ([asset isPlayable] || [asset containsHapVideoTrack])
				self.type = OpType_AVFFile;
			else
				self.type = OpType_Other;
		}
	}
}


@end
