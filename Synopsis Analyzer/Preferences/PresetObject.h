//
//	PresetObject.h
//	Synopsis
//
//	Created by vade on 12/27/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import <Synopsis/Synopsis.h>

#import "PresetSettings.h"




@interface PresetObject : NSObject<NSCopying>

- (id) initWithTitle:(NSString*)title audioSettings:(PresetAudioSettings*)audioSettings videoSettings:(PresetVideoSettings*)videoSettings analyzerSettings:(PresetAnalysisSettings*)analyzerSettings useAudio:(BOOL)useAudio useVideo:(BOOL)useVideo useAnalysis:(BOOL) useAnalysis exportOption:(SynopsisMetadataEncoderExportOption)exportOption editable:(BOOL)editable uuid:(NSString*)UUIDString;
- (id) initWithTitle:(NSString*)title audioSettings:(PresetAudioSettings*)audioSettings videoSettings:(PresetVideoSettings*)videoSettings analyzerSettings:(PresetAnalysisSettings*)analyzerSettings useAudio:(BOOL)useAudio useVideo:(BOOL)useVideo useAnalysis:(BOOL) useAnalysis exportOption:(SynopsisMetadataEncoderExportOption)exportOption editable:(BOOL)editable;

- (instancetype) initWithData:(NSData *)data;
- (instancetype) init NS_UNAVAILABLE;
- (NSData *)copyPresetDataWithError:(NSError **)outError;

- (BOOL) isEqual:(id)n;

- (BOOL) saveToDisk;

@property (readwrite) NSString* title;
@property (readwrite) PresetAudioSettings* audioSettings;
@property (readwrite) PresetVideoSettings* videoSettings;
@property (readwrite) PresetAnalysisSettings* analyzerSettings;

@property (readwrite) BOOL useAudio;
@property (readwrite) BOOL useVideo;
@property (readwrite) BOOL useAnalysis;
@property (readwrite) SynopsisMetadataEncoderExportOption metadataExportOption;
@property (readonly) BOOL editable;
@property (readonly) NSUUID* uuid;

- (NSString *) lengthyDescription;

@end



