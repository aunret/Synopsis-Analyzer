//
//	PreferencesGeneralViewController.h
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresetObject.h"
#import "PrefsPathPickerAbstraction.h"




@interface PreferencesGeneralViewController : NSViewController	{
	IBOutlet PrefsPathPickerAbstraction		*scriptAbs;
	IBOutlet PrefsPathPickerAbstraction		*sessionScriptAbs;
}

@property (weak) IBOutlet NSPopUpButton* defaultPresetPopupButton;
@property (copy) PresetObject* defaultPreset;

- (IBAction) defaultPresetPUBItemSelected:(id)sender;

- (BOOL) opScriptEnabled;
- (NSString *) opScript;
- (BOOL) sessionScriptEnabled;
- (NSString *) sessionScript;

//	populates my preset PUB
- (void) populateDefaultPresetPopupButton;

@end
