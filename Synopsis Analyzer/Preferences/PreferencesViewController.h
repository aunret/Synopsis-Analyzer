//
//	PreferencesViewController.h
//	Synopsis
//
//	Created by vade on 12/25/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresetObject.h"
#import "PreferencesGeneralViewController.h"
#import "PreferencesFileViewController.h"
#import "PreferencesPresetViewController.h"
#import "PreferencesAdvancedViewController.h"

@interface PreferencesViewController : NSViewController

@property (readonly, nonatomic, strong) PreferencesGeneralViewController* preferencesGeneralViewController;
@property (readonly, nonatomic, strong) PreferencesFileViewController* preferencesFileViewController;
@property (readonly, nonatomic, strong) PreferencesPresetViewController* preferencesPresetViewController;
@property (readonly, nonatomic, strong) PreferencesAdvancedViewController* preferencesAdvancedViewController;

//- (PresetObject*) defaultPreset;
//- (NSArray*) availablePresets;
//- (void) buildPresetMenu;

@end
