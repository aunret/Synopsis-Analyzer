//
//	PreferencesGeneralViewController.h
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresetObject.h"

@interface PreferencesGeneralViewController : NSViewController
@property (weak) IBOutlet NSPopUpButton* defaultPresetPopupButton;
@property (copy) PresetObject* defaultPreset;

- (IBAction)setDefaultPresetAction:(NSMenuItem*)sender;

@end
