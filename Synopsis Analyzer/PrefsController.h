//
//  PrefsController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/17/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresetObject.h"
#import "PresetGroup.h"

@class PreferencesViewController;




@interface PrefsController : NSWindowController	{
}

+ (PrefsController *) global;

@property (weak) IBOutlet PreferencesViewController* prefsViewController;

//	populates any NSMenu with menu items for the presets/preset groups
- (void) populatePopUpButtonWithPresets:(NSPopUpButton *)inPUB;
//	returns the NSUUID of the default preset (or nil).  this corresponds to the representedObject of any populated menus
- (NSUUID *) defaultPresetUUID;
- (PresetObject *) defaultPreset;
- (NSArray *) allPresets;

@end


