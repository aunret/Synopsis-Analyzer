//
//  PresetSettings.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/19/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PresetSettings.h"




@implementation PresetSettings;
+ (instancetype) settingsWithDict:(NSDictionary*)dictionary
{
	PresetSettings* preset =  [[[self class] alloc] init];
	
	if(preset)
		preset.settingsDictionary = dictionary;
	
	return preset;
}

+ (instancetype) none;
{
	return [[[self class] alloc] init];
}

@end


@implementation PresetAudioSettings
@end

@implementation PresetVideoSettings
@end

@implementation PresetAnalysisSettings;
/*
+ (instancetype) defaultAnalysisSettings	{
	PresetSettings		*preset = [[[self class] alloc] init];
	
	if (preset)	{
		preset.settingsDictionary = @{
			kSynopsisAnalysisSettingsQualityHintKey : @( SynopsisAnalysisQualityHintMedium ),
			kSynopsisAnalysisSettingsEnabledPluginsKey : @[ @"StandardAnalyzerPlugin" ],
			kSynopsisAnalysisSettingsEnableConcurrencyKey : @YES,
		};
	}
	
	return preset;
}
*/
@end
