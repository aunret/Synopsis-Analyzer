//
//  PresetSettingsUIController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/1/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PresetSettingsUIController.h"

#import "PresetObject.h"
#import "PreferencesPresetViewController.h"
#import <HapInAVFoundation/HapInAVFoundation.h>
#import "PresetSettings.h"
#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>
#import <VideoToolbox/VTCompressionProperties.h>
#import <VideoToolbox/VTProfessionalVideoWorkflow.h>




// Preferences Keys
const NSString* title = @"Title";
const NSString* value = @"Value";




@interface PresetSettingsUIController()
- (void) awakeAudioUI;
- (void) awakeVideoUI;
- (void) configureAudioSettingsFromPreset:(PresetObject*)preset;
- (void) configureVideoSettingsFromPreset:(PresetObject*)preset;
- (void) configureAnalysisSettingsFromPreset:(PresetObject*)preset;
@end




@implementation PresetSettingsUIController


#pragma mark - init/dealloc/awake


- (id) init	{
	self = [super init];
	if (self != nil)	{
	}
	return self;
}
- (void) awakeFromNib	{
	[self awakeAudioUI];
	[self awakeVideoUI];
	self.selectedPreset = nil;
	self.presetChanged = NO;
}
- (void) awakeAudioUI	{
	[prefsAudioFormat removeAllItems];
	[prefsAudioRate removeAllItems];
	[prefsAudioQuality removeAllItems];
	[prefsAudioBitrate removeAllItems];
	
	// Audio Prefs Format
	NSArray* formatArray = @[
							 @{title : @"Passthrough", value :[NSNull null] },
							 @{title : @"Seperator", value : @"Seperator" },
							 @{title : @"LinearPCM", value : @(kAudioFormatLinearPCM)} ,
							 @{title : @"Apple Lossless", value : @(kAudioFormatAppleLossless)},
							 @{title : @"AAC", value : @(kAudioFormatMPEG4AAC)},
							 //								@{title : @"MP3", value : @(kAudioFormatMPEGLayer3)},
							 ];
	
	[self addMenuItemsToMenu:prefsAudioFormat.menu withArray:formatArray withSelector:@selector(selectAudioFormat:)];
	
	// Audio Prefs Rate
	NSArray* rateArray = @[
						   @{title : @"Recommended", value : [NSNull null]},
						   @{title : @"Seperator", value : @"Seperator" },
						   @{title : @"16.000 Khz", value : @(16000.0)},
						   @{title : @"22.050 Khz", value : @(22050.0)},
						   @{title : @"24.000 Khz", value : @(24000.0)},
						   @{title : @"32.000 Khz", value : @(32000.0)},
						   @{title : @"44.100 Khz", value : @(44100.0)},
						   @{title : @"48.000 Khz", value : @(48000.0)},
						   @{title : @"88.200 Khz", value : @(88200.0)},
						   @{title : @"96.000 Khz", value : @(960000.0)},
						   ];
	
	[self addMenuItemsToMenu:prefsAudioRate.menu withArray:rateArray withSelector:@selector(selectAudioSamplerate:)];
	
	// Audio Prefs Quality
	
	NSArray* qualityArray = @[
							  @{title : @"Minimum", value : @(AVAudioQualityMin)} ,
							  @{title : @"Low", value : @(AVAudioQualityLow)},
							  @{title : @"Normal", value : @(AVAudioQualityMedium)},
							  @{title : @"High", value : @(AVAudioQualityHigh)},
							  @{title : @"Maximum", value : @(AVAudioQualityMax)}
							  ];
	
	[self addMenuItemsToMenu:prefsAudioQuality.menu withArray:qualityArray withSelector:@selector(selectAudioQuality:)];
	
	// Audio Prefs Bitrate
	NSArray* bitRateArray = @[
							  @{title : @"Recommended", value : [NSNull null]},
							  @{title : @"Seperator", value : @"Seperator" },
							  @{title : @"16 Kbps", value : @(16000)},
							  @{title : @"24 Kbps", value : @(24000)},
							  @{title : @"32 Kbps", value : @(32000)},
							  @{title : @"48 Kbps", value : @(38000)},
							  @{title : @"64 Kbps", value : @(64000)},
							  @{title : @"80 Kbps", value : @(80000)},
							  @{title : @"96 Kbps", value : @(96000)},
							  @{title : @"112 Kbps", value : @(112000)},
							  @{title : @"128 Kbps", value : @(128000)},
							  @{title : @"160 Kbps", value : @(160000)},
							  @{title : @"192 Kbps", value : @(192000)},
							  @{title : @"224 Kbps", value : @(224000)},
							  @{title : @"256 Kbps", value : @(256000)},
							  @{title : @"320 Kbps", value : @(320000)},
							  ];
	
	[self addMenuItemsToMenu:prefsAudioBitrate.menu withArray:bitRateArray withSelector:@selector(selectAudioBitrate:)];
}
- (void) awakeVideoUI	{
	[prefsVideoCompressor removeAllItems];
	[prefsVideoDimensions removeAllItems];
	[prefsVideoQuality removeAllItems];
	[prefsVideoAspectRatio removeAllItems];
	
	// Video Prefs Encoders
	
	VTRegisterProfessionalVideoWorkflowVideoDecoders();
	VTRegisterProfessionalVideoWorkflowVideoEncoders();
		
	CFArrayRef videoEncoders;
	VTCopyVideoEncoderList(NULL, &videoEncoders);
	NSArray* videoEncodersArray = (__bridge NSArray*)videoEncoders;
	
	NSMutableArray* encoderArrayWithTitles = [NSMutableArray arrayWithCapacity:videoEncodersArray.count + 2];

	[encoderArrayWithTitles addObject: @{title : @"Passthrough", value :[NSNull null] }];
	[encoderArrayWithTitles addObject: @{title : @"Seperator", value : @"Seperator" }];
	
	for(NSDictionary* encoder in videoEncodersArray)
	{
		NSNumber* codecType = encoder[@"CodecType"];
		FourCharCode fourcc = (FourCharCode)[codecType intValue];
		NSString* fourCCString = NSFileTypeForHFSTypeCode(fourcc);
		
		// remove ' so "'jpeg'" becomes "jpeg" for example
		fourCCString = [fourCCString stringByReplacingOccurrencesOfString:@"'" withString:@""];

		[encoderArrayWithTitles addObject:@{title:encoder[@"DisplayName"], value:fourCCString}];
	}

	// Add HAP Codecs manually
	[encoderArrayWithTitles addObject:@{ title : @"HAP", value : AVVideoCodecHap}];
	[encoderArrayWithTitles addObject:@{ title : @"HAP Alpha", value :AVVideoCodecHapAlpha}];
	[encoderArrayWithTitles addObject:@{ title : @"HAP Q", value : AVVideoCodecHapQ}];
	[encoderArrayWithTitles addObject:@{ title : @"HAP Q Alpha", value : AVVideoCodecHapQAlpha}];
//	  [encoderArrayWithTitles addObject:@{ title : @"HAP Alpha", value : @"HapA"}];
	
	//	  NSDictionary* animationDictionary = @{ title : @"MPEG4 Video" , value: @{ @"CodecType" : [NSNumber numberWithInt:kCMVideoCodecType_MPEG4Video]}};
	//	  [encoderArrayWithTitles addObject: animationDictionary];
	
	[self addMenuItemsToMenu:prefsVideoCompressor.menu withArray:encoderArrayWithTitles withSelector:@selector(selectVideoEncoder:)];
	
	// Video Prefs Resolution	 
	NSArray			*videoResolutions = @[
							  @{title : @"Native", value : [NSValue valueWithSize:NSZeroSize] },
							  @{title : @"Seperator", value : @"Seperator" },
							  @{title : @"640 x 480 (NTSC)", value : [NSValue valueWithSize:(NSSize){640.0, 480.0}] },
							  @{title : @"768 x 576 (PAL)", value : [NSValue valueWithSize:(NSSize){786.0, 576.0}] },
							  @{title : @"720 x 480 (480p)", value : [NSValue valueWithSize:(NSSize){720.0, 480.0}] },
							  @{title : @"720 x 576 (576p)", value : [NSValue valueWithSize:(NSSize){720.0, 576.0}] },
							  @{title : @"1280 x 720 (720p)", value : [NSValue valueWithSize:(NSSize){1280.0, 720.0}] },
							  @{title : @"1920 x 1080 (1080p)", value : [NSValue valueWithSize:(NSSize){1920.0, 1080.0}] },
							  @{title : @"2048 × 1080 (2k)", value : [NSValue valueWithSize:(NSSize){2048.0, 1080.0}] },
							  @{title : @"2048 × 858 (2k Cinemascope)", value : [NSValue valueWithSize:(NSSize){2048.0, 858.0}] },
							  @{title : @"3840 × 2160 (UHD)", value : [NSValue valueWithSize:(NSSize){3840.0, 2160.0}] },
							  @{title : @"4096 × 2160 (4k)", value : [NSValue valueWithSize:(NSSize){4096.0, 2160.0}] },
							  @{title : @"4096 × 1716 (4k Cinemascope)", value : [NSValue valueWithSize:(NSSize){4096.0, 1716.0}] },
							  @{title : @"Seperator", value : @"Seperator" },
							  @{title : @"Custom", value : [NSNull null] },
							  ];
	
	[self addMenuItemsToMenu:prefsVideoDimensions.menu withArray:videoResolutions withSelector:@selector(selectVideoResolution:)];

	// Video Prefs Quality
	NSArray* qualityArray = @[
							  @{title : @"Not Applicable", value : [NSNull null] },
							  @{title : @"Seperator", value : @"Seperator" },
							  @{title : @"Minimum", value : @0.0} ,
							  @{title : @"Low", value : @0.25},
							  @{title : @"Normal", value : @0.5},
							  @{title : @"High", value : @0.75},
							  @{title : @"Maximum", value : @1.0}
							  ];
	
	[self addMenuItemsToMenu:prefsVideoQuality.menu withArray:qualityArray withSelector:@selector(selectVideoQuality:)];
	
	// Video Prefs Aspect Ratio
	// AVVideoScalingModeKey
	NSArray* aspectArray = @[
							 @{title : @"Native", value : [NSNull null] },
							 @{title : @"Seperator", value : @"Seperator" },
							 @{title : @"Aspect Fill", value : AVVideoScalingModeResizeAspectFill},
							 @{title : @"Aspect Fit", value : AVVideoScalingModeResizeAspect},
							 @{title : @"Resize", value : AVVideoScalingModeResize},
							 ];
	
	[self addMenuItemsToMenu:prefsVideoAspectRatio.menu withArray:aspectArray withSelector:@selector(selectVideoAspectRatio:)];
	
	[self validateVideoPrefsUI];
	[self buildVideoPreferences];
}


#pragma mark - Prefs Helpers


- (void) addMenuItemsToMenu:(NSMenu*)aMenu withArray:(NSArray*)array withSelector:(SEL)selector
{
	for(NSDictionary* item in array)
	{
		if([item[title] isEqualToString:@"Seperator"])
		{
			[aMenu addItem:[NSMenuItem separatorItem]];
		}
		else
		{
			NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:item[title] action:selector keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:item[value]];
			[aMenu addItem:menuItem];
		}
	}
}


#pragma mark - control


@synthesize selectedPreset=mySelectedPreset;
- (void) setSelectedPreset:(PresetObject *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	mySelectedPreset = n;
	
	overviewDescriptionTextField.stringValue = self.selectedPreset.lengthyDescription;
	
	overViewSavePresetButton.enabled = self.selectedPreset.editable;
	
	[self configureAudioSettingsFromPreset:self.selectedPreset];
	[self configureVideoSettingsFromPreset:self.selectedPreset];
	[self configureAnalysisSettingsFromPreset:self.selectedPreset];
	
	[self validateVideoPrefsUI];
	[self validateAudioPrefsUI];
	
	self.presetChanged = NO;
}
- (PresetObject *) selectedPreset	{
	return mySelectedPreset;
}
@synthesize presetChanged=myPresetChanged;
- (void) setPresetChanged:(BOOL)n	{
	//NSLog(@"%s ... %d",__func__,n);
	myPresetChanged = n;
}
- (BOOL) presetChanged	{
	return myPresetChanged;
}
- (void) configureAudioSettingsFromPreset:(PresetObject*)preset
{
	//NSLog(@"%s",__func__);
	// configure editability:
	useAudioCheckButton.enabled = preset.editable;
	prefsAudioFormat.enabled = preset.editable && preset.useAudio;
	prefsAudioBitrate.enabled = preset.editable && preset.useAudio;
	prefsAudioQuality.enabled = preset.editable && preset.useAudio;
	prefsAudioRate.enabled = preset.editable && preset.useAudio;

	useAudioCheckButton.state = (preset.useAudio) ? 1 : 0;
	
	// set values
	if(preset.audioSettings.settingsDictionary)
	{
		// Audio Format
		if(preset.audioSettings.settingsDictionary[AVFormatIDKey])
		{
			NSInteger index = [prefsAudioFormat indexOfItemWithRepresentedObject:preset.audioSettings.settingsDictionary[AVFormatIDKey]];
			if(index > 0)
				[prefsAudioFormat selectItemAtIndex:index];
			else
				[prefsAudioFormat selectItemAtIndex:0];
		}
		else
			[prefsAudioFormat selectItemAtIndex:0];

		// Audio Quality
		if(preset.audioSettings.settingsDictionary[AVEncoderAudioQualityKey])
		{
			NSInteger index = [prefsAudioQuality indexOfItemWithRepresentedObject:preset.audioSettings.settingsDictionary[AVEncoderAudioQualityKey]];
			if(index > 0)
				[prefsAudioQuality selectItemAtIndex:index];
			else
				[prefsAudioQuality selectItemAtIndex:0];

		}
		else
			[prefsAudioQuality selectItemAtIndex:0];

		// Audio Rate
		if(preset.audioSettings.settingsDictionary[AVSampleRateKey])
		{
			NSInteger index = [prefsAudioRate indexOfItemWithRepresentedObject:preset.audioSettings.settingsDictionary[AVSampleRateKey]];
			if(index > 0)
				[prefsAudioRate selectItemAtIndex:index];
			else
				[prefsAudioRate selectItemAtIndex:0];
		}
		else
			[prefsAudioRate selectItemAtIndex:0];

		
		// Audio Bitrate
		if(preset.audioSettings.settingsDictionary[AVEncoderBitRateKey])
		{
			NSInteger index = [prefsAudioBitrate indexOfItemWithRepresentedObject:preset.audioSettings.settingsDictionary[AVEncoderBitRateKey]];
			if(index > 0)
				[prefsAudioBitrate selectItemAtIndex:index];
			else
				[prefsAudioBitrate selectItemAtIndex:0];
		}
		else
			[prefsAudioBitrate selectItemAtIndex:0];

	}
	// No audio settings at all = passthrough
	else
	{
		[prefsAudioFormat selectItemAtIndex:0];
		[prefsAudioQuality selectItemAtIndex:0];
		[prefsAudioRate selectItemAtIndex:0];
		[prefsAudioBitrate selectItemAtIndex:0];
	}
}

- (void) configureVideoSettingsFromPreset:(PresetObject*)preset
{
	//NSLog(@"%s",__func__);
	// configure editability:
	useVideoCheckButton.enabled = preset.editable;
	prefsVideoCompressor.enabled = preset.editable && preset.useVideo;
	prefsVideoDimensions.enabled = preset.editable	 && preset.useVideo;
	prefsVideoDimensionsCustomWidth.stringValue = @"";
	prefsVideoDimensionsCustomHeight.stringValue = @"";
	prefsVideoDimensionsCustomWidth.enabled = preset.editable && preset.useVideo;
	prefsVideoDimensionsCustomHeight.enabled = preset.editable && preset.useVideo;
	prefsVideoQuality.enabled = preset.editable && preset.useVideo;
	prefsVideoAspectRatio.enabled = preset.editable && preset.useVideo;
	
	useVideoCheckButton.state = (preset.useVideo) ? 1 : 0;
	
	if(preset.videoSettings.settingsDictionary)
	{
		// Codec
		if(preset.videoSettings.settingsDictionary[AVVideoCodecKey])
		{
			NSInteger index = [prefsVideoCompressor indexOfItemWithRepresentedObject:preset.videoSettings.settingsDictionary[AVVideoCodecKey]];
			if(index > 0)
				[prefsVideoCompressor selectItemAtIndex:index];
			else
				[prefsVideoCompressor selectItemAtIndex:0];
		}
		else
			[prefsVideoCompressor selectItemAtIndex:0];

		// Size
		if(preset.videoSettings.settingsDictionary[AVVideoWidthKey]
		   && preset.videoSettings.settingsDictionary[AVVideoHeightKey])
		{
			float width = [preset.videoSettings.settingsDictionary[AVVideoWidthKey] floatValue];
			float height = [preset.videoSettings.settingsDictionary[AVVideoHeightKey] floatValue];
			
			NSSize presetSize = NSMakeSize(width, height);

			if(!NSEqualSizes(presetSize, NSZeroSize))
			{
				NSValue* sizeValue = [NSValue valueWithSize:presetSize];
				
				NSInteger index = [prefsVideoDimensions indexOfItemWithRepresentedObject:sizeValue];
				
				if(index > 0)
				{
					[prefsVideoDimensions selectItemAtIndex:index];
					
					// Update the custom size UI with the appropriate values
					NSSize selectedSize = [prefsVideoDimensions.selectedItem.representedObject sizeValue];
					prefsVideoDimensionsCustomWidth.floatValue = selectedSize.width;
					prefsVideoDimensionsCustomHeight.floatValue = selectedSize.height;
					
					prefsVideoDimensionsCustomWidth.enabled = NO;
					prefsVideoDimensionsCustomHeight.enabled = NO;
				}
				// Custom size
				else
				{
					[prefsVideoDimensions selectItemAtIndex:[prefsVideoDimensions itemArray].count - 1];
					prefsVideoDimensionsCustomWidth.stringValue = [NSString stringWithFormat:@"%f", width, nil];
					prefsVideoDimensionsCustomHeight.stringValue = [NSString stringWithFormat:@"%f", height, nil];
				}
			}
			// Native size if NSZeroSize
			else
				[prefsVideoDimensions selectItemAtIndex:0];

		}
		else
			[prefsVideoDimensions selectItemAtIndex:0];

		// Quality
		if(preset.videoSettings.settingsDictionary[AVVideoQualityKey])
		{
			NSInteger index = [prefsVideoQuality indexOfItemWithRepresentedObject:preset.videoSettings.settingsDictionary[AVVideoQualityKey]];
			if(index > 0)
				[prefsVideoQuality selectItemAtIndex:index];
			else
				[prefsVideoQuality selectItemAtIndex:0];
		}
		else
			[prefsVideoQuality selectItemAtIndex:0];
		
		// Aspect Ratio
		if(preset.videoSettings.settingsDictionary[AVVideoScalingModeKey])
		{
			NSInteger index = [prefsVideoAspectRatio indexOfItemWithRepresentedObject:preset.videoSettings.settingsDictionary[AVVideoScalingModeKey]];
			
			if(index > 0)
				[prefsVideoAspectRatio selectItemAtIndex:index];
			else
				[prefsVideoAspectRatio selectItemAtIndex:0];
		}
		else
			[prefsVideoAspectRatio selectItemAtIndex:0];
		
	}
	// No video settings at all = passthrough
	else
	{
		[prefsVideoCompressor selectItemAtIndex:0];
		[prefsVideoDimensions selectItemAtIndex:0];
		[prefsVideoQuality selectItemAtIndex:0];
		[prefsVideoAspectRatio selectItemAtIndex:0];
	}
}

- (void) configureAnalysisSettingsFromPreset:(PresetObject*)preset
{
	//NSLog(@"%s",__func__);
	// configure editability:
	useAnalysisCheckButton.enabled = preset.editable;
	jsonOptionsButton.enabled = preset.editable  && preset.useAnalysis;

	useAnalysisCheckButton.state = (preset.useAnalysis) ? 1 : 0;
	[jsonOptionsButton selectItemWithTag:(NSInteger)(preset.metadataExportOption)];
}

- (void) savePreset	{
	// Update our preferences
	[self buildAudioPreferences];
	[self buildVideoPreferences];
	[self buildAnalysisPrefs];
	
	[self.selectedPreset saveToDisk];
	
	self.presetChanged = NO;
}


#pragma mark - Video Prefs Validation


- (void) validateVideoPrefsUI
{
	//NSLog(@"%s",__func__);
	// update UI / hack since we dont have validator code yet
	[self selectVideoEncoder:prefsVideoCompressor.selectedItem];

}

- (void) buildVideoPreferences
{
	//NSLog(@"%s",__func__);
	NSMutableDictionary* videoSettingsDictonary = [NSMutableDictionary new];
	
	// get our fourcc from our compressor UI represented object and convert it to a string
	id compressorFourCC = prefsVideoCompressor.selectedItem.representedObject;
	
	// If we are passthrough, we set out video prefs to nil and bail early
	if(compressorFourCC == [NSNull null] || compressorFourCC == nil)
	{
		self.selectedPreset.videoSettings = nil;
		return;
	}
	
	// Otherwise introspect our codec dictionary
	if([compressorFourCC isKindOfClass:[NSString class]])
	{
		
		videoSettingsDictonary[AVVideoCodecKey] = compressorFourCC;
	}
	// if we have a dimension, custom or other wise, get it
	id sizeValue = prefsVideoDimensions.selectedItem.representedObject;
	
	// Custom Size for NULL entry
	if(sizeValue == [NSNull null])
	{
		videoSettingsDictonary[AVVideoWidthKey] =  @(prefsVideoDimensionsCustomWidth.floatValue);
		videoSettingsDictonary[AVVideoHeightKey] =	@(prefsVideoDimensionsCustomHeight.floatValue);
		
		// If we have a non native size, we need the aspect key
		videoSettingsDictonary[AVVideoScalingModeKey] = prefsVideoAspectRatio.selectedItem.representedObject;
	}
	else if([sizeValue isKindOfClass:[NSValue class]])
	{
		NSSize videoSize = [prefsVideoDimensions.selectedItem.representedObject sizeValue];
		
		// Native size for NSZeroSize
		if(!NSEqualSizes(videoSize, NSZeroSize))
		{
			videoSettingsDictonary[AVVideoWidthKey] =  @(videoSize.width);
			videoSettingsDictonary[AVVideoHeightKey] =	@(videoSize.height);
			
			// If we have a non native size, we need the aspect key
			videoSettingsDictonary[AVVideoScalingModeKey] = prefsVideoAspectRatio.selectedItem.representedObject;
		}
	}
	
	// if we have a quality, get it,
	id qualityValue = prefsVideoQuality.selectedItem.representedObject;
	
	if(qualityValue != [NSNull null])
	{
		if([qualityValue isKindOfClass:[NSNumber class]])
		{
			NSDictionary* videoCompressionOptionsDictionary = @{AVVideoQualityKey : qualityValue};
			videoSettingsDictonary[AVVideoCompressionPropertiesKey] =  videoCompressionOptionsDictionary;
		}
	}
	
	self.selectedPreset.videoSettings = [PresetVideoSettings settingsWithDict:videoSettingsDictonary];
	
	//NSLog(@"Calculated Video Settings : %@", self.selectedPreset.videoSettings.settingsDictionary);
}


#pragma mark - Audio Prefs


- (void) validateAudioPrefsUI
{
	//NSLog(@"%s",__func__);
	// update UI / hack since we dont have validator code yet
	[self selectAudioFormat:prefsAudioFormat.selectedItem];
}


// Todo: Number of channels?
- (void) buildAudioPreferences
{
	//NSLog(@"%s",__func__);
	NSMutableDictionary* audioSettingsDictonary = [NSMutableDictionary new];
	
	// get our fourcc from our compressor UI represented object and convert it to a string
	id audioFormat = prefsAudioFormat.selectedItem.representedObject;
	
	// If we are passthrough, we set out video prefs to nil and bail early
	if(audioFormat == [NSNull null] || audioFormat == nil)
	{
		self.selectedPreset.audioSettings = nil;
		return;
	}
	
	// Standard keys
	audioSettingsDictonary[AVFormatIDKey] = audioFormat;
	audioSettingsDictonary[AVSampleRateKey] = prefsAudioRate.selectedItem.representedObject;
	
	// for now, we let our encoder match source - this is handled in our transcoder
	audioSettingsDictonary[AVNumberOfChannelsKey] = [NSNull null];
	
	switch ([audioFormat intValue])
	{
		case kAudioFormatLinearPCM:
		{
			// Add LinearPCM required keys
			audioSettingsDictonary[AVLinearPCMBitDepthKey] = @(16);
			audioSettingsDictonary[AVLinearPCMIsBigEndianKey] = @(NO);
			audioSettingsDictonary[AVLinearPCMIsFloatKey] = @(NO);
			audioSettingsDictonary[AVLinearPCMIsNonInterleavedKey] = @(NO);
			
			break;
		}
		case kAudioFormatAppleLossless:
		{
			// audioSettingsDictonary[AVEncoderAudioQualityKey] = self.prefsAudioQuality.selectedItem.representedObject;
			//audioSettingsDictonary[AVEncoderBitRateKey] = prefsAudioBitrate.selectedItem.representedObject;
			audioSettingsDictonary[AVSampleRateConverterAlgorithmKey] = AVSampleRateConverterAlgorithm_Normal;
			//audioSettingsDictonary[AVEncoderBitRateStrategyKey] = AVAudioBitRateStrategy_Constant;
			audioSettingsDictonary[AVEncoderBitDepthHintKey] = @( 32 );
			
			break;
		}
		case kAudioFormatMPEG4AAC:
		{
			// audioSettingsDictonary[AVEncoderAudioQualityKey] = self.prefsAudioQuality.selectedItem.representedObject;
			audioSettingsDictonary[AVEncoderBitRateKey] = prefsAudioBitrate.selectedItem.representedObject;
			audioSettingsDictonary[AVSampleRateConverterAlgorithmKey] = AVSampleRateConverterAlgorithm_Normal;
			audioSettingsDictonary[AVEncoderBitRateStrategyKey] = AVAudioBitRateStrategy_Constant;
			
			break;
		}
		default:
			break;
	}
	
	self.selectedPreset.audioSettings = [PresetAudioSettings settingsWithDict:audioSettingsDictonary];
	
	//NSLog(@"Calculated Audio Settings : %@", self.selectedPreset.audioSettings.settingsDictionary);
}


#pragma mark - Video Prefs Actions


- (IBAction)selectUseVideo:(NSButton*)sender
{
	//NSLog(@"%s",__func__);
	self.selectedPreset.useVideo = (BOOL)sender.state;
	self.presetChanged = YES;
}

- (IBAction)selectVideoEncoder:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	
	// If we are on passthrough encoder, then we disable all our options
	if(prefsVideoCompressor.selectedItem.representedObject == [NSNull null])
	{
		// disable other ui
		prefsVideoAspectRatio.enabled = NO;
		[prefsVideoAspectRatio selectItemAtIndex:0];
		
		prefsVideoDimensions.enabled = NO;
		[prefsVideoDimensions selectItemAtIndex:0];
		
		prefsVideoQuality.enabled = NO;
		[prefsVideoQuality selectItemAtIndex:0];
		
		prefsVideoDimensionsCustomHeight.enabled = NO;
		prefsVideoDimensionsCustomHeight.stringValue = @"";
		
		prefsVideoDimensionsCustomWidth.enabled = NO;
		prefsVideoDimensionsCustomWidth.stringValue = @"";
	}
	else
	{
		if(self.selectedPreset.editable)
			prefsVideoDimensions.enabled = YES;
		
		// If we are on JPEG, enable quality
		NSString* codecFourCC = prefsVideoCompressor.selectedItem.representedObject;
		if( [codecFourCC isEqualToString:@"JPEG"])
		{
			if(self.selectedPreset.editable)
				prefsVideoQuality.enabled = YES;
			[prefsVideoQuality selectItemAtIndex:4];
		}
		else
		{
			prefsVideoQuality.enabled = NO;
			[prefsVideoQuality selectItemAtIndex:0];
		}
	}
	
	
	self.presetChanged = YES;
}

- (IBAction)selectVideoResolution:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	
	// If we are on the first (Native) resolution
	if (prefsVideoDimensions.indexOfSelectedItem == 0)
	{
		[prefsVideoAspectRatio selectItemAtIndex:0];
		// Enable 'Native'
		[[prefsVideoAspectRatio itemAtIndex:0] setEnabled:YES];
		prefsVideoAspectRatio.enabled = NO;
	}
	else
	{
		// Disable the native aspect ratio choice, and select aspect fill by default
		prefsVideoAspectRatio.enabled = YES;
		// Disable 'Native'
		[[prefsVideoAspectRatio itemAtIndex:0] setEnabled:NO];
		[prefsVideoAspectRatio selectItemAtIndex:2];
	}
	
	// if our video resolution is custom
	if(prefsVideoDimensions.selectedItem.representedObject == [NSNull null])
	{
		prefsVideoDimensionsCustomWidth.enabled = YES;
		prefsVideoDimensionsCustomHeight.enabled = YES;
	}
	else
	{
		// Update the custom size UI with the appropriate values
		NSSize selectedSize = [prefsVideoDimensions.selectedItem.representedObject sizeValue];
		prefsVideoDimensionsCustomWidth.floatValue = selectedSize.width;
		prefsVideoDimensionsCustomHeight.floatValue = selectedSize.height;
		
		prefsVideoDimensionsCustomWidth.enabled = NO;
		prefsVideoDimensionsCustomHeight.enabled = NO;
	}
	
	self.presetChanged = YES;

}

- (IBAction)selectVideoQuality:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	
	self.presetChanged = YES;

}

- (IBAction)selectVideoAspectRatio:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	
	self.presetChanged = YES;

}


#pragma mark - Audio Prefs Actions


- (IBAction)selectUseAudio:(NSButton*)sender
{
	self.selectedPreset.useAudio = (BOOL)sender.state;
	self.presetChanged = YES;
	
	prefsAudioFormat.enabled = (BOOL)sender.state;
	prefsAudioRate.enabled = (BOOL)sender.state;
	prefsAudioBitrate.enabled = (BOOL)sender.state;
	prefsAudioQuality.enabled = (BOOL)sender.state;
}

- (IBAction)selectAudioFormat:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	
	// If we are on passthrough encoder, then we disable all our options
	if(prefsAudioFormat.selectedItem.representedObject == [NSNull null])
	{
		// disable other ui
		prefsAudioBitrate.enabled = NO;
		[prefsAudioBitrate selectItemAtIndex:0];
		
		prefsAudioQuality.enabled = NO;
		[prefsAudioQuality selectItemAtIndex:0];
		
		prefsAudioRate.enabled = NO;
		[prefsAudioRate selectItemAtIndex:0];
	}
	else
	{
		// if we have linear linear PCM (uncompressed) we dont enable bitrate / quality
		
		if([prefsAudioFormat.selectedItem.representedObject isEqual: @(kAudioFormatLinearPCM)])
		{
			prefsAudioBitrate.enabled = NO;
			prefsAudioQuality.enabled = NO;
			prefsAudioRate.enabled = YES;
		}
		else if ([prefsAudioFormat.selectedItem.representedObject isEqual: @(kAudioFormatAppleLossless)])
		{
			prefsAudioBitrate.enabled = NO;
			prefsAudioQuality.enabled = YES;
			prefsAudioRate.enabled = NO;
		}
		else
		{
			prefsAudioBitrate.enabled = YES;
			prefsAudioQuality.enabled = YES;
			prefsAudioRate.enabled = YES;
		}
	}

	self.presetChanged = YES;

}

- (IBAction)selectAudioSamplerate:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	self.presetChanged = YES;

}

- (IBAction)selectAudioQuality:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	self.presetChanged = YES;

}

- (IBAction)selectAudioBitrate:(id)sender
{
	//NSLog(@"%s ... %@",__func__,[sender representedObject]);
	self.presetChanged = YES;

}


#pragma mark - Analysis Prefs Actions


- (IBAction)selectUseAnalysis:(NSButton*)sender
{
	self.selectedPreset.useAnalysis = (BOOL)sender.state;
	jsonOptionsButton.enabled = (BOOL)sender.state;

	self.presetChanged = YES;
}

- (IBAction)selectExportJSON:(NSPopUpButton*)sender
{
	self.selectedPreset.metadataExportOption = (NSUInteger)sender.selectedTag;
	self.presetChanged = YES;
}

- (void) buildAnalysisPrefs
{
	// get our fourcc from our compressor UI represented object and convert it to a string
	self.selectedPreset.analyzerSettings = [PresetAnalysisSettings settingsWithDict:nil];
}


@end
