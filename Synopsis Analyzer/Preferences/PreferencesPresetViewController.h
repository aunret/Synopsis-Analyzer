//
//	PreferencesPresetViewController.h
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PresetObject.h"

@class PresetSettingsUIController;




@interface PreferencesPresetViewController : NSViewController

- (NSArray*) allPresets;

- (IBAction) addPresetClicked:(id)sender;
- (IBAction) removePresetClicked:(id)sender;

@end
