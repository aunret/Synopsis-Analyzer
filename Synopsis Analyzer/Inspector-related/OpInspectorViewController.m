//
//  OpInspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpInspectorViewController.h"

#import "SynOp.h"

#import "NSStringAdditions.h"




static NSString * FourCCString(FourCharCode code)	{
	NSString		*result = [NSString stringWithFormat:@"%c%c%c%c",(code>>24)&0xFF,(code>>16)&0xFF,(code>>8)&0xFF,code&0xFF];
	return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
//	this could totally be more efficient (use the actually fourcc instead of NSString)
static NSString * AudioFourCCStringToHumanReadableCodec(NSString *subType)	{
	NSString		*returnMe = nil;
	if ([subType caseInsensitiveCompare:@"lpcm"]==NSOrderedSame)
		returnMe = @"Linear PCM";
	else if ([subType caseInsensitiveCompare:@"ac-3"]==NSOrderedSame)
		returnMe = @"AC-3";
	else if ([subType caseInsensitiveCompare:@"cac3"]==NSOrderedSame)
		returnMe = @"AC-3 for transport";
	else if ([subType caseInsensitiveCompare:@"ima4"]==NSOrderedSame)
		returnMe = @"Apple IMA 4:1";
	else if ([subType caseInsensitiveCompare:@"aac"]==NSOrderedSame)
		returnMe = @"MPEG-4 Low Complexity AAC";
	else if ([subType caseInsensitiveCompare:@"celp"]==NSOrderedSame)
		returnMe = @"MPEG-4 CELP";
	else if ([subType caseInsensitiveCompare:@"hvxc"]==NSOrderedSame)
		returnMe = @"MPEG-4 HVXC";
	else if ([subType caseInsensitiveCompare:@"twvq"]==NSOrderedSame)
		returnMe = @"MPEG-4 TwinVQ";
	else if ([subType caseInsensitiveCompare:@"MAC3"]==NSOrderedSame)
		returnMe = @"MACE 3:1";
	else if ([subType caseInsensitiveCompare:@"MAC6"]==NSOrderedSame)
		returnMe = @"MACE 6:1";
	else if ([subType caseInsensitiveCompare:@"ulaw"]==NSOrderedSame)
		returnMe = @"µLaw 2:1";
	else if ([subType caseInsensitiveCompare:@"alaw"]==NSOrderedSame)
		returnMe = @"aLaw 2:1";
	else if ([subType caseInsensitiveCompare:@"QDMC"]==NSOrderedSame)
		returnMe = @"QDesign music";
	else if ([subType caseInsensitiveCompare:@"QDM2"]==NSOrderedSame)
		returnMe = @"QDesign2 music";
	else if ([subType caseInsensitiveCompare:@"Qclp"]==NSOrderedSame)
		returnMe = @"QUALCOMM PureVoice";
	else if ([subType caseInsensitiveCompare:@".mp1"]==NSOrderedSame)
		returnMe = @"MPEG-1/2, Layer 1";
	else if ([subType caseInsensitiveCompare:@".mp2"]==NSOrderedSame)
		returnMe = @"MPEG-1/2 Layer 2";
	else if ([subType caseInsensitiveCompare:@".mp3"]==NSOrderedSame)
		returnMe = @"MPEG-1/2, Layer 3";
	else if ([subType caseInsensitiveCompare:@"time"]==NSOrderedSame)
		returnMe = @"Timecode";
	else if ([subType caseInsensitiveCompare:@"midi"]==NSOrderedSame)
		returnMe = @"MIDI";
	else if ([subType caseInsensitiveCompare:@"apvs"]==NSOrderedSame)
		returnMe = @"Float32 Value Stream";
	else if ([subType caseInsensitiveCompare:@"alac"]==NSOrderedSame)
		returnMe = @"Apple Lossless";
	else if ([subType caseInsensitiveCompare:@"aach"]==NSOrderedSame)
		returnMe = @"MPEG-4 High Efficiency AAC";
	else if ([subType caseInsensitiveCompare:@"aacl"]==NSOrderedSame)
		returnMe = @"MPEG-4 AAC Low Delay";
	else if ([subType caseInsensitiveCompare:@"aace"]==NSOrderedSame)
		returnMe = @"MPEG-4 AAC Enhanced Low Delay";
	else if ([subType caseInsensitiveCompare:@"aacf"]==NSOrderedSame)
		returnMe = @"MPEG-4 AAC, SBR";
	//else if ([subType caseInsensitiveCompare:@"aacg"]==NSOrderedSame)
	//	returnMe = @"";	//	not listed in the enums?  CoreAudioTypes.h
	else if ([subType caseInsensitiveCompare:@"aacp"]==NSOrderedSame)
		returnMe = @"MPEG-4 High Efficiency AAC";
	else if ([subType caseInsensitiveCompare:@"aacs"]==NSOrderedSame)
		returnMe = @"MPEG-4 Spatial Audio";
	else if ([subType caseInsensitiveCompare:@"samr"]==NSOrderedSame)
		returnMe = @"AMR Narrow Band";
	else if ([subType caseInsensitiveCompare:@"sawb"]==NSOrderedSame)
		returnMe = @"AMR Wide Band";
	else if ([subType caseInsensitiveCompare:@"AUDB"]==NSOrderedSame)
		returnMe = @"Audible Audio Book";
	else if ([subType caseInsensitiveCompare:@"ilbc"]==NSOrderedSame)
		returnMe = @"iLBC Narrow Band";
	else if ([subType caseInsensitiveCompare:@"aes3"]==NSOrderedSame)
		returnMe = @"AES3-2003";
	else if ([subType caseInsensitiveCompare:@"ec-3"]==NSOrderedSame)
		returnMe = @"Enhanced AC-3";
	else if ([subType caseInsensitiveCompare:@"flac"]==NSOrderedSame)
		returnMe = @"Free Lossless";
	else if ([subType caseInsensitiveCompare:@"opus"]==NSOrderedSame)
		returnMe = @"Opus";
	
	if (returnMe == nil)
		returnMe = [NSString stringWithFormat:@"Unrecognized (%@)",subType];
	
	return returnMe;
}
//	this could totally be more efficient (use the actually fourcc instead of NSString)
static NSString * VideoFourCCStringToHumanReadableCodec(NSString *subtype)	{
	NSString		*returnMe = nil;
	if ([subtype isEqualToString:@""])
		returnMe = @"Uncompressed";
	else if ([subtype caseInsensitiveCompare:@"1"] == NSOrderedSame)
		returnMe = @"Uncompressed 1-bit Indexed Color";
	else if ([subtype caseInsensitiveCompare:@"2"] == NSOrderedSame)
		returnMe = @"Uncompressed 2-bit Indexed Color";
	else if ([subtype caseInsensitiveCompare:@"2vuy"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 8-bit 4:2:2 ordered Cb Y'0 Cr Y'1";
	else if ([subtype caseInsensitiveCompare:@"4"] == NSOrderedSame)
		returnMe = @"Uncompressed 4-bit Indexed Color";
	else if ([subtype caseInsensitiveCompare:@"8"] == NSOrderedSame)
		returnMe = @"Uncompressed 8-bit Indexed Color";
	else if ([subtype caseInsensitiveCompare:@"8BPS"] == NSOrderedSame)
		returnMe = @"Planar RGB";
	else if ([subtype caseInsensitiveCompare:@"16"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit RGB 555 (Big Endian)";
	else if ([subtype caseInsensitiveCompare:@"24"] == NSOrderedSame)
		returnMe = @"Uncompressed 24-bit RGB";
	else if ([subtype caseInsensitiveCompare:@"24BG"] == NSOrderedSame)
		returnMe = @"Uncompressed 24-bit BGR";
	else if ([subtype caseInsensitiveCompare:@"32"] == NSOrderedSame)
		returnMe = @"Uncompressed 32-bit ARGB";
	else if ([subtype caseInsensitiveCompare:@"33"] == NSOrderedSame)
		returnMe = @"Uncompressed 1-bit Grayscale";
	else if ([subtype caseInsensitiveCompare:@"34"] == NSOrderedSame)
		returnMe = @"Uncompressed 2-bit Grayscale";
	else if ([subtype caseInsensitiveCompare:@"36"] == NSOrderedSame)
		returnMe = @"Uncompressed 4-bit Grayscale";
	else if ([subtype caseInsensitiveCompare:@"40"] == NSOrderedSame)
		returnMe = @"Uncompressed 8-bit Grayscale";
	else if ([subtype caseInsensitiveCompare:@"5551"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit RGB 5551 (Little Endian)";
	else if ([subtype caseInsensitiveCompare:@"a2vy"] == NSOrderedSame)
		returnMe = @"Two-Plane Component Y'CbCr,A 8-bit 4:2:2,4";
	else if ([subtype caseInsensitiveCompare:@"ABGR"] == NSOrderedSame)
		returnMe = @"Uncompressed 32-bit ABGR";
	else if ([subtype caseInsensitiveCompare:@"ai5p"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 720p24/30/60";
	else if ([subtype caseInsensitiveCompare:@"ai5q"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 720p25/50";
	else if ([subtype caseInsensitiveCompare:@"ai52"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 1080p25/50";
	else if ([subtype caseInsensitiveCompare:@"ai53"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 1080p24/30/60";
	else if ([subtype caseInsensitiveCompare:@"ai55"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 1080i50";
	else if ([subtype caseInsensitiveCompare:@"ai56"] == NSOrderedSame)
		returnMe = @"AVC-Intra  50M 1080i60";
	else if ([subtype caseInsensitiveCompare:@"ai1p"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 720p24/30/60";
	else if ([subtype caseInsensitiveCompare:@"ai1q"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 720p25/50";
	else if ([subtype caseInsensitiveCompare:@"ai12"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 1080p25/50";
	else if ([subtype caseInsensitiveCompare:@"ai13"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 1080p24/30/60";
	else if ([subtype caseInsensitiveCompare:@"ai15"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 1080i50";
	else if ([subtype caseInsensitiveCompare:@"ai16"] == NSOrderedSame)
		returnMe = @"AVC-Intra 100M 1080i60";
	else if ([subtype caseInsensitiveCompare:@"ACTL"] == NSOrderedSame)
		returnMe = @"Streambox ACT-L2";
	else if ([subtype caseInsensitiveCompare:@"ap4h"] == NSOrderedSame)
		returnMe = @"Apple ProRes 4444";
	else if ([subtype caseInsensitiveCompare:@"ap4x"] == NSOrderedSame)
		returnMe = @"Apple ProRes 4444 (XQ)";
	else if ([subtype caseInsensitiveCompare:@"apch"] == NSOrderedSame)
		returnMe = @"Apple ProRes 422 (HQ)";
	else if ([subtype caseInsensitiveCompare:@"apcn"] == NSOrderedSame)
		returnMe = @"Apple ProRes 422";
	else if ([subtype caseInsensitiveCompare:@"apco"] == NSOrderedSame)
		returnMe = @"Apple ProRes 422 (Proxy)";
	else if ([subtype caseInsensitiveCompare:@"apcs"] == NSOrderedSame)
		returnMe = @"Apple ProRes 422 (LT)";
	else if ([subtype caseInsensitiveCompare:@"avc1"] == NSOrderedSame)
		returnMe = @"H.264";
	else if ([subtype caseInsensitiveCompare:@"AVdn"] == NSOrderedSame)
		returnMe = @"Avid DNxHD";
	else if ([subtype caseInsensitiveCompare:@"AVRn"] == NSOrderedSame)
		returnMe = @"Avid Motion JPEG";
	else if ([subtype caseInsensitiveCompare:@"AVDJ"] == NSOrderedSame)
		returnMe = @"Avid Motion JPEG";
	else if ([subtype caseInsensitiveCompare:@"ADJV"] == NSOrderedSame)
		returnMe = @"Avid Motion JPEG";
	else if ([subtype caseInsensitiveCompare:@"avr"] == NSOrderedSame)
		returnMe = @"Motion JPEG AVR";
	else if ([subtype caseInsensitiveCompare:@"b16g"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit Grayscale";
	else if ([subtype caseInsensitiveCompare:@"b32a"] == NSOrderedSame)
		returnMe = @"Uncompressed 32-bit AlphaGray";
	else if ([subtype caseInsensitiveCompare:@"b48r"] == NSOrderedSame)
		returnMe = @"Uncompressed 48-bit RGB";
	else if ([subtype caseInsensitiveCompare:@"b64a"] == NSOrderedSame)
		returnMe = @"Uncompressed 64-bit ARGB";
	else if ([subtype caseInsensitiveCompare:@"B565"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit RGB 565 (Big Endian)";
	else if ([subtype caseInsensitiveCompare:@"BGRA"] == NSOrderedSame)
		returnMe = @"Uncompressed 32-bit BGRA";
	else if ([subtype caseInsensitiveCompare:@"cvid"] == NSOrderedSame)
		returnMe = @"Cinepak";
	else if ([subtype caseInsensitiveCompare:@"dmb1"] == NSOrderedSame)
		returnMe = @"Motion JPEG OpenDML";
	else if ([subtype caseInsensitiveCompare:@"drmi"] == NSOrderedSame)
		returnMe = @"AVC0 Media";
	else if ([subtype caseInsensitiveCompare:@"dv1p"] == NSOrderedSame)
		returnMe = @"DV Video C Pro 100 PAL";
	else if ([subtype caseInsensitiveCompare:@"dv1n"] == NSOrderedSame)
		returnMe = @"DV Video C Pro 100 NTSC";
	else if ([subtype caseInsensitiveCompare:@"dv5n"] == NSOrderedSame)
		returnMe = @"DVCPRO50 - NTSC";
	else if ([subtype caseInsensitiveCompare:@"dv5p"] == NSOrderedSame)
		returnMe = @"DVCPRO50 - PAL";
	else if ([subtype caseInsensitiveCompare:@"dvc"] == NSOrderedSame)
		returnMe = @"DV/DVCPRO NTSC";
	else if ([subtype caseInsensitiveCompare:@"dvcp"] == NSOrderedSame)
		returnMe = @"DVC - PAL";
	else if ([subtype caseInsensitiveCompare:@"dvh2"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (1080p25)";
	else if ([subtype caseInsensitiveCompare:@"dvh3"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (1080p30)";
	else if ([subtype caseInsensitiveCompare:@"dvh5"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (1080i50)";
	else if ([subtype caseInsensitiveCompare:@"dvh6"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (1080i60)";
	else if ([subtype caseInsensitiveCompare:@"dvhp"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (720p60)";
	else if ([subtype caseInsensitiveCompare:@"dvhq"] == NSOrderedSame)
		returnMe = @"DVCPRO HD (720p50)";
	else if ([subtype caseInsensitiveCompare:@"dvp"] == NSOrderedSame)
		returnMe = @"DV Video Pro";
	else if ([subtype caseInsensitiveCompare:@"dvpp"] == NSOrderedSame)
		returnMe = @"DVCPRO - PAL";
	else if ([subtype caseInsensitiveCompare:@"flv"] == NSOrderedSame)
		returnMe = @"Flash";
	else if ([subtype caseInsensitiveCompare:@"gif"] == NSOrderedSame)
		returnMe = @"GIF";
	else if ([subtype caseInsensitiveCompare:@"h261"] == NSOrderedSame)
		returnMe = @"H.261";
	else if ([subtype caseInsensitiveCompare:@"h263"] == NSOrderedSame)
		returnMe = @"H.263";
	else if ([subtype caseInsensitiveCompare:@"h264"] == NSOrderedSame)
		returnMe = @"H.264";
	else if ([subtype caseInsensitiveCompare:@"hdv1"] == NSOrderedSame)
		returnMe = @"HDV (720p30)";
	else if ([subtype caseInsensitiveCompare:@"hdv2"] == NSOrderedSame)
		returnMe = @"HDV (1080i60)";
	else if ([subtype caseInsensitiveCompare:@"hdv3"] == NSOrderedSame)
		returnMe = @"HDV (1080i50)";
	else if ([subtype caseInsensitiveCompare:@"hdv4"] == NSOrderedSame)
		returnMe = @"HDV (720p24)";
	else if ([subtype caseInsensitiveCompare:@"hdv5"] == NSOrderedSame)
		returnMe = @"HDV (720p25)";
	else if ([subtype caseInsensitiveCompare:@"hdv6"] == NSOrderedSame)
		returnMe = @"HDV (1080p24)";
	else if ([subtype caseInsensitiveCompare:@"hdv7"] == NSOrderedSame)
		returnMe = @"HDV (1080p25)";
	else if ([subtype caseInsensitiveCompare:@"hdv8"] == NSOrderedSame)
		returnMe = @"HDV (1080p30)";
	else if ([subtype caseInsensitiveCompare:@"hdv9"] == NSOrderedSame)
		returnMe = @"HDV (720p60)";
	else if ([subtype caseInsensitiveCompare:@"hdva"] == NSOrderedSame)
		returnMe = @"HDV (720p50)";
	else if ([subtype caseInsensitiveCompare:@"icod"] == NSOrderedSame)
		returnMe = @"Apple Intermediate Codec";
	else if ([subtype caseInsensitiveCompare:@"IV41"] == NSOrderedSame)
		returnMe = @"Intel Indeo Video 4.3";
	else if ([subtype caseInsensitiveCompare:@"IV50"] == NSOrderedSame)
		returnMe = @"Indeo video 5.1";
	else if ([subtype caseInsensitiveCompare:@"jpeg"] == NSOrderedSame)
		returnMe = @"Photo - JPEG";
	else if ([subtype caseInsensitiveCompare:@"Jvt3"] == NSOrderedSame)
		returnMe = @"Apple H.264/AVC Video (Preview)";
	else if ([subtype caseInsensitiveCompare:@"L555"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit RGB 555 (Little Endian)";
	else if ([subtype caseInsensitiveCompare:@"L565"] == NSOrderedSame)
		returnMe = @"Uncompressed 16-bit RGB 565 (Little Endian)";
	else if ([subtype caseInsensitiveCompare:@"mjp2"] == NSOrderedSame)
		returnMe = @"JPEG 2000";
	else if ([subtype caseInsensitiveCompare:@"mjpa"] == NSOrderedSame)
		returnMe = @"Motion JPEG A";
	else if ([subtype caseInsensitiveCompare:@"mjpb"] == NSOrderedSame)
		returnMe = @"Motion JPEG B";
	else if ([subtype caseInsensitiveCompare:@"mjpg"] == NSOrderedSame)
		returnMe = @"Motion JPEG";
	else if ([subtype caseInsensitiveCompare:@"mpg4"] == NSOrderedSame)
		returnMe = @"MPEG-4 Video";
	else if ([subtype caseInsensitiveCompare:@"mp1v"] == NSOrderedSame)
		returnMe = @"MPEG-1 Video";
	else if ([subtype caseInsensitiveCompare:@"mp2v"] == NSOrderedSame)
		returnMe = @"MPEG-2 Video";
	else if ([subtype caseInsensitiveCompare:@"mp4v"] == NSOrderedSame)
		returnMe = @"MPEG-4 Video";
	else if ([subtype caseInsensitiveCompare:@"mplo"] == NSOrderedSame)
		returnMe = @"Implode";
	else if ([subtype caseInsensitiveCompare:@"png"] == NSOrderedSame)
		returnMe = @"PNG";
	else if ([subtype caseInsensitiveCompare:@"pxlt"] == NSOrderedSame)
		returnMe = @"Apple Pixlet Video";
	else if ([subtype caseInsensitiveCompare:@"r210"] == NSOrderedSame)
		returnMe = @"Blackmagic Uncompressed RAW 10bit";
	else if ([subtype caseInsensitiveCompare:@"r408"] == NSOrderedSame)
		returnMe = @"Component Y'CbCrA 8-bit 4:4:4:4 ordered A Y' Cb Cr";
	else if ([subtype caseInsensitiveCompare:@"RGBA"] == NSOrderedSame)
		returnMe = @"Uncompressed 32-bit RGBA";
	else if ([subtype caseInsensitiveCompare:@"rle"] == NSOrderedSame)
		returnMe = @"Animation";
	else if ([subtype caseInsensitiveCompare:@"rpza"] == NSOrderedSame)
		returnMe = @"Video";
	else if ([subtype caseInsensitiveCompare:@"s263"] == NSOrderedSame)
		returnMe = @"H.263";
	else if ([subtype caseInsensitiveCompare:@"smc"] == NSOrderedSame)
		returnMe = @"Graphics";
	else if ([subtype caseInsensitiveCompare:@"theo"] == NSOrderedSame)
		returnMe = @"Xiph.org's Theora Video";
	else if ([subtype caseInsensitiveCompare:@"v210"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 10-bit 4:2:2";
	else if ([subtype caseInsensitiveCompare:@"v216"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 10,12,14,16-bit 4:2:2";
	else if ([subtype caseInsensitiveCompare:@"v264"] == NSOrderedSame)
		returnMe = @"H.264";
	else if ([subtype caseInsensitiveCompare:@"v308"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 8-bit 4:4:4";
	else if ([subtype caseInsensitiveCompare:@"v408"] == NSOrderedSame)
		returnMe = @"Component Y'CbCrA 8-bit 4:4:4:4 ordered Cb Y' Cr A";
	else if ([subtype caseInsensitiveCompare:@"v410"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 10-bit 4:4:4";
	else if ([subtype caseInsensitiveCompare:@"VP30"] == NSOrderedSame)
		returnMe = @"On2 VP3 Video 3.2";
	else if ([subtype caseInsensitiveCompare:@"VP31"] == NSOrderedSame)
		returnMe = @"On2 VP3 Video 3.2";
	else if ([subtype caseInsensitiveCompare:@"VP50"] == NSOrderedSame)
		returnMe = @"On2's VP5 Video";
	else if ([subtype caseInsensitiveCompare:@"VP60"] == NSOrderedSame)
		returnMe = @"On2's VP6 Video";
	else if ([subtype caseInsensitiveCompare:@"VP70"] == NSOrderedSame)
		returnMe = @"On2's VP7 Video";
	else if ([subtype caseInsensitiveCompare:@"wmv1"] == NSOrderedSame)
		returnMe = @"Windows Media Video 7";
	else if ([subtype caseInsensitiveCompare:@"wmv2"] == NSOrderedSame)
		returnMe = @"Windows Media Video 8";
	else if ([subtype caseInsensitiveCompare:@"wmv3"] == NSOrderedSame)
		returnMe = @"Windows Media Video 9";
	else if ([subtype caseInsensitiveCompare:@"x264"] == NSOrderedSame)
		returnMe = @"H.264";
	else if ([subtype caseInsensitiveCompare:@"xd5a"] == NSOrderedSame)
		returnMe = @"XDCAM HD422 (720p50)";
	else if ([subtype caseInsensitiveCompare:@"xd59"] == NSOrderedSame)
		returnMe = @"XDCAM HD422 (720p60)";
	else if ([subtype caseInsensitiveCompare:@"xdv1"] == NSOrderedSame)
		returnMe = @"XDCAM EX (720p30)";
	else if ([subtype caseInsensitiveCompare:@"xdv2"] == NSOrderedSame)
		returnMe = @"XDCAM HD (1080i60)";
	else if ([subtype caseInsensitiveCompare:@"xdv3"] == NSOrderedSame)
		returnMe = @"XDCAM HD (1080i50)";
	else if ([subtype caseInsensitiveCompare:@"xdv4"] == NSOrderedSame)
		returnMe = @"XDCAM EX (720p24)";
	else if ([subtype caseInsensitiveCompare:@"xdv5"] == NSOrderedSame)
		returnMe = @"XDCAM EX (720p25)";
	else if ([subtype caseInsensitiveCompare:@"xdv6"] == NSOrderedSame)
		returnMe = @"XDCAM HD (1080p24)";
	else if ([subtype caseInsensitiveCompare:@"xdv7"] == NSOrderedSame)
		returnMe = @"XDCAM HD (1080p25)";
	else if ([subtype caseInsensitiveCompare:@"xdv8"] == NSOrderedSame)
		returnMe = @"XDCAM HD (1080p30)";
	else if ([subtype caseInsensitiveCompare:@"xdv9"] == NSOrderedSame)
		returnMe = @"XDCAM EX (720p60)";
	else if ([subtype caseInsensitiveCompare:@"xdva"] == NSOrderedSame)
		returnMe = @"XDCAM EX (720p50)";
	else if ([subtype caseInsensitiveCompare:@"xplo"] == NSOrderedSame)
		returnMe = @"Implode";
	else if ([subtype caseInsensitiveCompare:@"y420"] == NSOrderedSame)
		returnMe = @"Three-Plane Component Y'CbCr 8-bit 4:2:0";
	else if ([subtype caseInsensitiveCompare:@"yuvs"] == NSOrderedSame)
		returnMe = @"Component Y'CbCr 8-bit 4:2:2 ordered Y'0 Cb Y'1 Cr";
	else if ([subtype caseInsensitiveCompare:@"zygo"] == NSOrderedSame)
		returnMe = @"ZyGoVideo";
	
	if (returnMe == nil)
		returnMe = [NSString stringWithFormat:@"Unrecognized (%@)",subtype];
	
	return returnMe;
}




@interface OpInspectorViewController ()
@end




@implementation OpInspectorViewController


- (id) initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle	{
	//NSLog(@"%s",__func__);
	self = [super initWithNibName:inNibName bundle:inBundle];
	if (self != nil)	{
	}
	return self;
}
- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
	[super viewDidLoad];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
}
- (void) inspectOp:(SynOp *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	self.inspectedObject = n;
	
	[self updateUI];
}
- (void) updateUI	{
	if (self.inspectedObject == nil)	{
		return;
	}
	
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateUI];
		});
		return;
	}
	//NSLog(@"%s",__func__);
	
	
	if (self.inspectedObject.type == OpType_Other)	{
		//	populate the field field
		//	populate the video field
		//	populate the auido field
	}
	else	{
		AVAsset						*asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:self.inspectedObject.src isDirectory:NO]];
		
		NSString						*tmpString = nil;
		NSMutableAttributedString		*tmpAttrString = nil;
		//NSMutableParagraphStyle			*ps = nil;
	
		NSMutableAttributedString		*fileString = [[NSMutableAttributedString alloc] initWithString:@""];
		NSMutableAttributedString		*videoString = [[NSMutableAttributedString alloc] initWithString:@""];
		NSMutableAttributedString		*audioString = [[NSMutableAttributedString alloc] initWithString:@""];
	
		//	populate the file string
		{
			//	filename
			tmpString = self.inspectedObject.src.lastPathComponent.stringByDeletingPathExtension;
			tmpAttrString = [[NSMutableAttributedString alloc] initWithString:tmpString];
			[tmpAttrString
				addAttribute:NSFontAttributeName
				value:[NSFont systemFontOfSize:[NSFont systemFontSize]]
				range:NSMakeRange(0,tmpAttrString.length)];
			[fileString appendAttributedString:tmpAttrString];
			
			
			[fileString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n\n"]];
			
			
			//	file type
			NSString			*extension = self.inspectedObject.src.pathExtension;
			if (extension != nil)	{
				tmpAttrString = nil;
				if ([extension caseInsensitiveCompare:@"mp4"] == NSOrderedSame)	{
					//[description appendString:@"MPEG-4 movie\n"];
					tmpAttrString = [[NSMutableAttributedString alloc] initWithString:@"MPEG-4 movie"];
				}
				else if ([extension caseInsensitiveCompare:@"mov"] == NSOrderedSame)	{
					//[description appendString:@"QuickTime movie\n"];
					tmpAttrString = [[NSMutableAttributedString alloc] initWithString:@"QuickTime movie"];
				}
				if (tmpAttrString != nil)	{
					[tmpAttrString
						addAttribute:NSFontAttributeName
						value:[NSFont labelFontOfSize:[NSFont labelFontSize]]
						range:NSMakeRange(0,[tmpAttrString length])];
					[fileString appendAttributedString:tmpAttrString];
				
				
					[fileString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n\n"]];
				}
			}
			
			
			//	full path to file
			tmpString = self.inspectedObject.src;
			tmpAttrString = [[NSMutableAttributedString alloc] initWithString:tmpString];
			[tmpAttrString 
				addAttribute:NSFontAttributeName
				value:[NSFont labelFontOfSize:[NSFont labelFontSize]]
				range:NSMakeRange(0,tmpAttrString.length)];
			[fileString appendAttributedString:tmpAttrString];
			
			
			[fileString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n\n"]];
			
			
			//	duration of file
			NSArray<AVAssetTrack*>		*visualTracks = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
			if (visualTracks!=nil && visualTracks.count > 0)	{
				AVAssetTrack		*videoTrack = visualTracks[0];
				CMTime				tmpTime = [asset duration];
				double				tmpDouble = [videoTrack nominalFrameRate];
				NSString			*tmpString = (asset==nil) ? nil : [NSString smpteStringForTimeInSeconds:CMTimeGetSeconds(tmpTime) withFPS:tmpDouble];
				if (tmpString != nil)	{
					tmpString = [NSString stringWithFormat:@"Duration: %@",tmpString];
					tmpAttrString = [[NSMutableAttributedString alloc] initWithString:tmpString];
					[tmpAttrString
						addAttribute:NSFontAttributeName
						value:[NSFont labelFontOfSize:[NSFont labelFontSize]]
						range:NSMakeRange(0,tmpAttrString.length)];
					[fileString appendAttributedString:tmpAttrString];
				
				
					//[fileString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n\n"]];
				}
				
				
				[fileField setAttributedStringValue:fileString];
				[fileField setAllowsEditingTextAttributes:YES];
				[fileField sizeToFit];
			}
		}
	
		
		//	populate the video string
		{
			tmpString = nil;
			NSArray<AVAssetTrack*>		*tracks = [asset tracks];
			int							trackIndex = 1;
			for (AVAssetTrack *track in tracks)	{
				BOOL				isVideoTrack = NO;
				AVMediaType			trackMediaType = [track mediaType];
				//NSLog(@"\t\tprocessing track %@, media type is %@",track,trackMediaType);
				if ([trackMediaType isEqualToString:AVMediaTypeMuxed])	{
					isVideoTrack = YES;
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						CMMediaType			mediaType = CMFormatDescriptionGetMediaType(desc);
						NSString			*subtype = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						NSString			*humanReadable = nil;
						switch (mediaType)	{
						case kCMMediaType_Video:
							humanReadable = VideoFourCCStringToHumanReadableCodec(subtype);
							break;
						case kCMMediaType_Audio:
							humanReadable = AudioFourCCStringToHumanReadableCodec(subtype);
							break;
						//case kCMMediaType_Muxed:
						case kCMMediaType_Text:
							humanReadable = @"Text";
							break;
						case kCMMediaType_ClosedCaption:
							humanReadable = @"Closed Caption";
							break;
						case kCMMediaType_Subtitle:
							humanReadable = @"Subtitle";
							break;
						case kCMMediaType_TimeCode:
							humanReadable = @"Timecode";
							break;
						//	weird, not recognized for some reason?
						//case kCMMediaType_TimedMetadata:
						//	humanReadable = @"Timed Metadata";
						//	break;
						case kCMMediaType_Metadata:
							humanReadable = @"Metadata";
							break;
						}
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					//[description appendFormat:@"\t%d: Muxed (%@)\n",trackIndex,codecsString];
					if (tmpString == nil)
						tmpString = [NSString stringWithFormat:@"Track %d: Muxed (%@)",trackIndex,codecsString];
					else
						tmpString = [tmpString stringByAppendingFormat:@"\nTrack %d: Muxed (%@)",trackIndex,codecsString];
					
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeVideo])	{
					isVideoTrack = YES;
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						NSString			*type = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						if (type == nil)
							continue;
						NSString			*humanReadable = VideoFourCCStringToHumanReadableCodec(type);
						if (humanReadable == nil)
							continue;
						
						if (codecsString == nil)	{
							codecsString = humanReadable;
							break;	//	only display the first format description for non-muxed tracks
						}
						//else
						//	codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					//[description appendFormat:@"\t%d: Video (%@)\n",trackIndex,codecsString];
					if (tmpString == nil)
						tmpString = [NSString stringWithFormat:@"Track %d: %@",trackIndex,codecsString];
					else
						tmpString = [tmpString stringByAppendingFormat:@"\nTrack %d: %@",trackIndex,codecsString];
				}
				
				//	regardless if its muxed or not, all video tracks need to display some common properties
				if (isVideoTrack)	{
					//	get the resolution
					CGSize				tmpSize = [track naturalSize];
					tmpString = [tmpString stringByAppendingFormat:@", %d x %d",(int)tmpSize.width,(int)tmpSize.height];
				
					//	get the framerate
					double				tmpDouble = [track nominalFrameRate];
					tmpString = [tmpString stringByAppendingFormat:@", %0.2f FPS",tmpDouble];
				
					//	get the duration
					//CMTime				tmpTime = [asset duration];
					//NSString			*tmpString = [NSString smpteStringForTimeInSeconds:CMTimeGetSeconds(tmpTime) withFPS:tmpDouble];
					//if (tmpString != nil)
					//	[description appendFormat:@", Duration: %@",tmpString];
				
				
					if (track.formatDescriptions.count > 0)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[0];
						CFTypeRef			tmpTypeRef = NULL;
						id					recastTypeRef = nil;
					
						//	check the field count
						tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_FieldCount);
						//NSLog(@"FieldCount is %@",(__bridge id)tmpTypeRef);
						recastTypeRef = (__bridge id)tmpTypeRef;
						if (tmpTypeRef == NULL || 
						([recastTypeRef isKindOfClass:[NSNumber class]] && [(NSNumber *)recastTypeRef intValue]<2))	{
							tmpString = [tmpString stringByAppendingFormat:@", Progressive"];
						}
						else
							tmpString = [tmpString stringByAppendingFormat:@", Interlaced"];
					
						//	check the pixel aspect ratio
						tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_PixelAspectRatio);
						recastTypeRef = (__bridge id)tmpTypeRef;
						//NSLog(@"PixelAspectRatio is (%@), %@",[recastTypeRef class],recastTypeRef);
						if (tmpTypeRef == NULL)
							tmpString = [tmpString stringByAppendingFormat:@", Square pixels"];
						else	{
							NSNumber		*tmpWidth = [(NSDictionary *)recastTypeRef objectForKey:@"HorizontalSpacing"];
							NSNumber		*tmpHeight = [(NSDictionary *)recastTypeRef objectForKey:@"VerticalSpacing"];
							if (tmpWidth==nil || tmpHeight==nil)
								tmpString = [tmpString stringByAppendingFormat:@", Square pixels"];
							else	{
								if (tmpWidth.intValue == tmpHeight.intValue)
									tmpString = [tmpString stringByAppendingFormat:@", Square pixels"];
								else
									tmpString = [tmpString stringByAppendingFormat:@", %d:%d pixel aspect ratio",tmpWidth.intValue,tmpHeight.intValue];
							}
						}
					
						//	can we get the color space/color profile?
						//	i have no idea how this is supposed to work, these return NULL and i'm gonna try something else instead of spending more time here
						//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_ICCProfile);
						//recastTypeRef = (__bridge id)tmpTypeRef;
						//NSLog(@"ICCProfile is %@",recastTypeRef);
						//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_ColorPrimaries);
						//recastTypeRef = (__bridge id)tmpTypeRef;
						//NSLog(@"ColorPrimaries are %@",recastTypeRef);
						//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionColorPrimaries_ITU_R_709_2);
						//recastTypeRef = (__bridge id)tmpTypeRef;
						//NSLog(@"709 is %@",recastTypeRef);
					
					
					}
				}
				
				++trackIndex;
			}
			
			tmpAttrString = [[NSMutableAttributedString alloc] initWithString:(tmpString==nil) ? @"(No video tracks)" : tmpString];
			[tmpAttrString
				addAttribute:NSFontAttributeName
				value:[NSFont labelFontOfSize:[NSFont labelFontSize]]
				range:NSMakeRange(0,tmpAttrString.length)];
			[videoString appendAttributedString:tmpAttrString];
			
			[videoField setAttributedStringValue:videoString];
			[videoField setAllowsEditingTextAttributes:YES];
			[videoField sizeToFit];
		}
		
		
		//	populate the audio string
		{
			tmpString = nil;
			NSArray<AVAssetTrack*>		*tracks = [asset tracks];
			int							trackIndex = 1;
			for (AVAssetTrack *track in tracks)	{
				AVMediaType			trackMediaType = [track mediaType];
				//NSLog(@"\t\tprocessing track %@, media type is %@",track,trackMediaType);
				if ([trackMediaType isEqualToString:AVMediaTypeAudio])	{
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						NSString			*type = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						if (type == nil)
							continue;
						NSString			*humanReadable = AudioFourCCStringToHumanReadableCodec(type);
						if (humanReadable == nil)
							continue;
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					//[description appendFormat:@"\t%d: Audio (%@)\n",trackIndex,codecsString];
					if (tmpString == nil)
						tmpString = [NSString stringWithFormat:@"Track %d: %@",trackIndex,codecsString];
					else
						tmpString = [tmpString stringByAppendingFormat:@"\nTrack %d: %@",trackIndex,codecsString];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeMuxed])	{
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						CMMediaType			mediaType = CMFormatDescriptionGetMediaType(desc);
						NSString			*subtype = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						NSString			*humanReadable = nil;
						switch (mediaType)	{
						case kCMMediaType_Video:
							humanReadable = VideoFourCCStringToHumanReadableCodec(subtype);
							break;
						case kCMMediaType_Audio:
							humanReadable = AudioFourCCStringToHumanReadableCodec(subtype);
							break;
						//case kCMMediaType_Muxed:
						case kCMMediaType_Text:
							humanReadable = @"Text";
							break;
						case kCMMediaType_ClosedCaption:
							humanReadable = @"Closed Caption";
							break;
						case kCMMediaType_Subtitle:
							humanReadable = @"Subtitle";
							break;
						case kCMMediaType_TimeCode:
							humanReadable = @"Timecode";
							break;
						//	weird, not recognized for some reason?
						//case kCMMediaType_TimedMetadata:
						//	humanReadable = @"Timed Metadata";
						//	break;
						case kCMMediaType_Metadata:
							humanReadable = @"Metadata";
							break;
						}
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					//[description appendFormat:@"\t%d: Muxed (%@)\n",trackIndex,codecsString];
					if (tmpString == nil)
						tmpString = [NSString stringWithFormat:@"Track %d: Muxed (%@)",trackIndex,codecsString];
					else
						tmpString = [tmpString stringByAppendingFormat:@"\nTrack %d: Muxed (%@)",trackIndex,codecsString];
				}
				
				++trackIndex;
			}
			
			tmpAttrString = [[NSMutableAttributedString alloc] initWithString:(tmpString==nil) ? @"(No audio tracks)" : tmpString];
			[tmpAttrString
				addAttribute:NSFontAttributeName
				value:[NSFont labelFontOfSize:[NSFont labelFontSize]]
				range:NSMakeRange(0,tmpAttrString.length)];
			[audioString appendAttributedString:tmpAttrString];
			
			[audioField setAttributedStringValue:audioString];
			[audioField setAllowsEditingTextAttributes:YES];
			[audioField sizeToFit];
		}
	}
	
	
	
	/*
	NSMutableString		*description = [[NSMutableString alloc] init];
	[description appendFormat:@"%@\n",self.inspectedObject.src];
	if (self.inspectedObject.type == OpType_Other)	{
		[description appendString:@"<Not a video file>"];
	}
	else	{
		NSString			*extension = self.inspectedObject.src.pathExtension;
		if (extension != nil)	{
			if ([extension caseInsensitiveCompare:@"mp4"] == NSOrderedSame)	{
				[description appendString:@"MPEG-4 movie\n"];
			}
			else if ([extension caseInsensitiveCompare:@"mov"] == NSOrderedSame)	{
				[description appendString:@"QuickTime movie\n"];
			}
		}
		
		if (asset != nil)	{
			//	get some vars we're gonna need ahead of time
			NSArray<AVAssetTrack*>		*tracks = [asset tracks];
			NSArray<AVAssetTrack*>		*visualTracks = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
			
			//	run through the tracks, assemble a quick summary of each track
			[description appendString:@"Tracks:\n"];
			int							trackIndex = 1;
			for (AVAssetTrack *track in tracks)	{
				AVMediaType			trackMediaType = [track mediaType];
				NSLog(@"\t\tprocessing track %@, media type is %@",track,trackMediaType);
				if ([trackMediaType isEqualToString:AVMediaTypeAudio])	{
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						NSString			*type = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						if (type == nil)
							continue;
						NSString			*humanReadable = AudioFourCCStringToHumanReadableCodec(type);
						if (humanReadable == nil)
							continue;
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					[description appendFormat:@"\t%d: Audio (%@)\n",trackIndex,codecsString];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeClosedCaption])	{
					[description appendFormat:@"\t%d: Closed-caption\n",trackIndex];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeDepthData])	{
					[description appendFormat:@"\t%d: Depth Data\n",trackIndex];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeMetadata])	{
					[description appendFormat:@"\t%d: Metadata\n",trackIndex];
				}
				//	not available on macOS
				//else if (trackMediaType == AVMediaTypeMetadataObject)	{
				//	[description appendFormat:@"\t%d: Metadata Object\n",trackIndex];
				//}
				else if ([trackMediaType isEqualToString:AVMediaTypeMuxed])	{
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						CMMediaType			mediaType = CMFormatDescriptionGetMediaType(desc);
						NSString			*subtype = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						NSString			*humanReadable = nil;
						switch (mediaType)	{
						case kCMMediaType_Video:
							humanReadable = VideoFourCCStringToHumanReadableCodec(subtype);
							break;
						case kCMMediaType_Audio:
							humanReadable = AudioFourCCStringToHumanReadableCodec(subtype);
							break;
						//case kCMMediaType_Muxed:
						case kCMMediaType_Text:
							humanReadable = @"Text";
							break;
						case kCMMediaType_ClosedCaption:
							humanReadable = @"Closed Caption";
							break;
						case kCMMediaType_Subtitle:
							humanReadable = @"Subtitle";
							break;
						case kCMMediaType_TimeCode:
							humanReadable = @"Timecode";
							break;
						//	weird, not recognized for some reason?
						//case kCMMediaType_TimedMetadata:
						//	humanReadable = @"Timed Metadata";
						//	break;
						case kCMMediaType_Metadata:
							humanReadable = @"Metadata";
							break;
						}
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					[description appendFormat:@"\t%d: Muxed (%@)\n",trackIndex,codecsString];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeSubtitle])	{
					[description appendFormat:@"\t%d: Subtitles\n",trackIndex];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeText])	{
					[description appendFormat:@"\t%d: Text\n",trackIndex];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeTimecode])	{
					[description appendFormat:@"\t%d: Timecode\n",trackIndex];
				}
				else if ([trackMediaType isEqualToString:AVMediaTypeVideo])	{
					NSString		*codecsString = nil;
					for (int i=0; i<track.formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
						if (desc == NULL)
							continue;
						NSString			*type = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
						if (type == nil)
							continue;
						NSString			*humanReadable = VideoFourCCStringToHumanReadableCodec(type);
						if (humanReadable == nil)
							continue;
						
						if (codecsString == nil)
							codecsString = humanReadable;
						else
							codecsString = [codecsString stringByAppendingFormat:@", %@",humanReadable];
					}
					[description appendFormat:@"\t%d: Video (%@)\n",trackIndex,codecsString];
				}
				
				++trackIndex;
			}	//	end of 'for' loop iterating across tracks
			
			//	make a space
			[description appendFormat:@"\n"];
			
			
			//	now get the primary video track- we want to describe it more qualitatively...
			if (visualTracks!=nil && visualTracks.count > 0)	{
				AVAssetTrack		*videoTrack = visualTracks[0];
				
				//	get the resolution
				CGSize				tmpSize = [videoTrack naturalSize];
				[description appendFormat:@"%d x %d",(int)tmpSize.width,(int)tmpSize.height];
				
				//	get the framerate
				double				tmpDouble = [videoTrack nominalFrameRate];
				[description appendFormat:@", %0.2f FPS",tmpDouble];
				
				//	get the duration
				CMTime				tmpTime = [asset duration];
				NSString			*tmpString = [NSString smpteStringForTimeInSeconds:CMTimeGetSeconds(tmpTime) withFPS:tmpDouble];
				if (tmpString != nil)
					[description appendFormat:@", Duration: %@",tmpString];
				
				
				if (videoTrack.formatDescriptions.count > 0)	{
					CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)videoTrack.formatDescriptions[0];
					CFTypeRef			tmpTypeRef = NULL;
					id					recastTypeRef = nil;
					
					//	check the field count
					tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_FieldCount);
					NSLog(@"FieldCount is %@",(__bridge id)tmpTypeRef);
					recastTypeRef = (__bridge id)tmpTypeRef;
					if (tmpTypeRef == NULL || 
					([recastTypeRef isKindOfClass:[NSNumber class]] && [(NSNumber *)recastTypeRef intValue]<2))	{
						[description appendFormat:@", Progressive"];
					}
					else
						[description appendFormat:@", Interlaced"];
					
					//	check the pixel aspect ratio
					tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_PixelAspectRatio);
					recastTypeRef = (__bridge id)tmpTypeRef;
					NSLog(@"PixelAspectRatio is (%@), %@",[recastTypeRef class],recastTypeRef);
					if (tmpTypeRef == NULL)
						[description appendFormat:@", Square pixels"];
					else	{
						NSNumber		*tmpWidth = [(NSDictionary *)recastTypeRef objectForKey:@"HorizontalSpacing"];
						NSNumber		*tmpHeight = [(NSDictionary *)recastTypeRef objectForKey:@"VerticalSpacing"];
						if (tmpWidth==nil || tmpHeight==nil)
							[description appendFormat:@", Square pixels"];
						else	{
							if (tmpWidth.intValue == tmpHeight.intValue)
								[description appendFormat:@", Square pixels"];
							else
								[description appendFormat:@", %d:%d pixel aspect ratio",tmpWidth.intValue,tmpHeight.intValue];
						}
					}
					
					//	can we get the color space/color profile?
					//	i have no idea how this is supposed to work, these return NULL and i'm gonna try something else instead of spending more time here
					//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_ICCProfile);
					//recastTypeRef = (__bridge id)tmpTypeRef;
					//NSLog(@"ICCProfile is %@",recastTypeRef);
					//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionExtension_ColorPrimaries);
					//recastTypeRef = (__bridge id)tmpTypeRef;
					//NSLog(@"ColorPrimaries are %@",recastTypeRef);
					//tmpTypeRef = CMFormatDescriptionGetExtension(desc, kCMFormatDescriptionColorPrimaries_ITU_R_709_2);
					//recastTypeRef = (__bridge id)tmpTypeRef;
					//NSLog(@"709 is %@",recastTypeRef);
					
					
				}
				
			}
			
			
			
			//	actually update the description field
			[opDescriptionField setStringValue:description];
			
			//	we need to resize the description field + box
		}
	}
	*/
}


@end
