//
//	PresetObject.m
//	Synopsis
//
//	Created by vade on 12/27/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PresetObject.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>
#import <VideoToolbox/VTProfessionalVideoWorkflow.h>

#import <HapInAVFoundation/HapInAVFoundation.h>




@interface PresetObject ()
@property (readwrite) BOOL editable;
@property (readwrite) NSUUID* uuid;
//@property (readwrite) NSString* zero;
//@property (readwrite) NSString* one;
//@property (readwrite) NSString* two;
@end




@implementation PresetObject

- (id) initWithTitle:(NSString*)title audioSettings:(PresetAudioSettings*)audioSettings videoSettings:(PresetVideoSettings*)videoSettings analyzerSettings:(PresetAnalysisSettings*)analyzerSettings useAudio:(BOOL)useAudio useVideo:(BOOL)useVideo useAnalysis:(BOOL) useAnalysis exportOption:(SynopsisMetadataEncoderExportOption)exportOption editable:(BOOL)editable uuid:(NSString*)UUIDString
{
	self = [super init];
	if(self)
	{
		self.title = title;
		
		self.audioSettings = audioSettings;
		self.videoSettings = videoSettings;
		self.analyzerSettings = analyzerSettings;
		
		self.useAudio = useAudio;
		self.useVideo = useVideo;
		self.useAnalysis = useAnalysis;
		self.metadataExportOption = exportOption;
		self.editable = editable;
		self.uuid = [[NSUUID alloc] initWithUUIDString:UUIDString];
		
		return self;
	}
	return nil;
}

- (id) initWithTitle:(NSString*)title audioSettings:(PresetAudioSettings*)audioSettings videoSettings:(PresetVideoSettings*)videoSettings analyzerSettings:(PresetAnalysisSettings*)analyzerSettings useAudio:(BOOL)useAudio useVideo:(BOOL)useVideo useAnalysis:(BOOL) useAnalysis exportOption:(SynopsisMetadataEncoderExportOption)exportOption editable:(BOOL)editable
{
	self = [super init];
	if(self)
	{
		self.title = title;
		
		self.audioSettings = audioSettings;
		self.videoSettings = videoSettings;
		self.analyzerSettings = analyzerSettings;
		
		self.useAudio = useAudio;
		self.useVideo = useVideo;
		self.useAnalysis = useAnalysis;
		
		self.editable = editable;
		self.uuid = [NSUUID UUID];
		
		self.metadataExportOption = SynopsisMetadataEncoderExportOptionNone;
		
		return self;
	}
	return nil;
}

- (instancetype) initWithData:(NSData *)data
{
	self = [super init];
	if(self)
	{
		@try
		{
			NSDictionary* savedDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			
			self.title = savedDict[kSynopsisAnalyzerPresetTitleKey];
			
			self.audioSettings = [PresetAudioSettings settingsWithDict:savedDict[kSynopsisAnalyzerPresetAudioSettingsKey]];
			self.videoSettings = [PresetVideoSettings settingsWithDict:savedDict[kSynopsisAnalyzerPresetVideoSettingsKey]];
			self.analyzerSettings = [PresetAnalysisSettings settingsWithDict:savedDict[kSynopsisAnalyzerPresetAnalysisSettingsKey]];
			
			self.useAudio = [savedDict[kSynopsisAnalyzerPresetUseAudioKey] boolValue];
			self.useVideo = [savedDict[kSynopsisAnalyzerPresetUseVideoKey] boolValue];
			self.useAnalysis = [savedDict[kSynopsisAnalyzerPresetUseAnalysisKey] boolValue];
			self.metadataExportOption = [savedDict[kSynopsisAnalyzerPresetExportOptionsKey] integerValue];
			self.editable = [savedDict[kSynopsisAnalyzerPresetEditableKey] boolValue];
			self.uuid = [[NSUUID alloc] initWithUUIDString:savedDict[kSynopsisAnalyzerPresetUUIDKey]];
		}
		@catch (NSException *exception)
		{
			return nil;
		}
	}
	
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
	// Copy keeps the UUID
	return [[PresetObject allocWithZone:zone] initWithTitle:self.title
											  audioSettings:self.audioSettings
											  videoSettings:self.videoSettings
										   analyzerSettings:self.analyzerSettings
												   useAudio:self.useAudio
												   useVideo:self.useVideo
												useAnalysis:self.useAnalysis
												exportOption:self.metadataExportOption
												   editable:self.editable
													   uuid:self.uuid.UUIDString];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
	// Mutable copy gives us a new UUID?
	return [[PresetObject allocWithZone:zone] initWithTitle:self.title
											  audioSettings:self.audioSettings
											  videoSettings:self.videoSettings
										   analyzerSettings:self.analyzerSettings
												   useAudio:self.useAudio
												   useVideo:self.useVideo
												useAnalysis:self.useAnalysis
											   exportOption:self.metadataExportOption
												   editable:YES
													   uuid:[NSUUID UUID].UUIDString];
}

- (NSData *)copyPresetDataWithError:(NSError **)outError
{
	NSData* data = nil;
	@try
	{
		NSMutableDictionary* savedDict = [NSMutableDictionary dictionary];
		
		savedDict[kSynopsisAnalyzerPresetTitleKey] = self.title;
		
		savedDict[kSynopsisAnalyzerPresetAudioSettingsKey] =  self.audioSettings.settingsDictionary;
		savedDict[kSynopsisAnalyzerPresetVideoSettingsKey] = self.videoSettings.settingsDictionary;
		savedDict[kSynopsisAnalyzerPresetAnalysisSettingsKey] = self.analyzerSettings.settingsDictionary;
		
		savedDict[kSynopsisAnalyzerPresetUseAudioKey] = @(self.useAudio);
		savedDict[kSynopsisAnalyzerPresetUseVideoKey] = @(self.useVideo);
		savedDict[kSynopsisAnalyzerPresetUseAnalysisKey] = @(self.useAnalysis);
		savedDict[kSynopsisAnalyzerPresetExportOptionsKey] = @(self.metadataExportOption);

		savedDict[kSynopsisAnalyzerPresetEditableKey] = @(self.editable);
		savedDict[kSynopsisAnalyzerPresetUUIDKey] = (self.uuid.UUIDString);
		
		data = [NSKeyedArchiver archivedDataWithRootObject:savedDict];
	}
	@catch (NSException *exception)
	{
		NSDictionary *d = [NSDictionary dictionaryWithObject:@"Unable to archive preset" forKey:NSLocalizedFailureReasonErrorKey];
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:-1 userInfo:d];
		return nil;
	}
	
	return data;
}


- (BOOL) isEqual:(id)n	{
	if (![n isKindOfClass:[self class]])
		return NO;
	PresetObject		*recast = (PresetObject *)n;
	if (recast == self)
		return YES;
	if (self.uuid == nil || recast.uuid == nil)
		return NO;
	return ([self.uuid.UUIDString isEqualToString:recast.uuid.UUIDString]);
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<PresetObject: %@>",self.title];
}
- (NSString*) lengthyDescription
{
	NSString* lengthyDescription = @"";
	
	NSString* videoSettingsString = [@"Video : " stringByAppendingString:[self videoFormatString]];
	NSString* audioSettingsString = [@"Audio : " stringByAppendingString:[self audioFormatString]];

	lengthyDescription = [lengthyDescription stringByAppendingString:videoSettingsString];
	lengthyDescription = [lengthyDescription stringByAppendingString:@"\n\r"];
	lengthyDescription = [lengthyDescription stringByAppendingString:audioSettingsString];

	return lengthyDescription;
}

- (NSString*) audioFormatString	{
	NSString* audioFormat = @"";
	
	if(self.useAudio == NO)
		return [audioFormat stringByAppendingString:@"None"];
	
	if(self.audioSettings == nil || self.audioSettings.settingsDictionary == nil)
		return [audioFormat stringByAppendingString:@"Passthrough"];
	
	if(self.audioSettings.settingsDictionary)
	{
		if(self.audioSettings.settingsDictionary[AVFormatIDKey] == [NSNull null])
			return [audioFormat stringByAppendingString:@"Passthrough"];
		
		else if([self.audioSettings.settingsDictionary[AVFormatIDKey]  isEqual: @(kAudioFormatLinearPCM)])
			audioFormat = [audioFormat stringByAppendingString:@"Linear PCM"];
		
		else if([self.audioSettings.settingsDictionary[AVFormatIDKey]  isEqual: @(kAudioFormatAppleLossless)])
			audioFormat = [audioFormat stringByAppendingString:@"Apple Lossless"];
		
		else if([self.audioSettings.settingsDictionary[AVFormatIDKey]  isEqual: @(kAudioFormatMPEG4AAC)])
			audioFormat = [audioFormat stringByAppendingString:@"AAC"];
		
		audioFormat = [audioFormat stringByAppendingString:@", "];

		if(self.audioSettings.settingsDictionary[AVEncoderBitRateKey] != [NSNull null] && self.audioSettings.settingsDictionary[AVEncoderBitRateKey] != nil)
		{
			audioFormat = [audioFormat stringByAppendingString:[self.audioSettings.settingsDictionary[AVEncoderBitRateKey] stringValue]];
			audioFormat = [audioFormat stringByAppendingString:@" kbps, "];
		}
		
		if(self.audioSettings.settingsDictionary[AVSampleRateKey] != [NSNull null] && self.audioSettings.settingsDictionary[AVSampleRateKey] != nil)
			audioFormat = [audioFormat stringByAppendingString:[self.audioSettings.settingsDictionary[AVSampleRateKey] stringValue]];
		else
			audioFormat = [audioFormat stringByAppendingString:@" Match"];

		audioFormat = [audioFormat stringByAppendingString:@"khz, "];

		if(self.audioSettings.settingsDictionary[AVNumberOfChannelsKey] != [NSNull null] && self.audioSettings.settingsDictionary[AVNumberOfChannelsKey] != nil)
			audioFormat = [audioFormat stringByAppendingString:[self.audioSettings.settingsDictionary[AVNumberOfChannelsKey] stringValue]];
		else
			audioFormat = [audioFormat stringByAppendingString:@"Match"];

		audioFormat = [audioFormat stringByAppendingString:@" Channels"];

	}
	else
		return [audioFormat stringByAppendingString:@"Passthrough"];

	return audioFormat;
}

- (NSString*) videoFormatString	{
	NSString* videoFormat = @"";
	
	if(self.useVideo == NO)
		return [videoFormat stringByAppendingString:@"None"];

	if(self.videoSettings == nil || self.videoSettings.settingsDictionary == nil)
		return [videoFormat stringByAppendingString:@"Passthrough"];

	if(self.videoSettings.settingsDictionary)
	{
		if(self.videoSettings.settingsDictionary[AVVideoCodecKey] == [NSNull null])
			return [videoFormat stringByAppendingString:@"Passthrough"];
		
		CFArrayRef			videoEncoders;
		VTCopyVideoEncoderList(NULL, &videoEncoders);
		NSMutableArray*		videoEncodersArray = [(__bridge NSArray*)videoEncoders mutableCopy];
	
		// fourcc requires 'icod' (need to add the 's)
		OSType				fourcc = NSHFSTypeCodeFromFileType([@"'" stringByAppendingString:[self.videoSettings.settingsDictionary[AVVideoCodecKey] stringByAppendingString:@"'"]]);
		NSNumber*			fourccNum = [NSNumber numberWithInt:fourcc];
		
		NSString*			encoderName = nil;
		for(NSDictionary* encoder in videoEncodersArray)
		{
			NSNumber*			codecType = (NSNumber*)encoder[(NSString*)kVTVideoEncoderList_CodecType];
			if([codecType isEqual:fourccNum])
			{
				encoderName = encoder[(NSString*)kVTVideoEncoderList_DisplayName];
				break;
			}
		}
		
		if(encoderName == nil)
		{
			// ADD HAP HERE
			NSString		*settingsCodecKey = self.videoSettings.settingsDictionary[AVVideoCodecKey];
			if ([settingsCodecKey isEqualToString:AVVideoCodecHap])	{
				encoderName = @"Hap";
			}
			else if ([settingsCodecKey isEqualToString:AVVideoCodecHapAlpha])	{
				encoderName = @"Hap Alpha";
			}
			else if ([settingsCodecKey isEqualToString:AVVideoCodecHapQ])	{
				encoderName = @"HapQ";
			}
			else if ([settingsCodecKey isEqualToString:AVVideoCodecHapQAlpha])	{
				encoderName = @"HapQ Alpha";
			}
		}
		
		if(encoderName)
			videoFormat = [videoFormat stringByAppendingString:encoderName];

		if(self.videoSettings.settingsDictionary[AVVideoWidthKey] && self.videoSettings.settingsDictionary[AVVideoHeightKey])
		{
			videoFormat = [videoFormat stringByAppendingString:@" , "];
			videoFormat = [videoFormat stringByAppendingString:[self.videoSettings.settingsDictionary[AVVideoWidthKey] stringValue]];
			videoFormat = [videoFormat stringByAppendingString:@" x "];
			videoFormat = [videoFormat stringByAppendingString:[self.videoSettings.settingsDictionary[AVVideoHeightKey] stringValue]];
		}
		else
		{
			videoFormat = [videoFormat stringByAppendingString:@", Native Size"];
		}
		
		CFRelease(videoEncoders);
	}
	return videoFormat;
}

@end





