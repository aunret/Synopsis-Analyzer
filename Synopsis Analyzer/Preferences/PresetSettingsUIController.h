//
//  PresetSettingsUIController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/1/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PreferencesPresetViewController;
@class PresetObject;



@interface PresetSettingsUIController : NSObject	{
	IBOutlet PreferencesPresetViewController		*presetViewController;
	
	IBOutlet NSView				*overviewContainerView;
	IBOutlet NSTextField		*overviewTitleTextField;
	IBOutlet NSTextField		*overviewDescriptionTextField;
	
	IBOutlet NSButton			*overViewSavePresetButton;
	
	// Preferences Video
	IBOutlet NSView				*videoContainerView;
	IBOutlet NSButton			*useVideoCheckButton;
	IBOutlet NSPopUpButton		*prefsVideoCompressor;
	IBOutlet NSPopUpButton		*prefsVideoDimensions;
	IBOutlet NSPopUpButton		*prefsVideoQuality;
	IBOutlet NSTextField		*prefsVideoDimensionsCustomWidth;
	IBOutlet NSTextField		*prefsVideoDimensionsCustomHeight;
	IBOutlet NSPopUpButton		*prefsVideoAspectRatio;
	
	// Preferences Audio
	IBOutlet NSView				*audioContainerView;
	IBOutlet NSButton			*useAudioCheckButton;
	IBOutlet NSPopUpButton		*prefsAudioFormat;
	IBOutlet NSPopUpButton		*prefsAudioRate;
	IBOutlet NSPopUpButton		*prefsAudioQuality;
	IBOutlet NSPopUpButton		*prefsAudioBitrate;
	
	// Preferences Analysis
	IBOutlet NSView				*analysisContainerView;
	IBOutlet NSButton			*useAnalysisCheckButton;
	IBOutlet NSPopUpButton		*jsonOptionsButton;
}

@property (strong,atomic,readwrite) PresetObject * selectedPreset;
@property (readwrite, assign) BOOL presetChanged;

- (void) savePreset;

- (IBAction)selectUseVideo:(NSButton*)sender;
- (IBAction)selectVideoEncoder:(id)sender;
- (IBAction)selectVideoResolution:(id)sender;
- (IBAction)selectVideoQuality:(id)sender;
- (IBAction)selectVideoAspectRatio:(id)sender;

- (IBAction)selectUseAudio:(NSButton*)sender;
- (IBAction)selectAudioFormat:(id)sender;
- (IBAction)selectAudioSamplerate:(id)sender;
- (IBAction)selectAudioQuality:(id)sender;
- (IBAction)selectAudioBitrate:(id)sender;

- (IBAction)selectUseAnalysis:(NSButton*)sender;
- (IBAction)selectExportJSON:(NSPopUpButton*)sender;

@end




NS_ASSUME_NONNULL_END
