//
//	PresetGroup.m
//	Synopsis
//
//	Created by vade on 12/28/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PresetGroup.h"
#import "PresetObject.h"
#import <HapInAVFoundation/HapInAVFoundation.h>




@interface PresetGroup ()
@property (readwrite) BOOL editable;
@property (strong,readwrite) NSMutableArray * children;
@end


PresetGroup			*_standardPresets = nil;
PresetGroup			*_customPresets = nil;




@implementation PresetGroup


+ (PresetGroup *) standardPresets	{
	return _standardPresets;
}
+ (PresetGroup *) customPresets	{
	return _customPresets;
}


+ (void) initialize	{
	if (_standardPresets == nil)	{
		_standardPresets = [[PresetGroup alloc] initWithTitle:@"Standard Presets" editable:NO];
		
#pragma mark - Passthrough 

		PresetObject*		passthrough = [[PresetObject alloc] initWithTitle:@"Passthrough"
			audioSettings:[PresetAudioSettings none]
			videoSettings:[PresetVideoSettings none]
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"DDCEA125-B93D-464B-B369-FB78A5E890B4"];

		PresetObject*		passthroughWJSON = [[PresetObject alloc] initWithTitle:@"Passthrough - Export JSON"
			audioSettings:[PresetAudioSettings none]
			videoSettings:[PresetVideoSettings none]
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionJSONContiguous
			editable:NO
			uuid:@"A3986F2F-0FC2-4839-9F6D-9580066B9890"];

		PresetObject*		passthroughNoAudio = [[PresetObject alloc] initWithTitle:@"Passthrough - No Audio"
			audioSettings:[PresetAudioSettings none]
			videoSettings:[PresetVideoSettings none]
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:NO
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO];

		PresetGroup*		passthroughGroup = [[PresetGroup alloc] initWithTitle:@"Passthrough" editable:NO];
		passthroughGroup.children = [@[
			passthrough,
			passthroughWJSON,
			passthroughNoAudio
		] mutableCopy];

#pragma mark - Uncompressed

		// Uncompressed YUV 422 -
		// TODO: when to use yuvs vs 2vuy ?

		//		  PresetVideoSettings* rgb24VideoSetting = [[PresetVideoSettings alloc] init];
		//		  rgb24VideoSetting.settingsDictionary = @{AVVideoCodecKey:@"24	 "};
		//
		//		  PresetObject* rgb24Preset = [[PresetObject alloc] initWithTitle:@"Uncompressed 8 Bit RGB"
		//																	audioSettings:[PresetAudioSettings none]
		//																	videoSettings:rgb24VideoSetting
		//																 analyzerSettings:[PresetAnalysisSettings none]
		//																		 useAudio:YES
		//																		 useVideo:YES
		//																	  useAnalysis:YES
		//																		 editable:NO];


		PresetVideoSettings*		yuv422YpCbCr8VideoSetting = [[PresetVideoSettings alloc] init];
		yuv422YpCbCr8VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"2vuy"
		};

		PresetObject*		yuv422YpCbCr8Preset = [[PresetObject alloc] initWithTitle:@"Uncompressed 8 Bit 422"
			audioSettings:[PresetAudioSettings none]
			videoSettings:yuv422YpCbCr8VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"DFFD849D-FAF6-4372-BF37-26E6DED926D3"];

		// TODO: RGB 24 bit ?
		PresetGroup*		uncompressedGroup = [[PresetGroup alloc] initWithTitle:@"Uncompressed" editable:NO];
		uncompressedGroup.children = [@[
			//rgb24Preset,
			yuv422YpCbCr8Preset,
		] mutableCopy];

#pragma mark - HAP

		// Hap1
		PresetVideoSettings*		hap1VideoSetting = [[PresetVideoSettings alloc] init];
		hap1VideoSetting.settingsDictionary = @{
			AVVideoCodecKey: AVVideoCodecHap
		};

		PresetObject*		hap1Preset = [[PresetObject alloc] initWithTitle:@"HAP"
			audioSettings:[PresetAudioSettings none]
			videoSettings:hap1VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"21C7330B-89F5-4742-AD8E-7574E2AFE3F1"];
	
		// Hap5
		PresetVideoSettings*		hap5VideoSetting = [[PresetVideoSettings alloc] init];
		hap5VideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecHapAlpha
		};

		PresetObject*		hap5Preset = [[PresetObject alloc] initWithTitle:@"HAP Alpha"
			audioSettings:[PresetAudioSettings none]
			videoSettings:hap5VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"A5327E1E-0BDA-4CBE-AE35-866E91932991"];


		// HapY
		PresetVideoSettings*		hapYVideoSetting = [[PresetVideoSettings alloc] init];
		hapYVideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecHapQ
		};

		PresetObject*		hapYPreset = [[PresetObject alloc] initWithTitle:@"HAP Q"
			audioSettings:[PresetAudioSettings none]
			videoSettings:hapYVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"46CF27AB-7503-4D98-A3A8-0FBA54FA1C5A"];

		// HapM
		PresetVideoSettings*		hapMVideoSetting = [[PresetVideoSettings alloc] init];
		hapMVideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecHapQAlpha
		};

		PresetObject*		hapMPreset = [[PresetObject alloc] initWithTitle:@"HAP Q Alpha"
			audioSettings:[PresetAudioSettings none]
			videoSettings:hapMVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"A0A20F63-0147-4D06-A7CF-C6E467ADDD17"];

		//		  // HapA
		//		  PresetVideoSettings* hapAVideoSetting = [[PresetVideoSettings alloc] init];
		//		  hapAVideoSetting.settingsDictionary = @{AVVideoCodecKey:@"HapA"};
		//
		//		  PresetObject* hapAPreset = [[PresetObject alloc] initWithTitle:@"HAP Alpha"
		//														   audioSettings:[PresetAudioSettings none]
		//														   videoSettings:hapAVideoSetting
		//														analyzerSettings:[PresetAnalysisSettings none]
		//																useAudio:YES
		//																useVideo:YES
		//															 useAnalysis:YES
		//																editable:NO];

		PresetGroup* hapGroup = [[PresetGroup alloc] initWithTitle:@"HAP" editable:NO];
		hapGroup.children = [@[
			hap1Preset,
			hap5Preset,
			hapYPreset,
			hapMPreset,
			//hapAPreset,
		] mutableCopy];

#pragma mark - Animation

		// No RLE Encoder in AVFoundation on 10.12?
		//		  PresetVideoSettings* animationVideoSetting = [[PresetVideoSettings alloc] init];
		//		  animationVideoSetting.settingsDictionary = @{AVVideoCodecKey:@"rle "};
		//
		//		  PresetObject* animationPreset = [[PresetObject alloc] initWithTitle:@"Apple Animation"
		//																	audioSettings:[PresetAudioSettings none]
		//																	videoSettings:animationVideoSetting
		//																 analyzerSettings:[PresetAnalysisSettings none]
		//																		 useAudio:YES
		//																		 useVideo:YES
		//																	  useAnalysis:YES
		//																		 editable:NO];
		//
		//		  PresetGroup* animationGroup = [[PresetGroup alloc] initWithTitle:@"Animation" editable:NO];
		//		  animationGroup.children = @[animationPreset];

#pragma mark - Pro Res Variants

		// 4444
		PresetVideoSettings*		appleProRes4444VideoSetting = [[PresetVideoSettings alloc] init];
		appleProRes4444VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"ap4h"
		};

		PresetObject*		appleProRes4444Preset = [[PresetObject alloc] initWithTitle:@"Apple Pro Res 4444"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleProRes4444VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"CBA4E53A-EF8A-4539-8167-4C6F4144C305"];

		// 422 HQ
		PresetVideoSettings*		appleProRes422HQVideoSetting = [[PresetVideoSettings alloc] init];
		appleProRes422HQVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"apch"
		};

		PresetObject*		appleProRes422HQPreset = [[PresetObject alloc] initWithTitle:@"Apple Pro Res 422 HQ"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleProRes422HQVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"1152F200-46FF-4434-AB0E-6BC2CAFD0B6D"];


		// 422
		PresetVideoSettings*		appleProRes422VideoSetting = [[PresetVideoSettings alloc] init];
		appleProRes422VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:AVVideoCodecTypeAppleProRes422
		};

		PresetObject*		appleProRes422Preset = [[PresetObject alloc] initWithTitle:@"Apple Pro Res 422"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleProRes422VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"7595D0BC-6AF4-4D0C-8547-2BC751E7B64A"];

		// 422 LT
		PresetVideoSettings*		appleProRes422LTVideoSetting = [[PresetVideoSettings alloc] init];
		appleProRes422LTVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"apcs"
		};

		PresetObject*		appleProRes422LTPreset = [[PresetObject alloc] initWithTitle:@"Apple Pro Res 422 LT"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleProRes422LTVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"DE8F3364-1781-424F-A6CF-C8C32CAB1987"];

		// 422 Proxy
		PresetVideoSettings*		appleProRes422ProxyVideoSetting = [[PresetVideoSettings alloc] init];
		appleProRes422ProxyVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"apco"
		};

		PresetObject*		appleProRes422ProxyPreset = [[PresetObject alloc] initWithTitle:@"Apple Pro Res 422 Proxy"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleProRes422ProxyVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"80E6F537-41CD-4081-9065-ABA3D093F080"];

		PresetGroup*		proResGroup = [[PresetGroup alloc] initWithTitle:@"Pro Res" editable:NO];
		proResGroup.children = [@[
			appleProRes4444Preset,
			appleProRes422HQPreset,
			appleProRes422Preset,
			appleProRes422LTPreset,
			appleProRes422ProxyPreset,
		] mutableCopy];

#pragma mark - Apple Intermediate

		PresetVideoSettings*		appleIntermediateVideoSetting = [[PresetVideoSettings alloc] init];
		appleIntermediateVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"icod"
		};

		PresetObject*		appleIntermediatePreset = [[PresetObject alloc] initWithTitle:@"Apple Intermediate"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleIntermediateVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"2444D7B8-38BC-4A2C-A4F5-434495B733D8"];

		PresetObject*		appleIntermediatePresetNoAudio = [[PresetObject alloc] initWithTitle:@"Apple Intermediate - No Audio"
			audioSettings:[PresetAudioSettings none]
			videoSettings:appleIntermediateVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:NO
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"DE2E3324-C669-4006-8782-9AC170F29D6F"];

		PresetGroup*		aicGroup = [[PresetGroup alloc] initWithTitle:@"Apple Intermediate Codec" editable:NO];
		aicGroup.children = [@[
			appleIntermediatePreset,
			appleIntermediatePresetNoAudio
		] mutableCopy];

#pragma mark - Motion Jpeg

		PresetVideoSettings*		photoJPEGVideoSetting = [[PresetVideoSettings alloc] init];
		photoJPEGVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:AVVideoCodecTypeJPEG
		};

		PresetObject*		photoJPEGPreset = [[PresetObject alloc] initWithTitle:@"Photo JPEG"
			audioSettings:[PresetAudioSettings none]
			videoSettings:photoJPEGVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"6D1C20D3-8B1D-4151-A12D-3EAFDA89CD48"];

		PresetObject*		photoJPEGPresetNoAudio = [[PresetObject alloc] initWithTitle:@"Photo JPEG - No Audio"
			audioSettings:[PresetAudioSettings none]
			videoSettings:photoJPEGVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:NO
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"02BC065A-E05D-4A08-A5C8-2D768546C0CB"];

		PresetGroup*		motionJPEGGroup = [[PresetGroup alloc] initWithTitle:@"Photo JPEG" editable:NO];
		motionJPEGGroup.children = [@[
			photoJPEGPreset,
			photoJPEGPresetNoAudio
		] mutableCopy];

#pragma mark - DV Family

		// DV NTSC
		PresetVideoSettings*		dvNTSCVideoSetting = [[PresetVideoSettings alloc] init];
		dvNTSCVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvc ",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect
		};

		PresetObject*		dvNTSCPreset = [[PresetObject alloc] initWithTitle:@"DV NTSC (720x480)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvNTSCVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"54CF7EA2-DB5F-40B6-BB31-63E912550CE5"];

		// DV NTSC
		PresetVideoSettings*		dvPalVideoSetting = [[PresetVideoSettings alloc] init];
		dvPalVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvcp",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect
		};

		PresetObject*		dvPalPreset = [[PresetObject alloc] initWithTitle:@"DV PAL (720x576)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvPalVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"A0357630-5194-46D5-AFFB-F6FE86106C54"];

		// DVCPro 50 NTSC
		PresetVideoSettings*		dvcProNTSCVideoSetting = [[PresetVideoSettings alloc] init];
		dvcProNTSCVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dv5n",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect
		};

		PresetObject*		dvcProNTSCPreset = [[PresetObject alloc] initWithTitle:@"DVCPro 50 NTSC (720x480)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcProNTSCVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"9DF14B22-F079-4584-88A3-395F1ABDA846"];

		// DVCPro 50 PAL
		PresetVideoSettings*		dvcProPALVideoSetting = [[PresetVideoSettings alloc] init];
		dvcProPALVideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dv5p",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect
		};

		PresetObject*		dvcProPALPreset = [[PresetObject alloc] initWithTitle:@"DVCPro 50 PAL (720x576)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcProPALVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"399D02B3-A5EB-4D2F-A202-8D9EC3EE9B61"];

		// For whatever reason, DVCPro codecs need size
		// Adjust for pixel aspect ratio
		// so output size is right.

		// DVC Pro HD 720p60
		PresetVideoSettings*		dvcPro720p60VideoSetting = [[PresetVideoSettings alloc] init];
		dvcPro720p60VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvhp",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
			AVVideoWidthKey : @(960),
			AVVideoHeightKey : @(720),
		};

		PresetObject*		dvcPro720p60Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 720p60 (1280x720)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcPro720p60VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"31F93C3D-E4C9-42BD-984E-15E5A30814C6"];

		// DVC Pro HD 720p50
		PresetVideoSettings*		dvcPro720p50VideoSetting = [[PresetVideoSettings alloc] init];
		dvcPro720p50VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvhq",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
			AVVideoWidthKey : @(960),
			AVVideoHeightKey : @(720),
		};

		PresetObject*		dvcPro720p50Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 720p50 (1280x720)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcPro720p50VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"4B715F46-DD97-4C0B-A4C9-5188CEFDE4A0"];

		// DVC Pro HD 1080i60
		//		  PresetVideoSettings* dvcPro1080i60VideoSetting = [[PresetVideoSettings alloc] init];
		//		  dvcPro1080i60VideoSetting.settingsDictionary = @{AVVideoCodecKey:@"dvh6",
		//														   AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
		//														   AVVideoWidthKey : @(1280),
		//														   AVVideoHeightKey : @(1080),
		//														   };
		//		  
		//		  PresetObject* dvcPro1080i60Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 1080i60 (1920x1080)"
		//																	audioSettings:[PresetAudioSettings none]
		//																	videoSettings:dvcPro1080i60VideoSetting
		//																 analyzerSettings:[PresetAnalysisSettings none]
		//																		 useAudio:YES
		//																		 useVideo:YES
		//																	  useAnalysis:YES
		//																		 editable:NO
		//																			 uuid:@"293A1031-03DF-4761-88DC-D30E710872C2"];

		// DVC Pro HD 1080i50
		//		  PresetVideoSettings* dvcPro1080i50VideoSetting = [[PresetVideoSettings alloc] init];
		//		  dvcPro1080i50VideoSetting.settingsDictionary = @{AVVideoCodecKey:@"dvh5",
		//														   AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
		//														   AVVideoWidthKey : @(1280),
		//														   AVVideoHeightKey : @(1080),
		//														   };
		//		  
		//		  PresetObject* dvcPro1080i50Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 1080i50 (1920x1080)"
		//																	audioSettings:[PresetAudioSettings none]
		//																	videoSettings:dvcPro1080i50VideoSetting
		//																 analyzerSettings:[PresetAnalysisSettings none]
		//																		 useAudio:YES
		//																		 useVideo:YES
		//																	  useAnalysis:YES
		//																		 editable:NO
		//																			 uuid:@"2BEB8551-5670-48EB-9ED6-0DCDDEFFA251"];

		// DVC Pro HD 1080p30
		PresetVideoSettings*		dvcPro1080p30VideoSetting = [[PresetVideoSettings alloc] init];
		dvcPro1080p30VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvh3",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
			AVVideoWidthKey : @(1280),
			AVVideoHeightKey : @(1080),
		};

		PresetObject*		dvcPro1080p30Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 1080p30 (1920x1080)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcPro1080p30VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"EC0365CE-0C56-433A-8BB3-710BE06B9D3B"];

		// DVC Pro HD 1080p25
		PresetVideoSettings*		dvcPro1080p25VideoSetting = [[PresetVideoSettings alloc] init];
		dvcPro1080p25VideoSetting.settingsDictionary = @{
			AVVideoCodecKey:@"dvh3",
			AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
			AVVideoWidthKey : @(1280),
			AVVideoHeightKey : @(1080),
		};

		PresetObject*		dvcPro1080p25Preset = [[PresetObject alloc] initWithTitle:@"DVCPro 1080p25 (1920x1080)"
			audioSettings:[PresetAudioSettings none]
			videoSettings:dvcPro1080p25VideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"9717C926-E15D-45E7-BD7E-4A300FEB1049"];

		PresetGroup*		dvGroup = [[PresetGroup alloc] initWithTitle:@"DV" editable:NO];
		dvGroup.children = [@[
			dvNTSCPreset,
			dvPalPreset,
			dvcProNTSCPreset,
			dvcProPALPreset,
			dvcPro720p60Preset,
			dvcPro720p50Preset,
			//dvcPro1080i60Preset,
			//dvcPro1080i50Preset,
			dvcPro1080p30Preset,
			dvcPro1080p25Preset,
		] mutableCopy];

#pragma mark - h.264


		PresetAudioSettings*		aac48Khz = [[PresetAudioSettings alloc] init];
		aac48Khz.settingsDictionary = @{
			AVFormatIDKey : @(kAudioFormatMPEG4AAC),
			AVSampleRateKey : @(48000.0),
			AVNumberOfChannelsKey : @(2),
			AVEncoderBitRateKey : @(256000),
		//AVEncoderAudioQualityKey : @(AVAudioQualityHigh),
		};

		// h.264 Baseline Auto / AAC 48khz Stereo 256
		PresetVideoSettings*		baseLineAutoLevelVideoSetting = [[PresetVideoSettings alloc] init];
		baseLineAutoLevelVideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecTypeH264,
			AVVideoCompressionPropertiesKey : @{
				AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
			},
			//AVVideoEncoderSpecificationKey : @{
			//	(NSString*)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder : @YES,
			//}
		};

		PresetObject*		baseLineAutoLevelPreset = [[PresetObject alloc] initWithTitle:@"h.264 Baseline Auto Level / Stereo AAC, 48Khz 240kbps"
			audioSettings:aac48Khz
			videoSettings:baseLineAutoLevelVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"B9CB5486-3E7C-4BAB-8329-6ED98A4FA4BA"];

		// h.264 Main Auto / AAC 48khz Stereo 256
		PresetVideoSettings*		mainAutoLevelVideoSetting = [[PresetVideoSettings alloc] init];
		mainAutoLevelVideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecTypeH264,
			AVVideoCompressionPropertiesKey : @{
				AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
			},
			//AVVideoEncoderSpecificationKey : @{
			//	(NSString*)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder : @YES,
			//}
		};

		PresetObject*		mainAutoLevelPreset = [[PresetObject alloc] initWithTitle:@"h.264 Main Auto Level / Stereo AAC, 48Khz 240kbps"
			audioSettings:aac48Khz
			videoSettings:mainAutoLevelVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"4A5F9F66-58FD-4464-9BD3-69C4529EF779"];

		// h.264 Main Auto / AAC 48khz Stereo 256
		PresetVideoSettings*		highAutoLevelVideoSetting = [[PresetVideoSettings alloc] init];
		highAutoLevelVideoSetting.settingsDictionary = @{
			AVVideoCodecKey : AVVideoCodecTypeH264,
			AVVideoCompressionPropertiesKey : @{
				AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
			},
			//AVVideoEncoderSpecificationKey : @{
			//	(NSString*)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder : @YES,
			//}
		};

		PresetObject*		highAutoLevelPreset = [[PresetObject alloc] initWithTitle:@"h.264 High Auto Level / Stereo AAC, 48Khz 240kbps"
			audioSettings:aac48Khz
			videoSettings:highAutoLevelVideoSetting
			analyzerSettings:[PresetAnalysisSettings none]
			useAudio:YES
			useVideo:YES
			useAnalysis:YES
			exportOption:SynopsisMetadataEncoderExportOptionNone
			editable:NO
			uuid:@"44CE7EA4-1FF8-4E47-8AB6-ABE909FB4E6E"];

		PresetGroup*		h264Group = [[PresetGroup alloc] initWithTitle:@"h.264" editable:NO];
		h264Group.children = [@[
			baseLineAutoLevelPreset,
			mainAutoLevelPreset,
			highAutoLevelPreset
		] mutableCopy];


#pragma mark - HEVC

		[_standardPresets.children addObjectsFromArray:@[
			passthroughGroup,
			uncompressedGroup,
			hapGroup,
			//animationGroup,
			proResGroup,
			aicGroup,
			motionJPEGGroup,
			dvGroup,
			h264Group,
		]];
	}
	
	if (_customPresets == nil)	{
		_customPresets = [[PresetGroup alloc] initWithTitle:@"Custom Presets" editable:NO];
		_customPresets.editable = YES;
		
		NSString			*appName = @"Synopsis Analyzer";
		NSArray<NSURL*>		*appSupportURLS = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
		NSMutableArray<PresetObject*>		*userSavedPresets = [NSMutableArray array];
	
		if (appSupportURLS.count > 0)	{
			NSURL				*presetURL = [appSupportURLS[0] URLByAppendingPathComponent:appName isDirectory:YES];
			presetURL = [presetURL URLByAppendingPathComponent:@"Presets" isDirectory:YES];

			NSError				*error;
			NSArray				*potentialPresets = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:presetURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
		
			for (NSURL* potentialPresetURL in potentialPresets)	{
				if([potentialPresetURL.pathExtension isEqualToString:@"SynopsisPreset"])	{
					NSData			*presetData = [NSData dataWithContentsOfURL:potentialPresetURL];
					PresetObject	*preset = [[PresetObject alloc] initWithData:presetData];
					[userSavedPresets addObject:preset];
				}
			}
		}
		
		[_customPresets.children addObjectsFromArray:userSavedPresets];
	}
}


#pragma mark - init/dealloc


- (id) initWithTitle:(NSString*)title editable:(BOOL)editable
{
	self = [super init];
	if(self)
	{
		self.title = title;
		self.children = [[NSMutableArray alloc] init];
		self.editable = editable;
		return self;
	}
	return nil;
}

- (NSString*) description
{
	return self.title;
}


@end
