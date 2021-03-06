//
//	PreferencesGeneralViewController.m
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PreferencesGeneralViewController.h"
#import "PresetObject.h"
#import <Synopsis/Synopsis.h>
#import "Constants.h"
#import "AppDelegate.h"

#import "PrefsController.h"
#import "NSPopUpButtonAdditions.h"




@interface PreferencesGeneralViewController ()
@property (weak) IBOutlet NSTextField* selectedDefaultPresetDescription;
@end




@implementation PreferencesGeneralViewController

- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	__weak PreferencesGeneralViewController		*bss = self;
	
	[scriptAbs setUserDefaultsKey:kSynopsisAnalyzerOperationScriptKey];
	[scriptAbs setDisabledLabelString:@"No script selected"];
	[scriptAbs setCustomPathLabelString:@"Custom script..."];
	[scriptAbs setRecentPathLabelString:@"Recent scripts"];
	[scriptAbs updateUI];
	[scriptAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = NO;
		openPanel.canCreateDirectories = NO;
		openPanel.canChooseFiles = YES;
		openPanel.allowedFileTypes = @[ @"py" ];
		openPanel.message = @"Select Python script to use";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
			}
		}];
	}];
	
	[sessionScriptAbs setUserDefaultsKey:kSynopsisAnalyzerSessionScriptKey];
	[sessionScriptAbs setDisabledLabelString:@"No script selected"];
	[sessionScriptAbs setCustomPathLabelString:@"Custom script..."];
	[sessionScriptAbs setRecentPathLabelString:@"Recent scripts"];
	[sessionScriptAbs updateUI];
	[sessionScriptAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = NO;
		openPanel.canCreateDirectories = NO;
		openPanel.canChooseFiles = YES;
		openPanel.allowedFileTypes = @[ @"py" ];
		openPanel.message = @"Select Python script to use";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
			}
		}];
	}];
	
	[self populateDefaultPresetPopupButton];
}
- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
	[super viewDidLoad];
}

- (IBAction) defaultPresetPUBItemSelected:(id)sender	{
	//NSLog(@"%s ... %@",__func__,sender);
	if (sender == nil)
		return;
	//NSLog(@"\t\tselectedItem = %@",sender);
	PresetObject		*selectedPreset = [sender representedObject];
	//NSLog(@"\t\tselectedPreset = %@",selectedPreset);
	self.selectedDefaultPresetDescription.stringValue = selectedPreset.lengthyDescription;
	
	self.defaultPreset = selectedPreset;
	
	//[self.defaultPresetPopupButton setTitle:selectedPreset.title];
	
	[[NSUserDefaults standardUserDefaults] setObject:self.defaultPreset.uuid.UUIDString forKey:kSynopsisAnalyzerDefaultPresetPreferencesKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (BOOL) opScriptEnabled	{
	return [scriptAbs enabled];
}
- (NSString *) opScript	{
	return [scriptAbs path];
}
- (BOOL) sessionScriptEnabled	{
	return [sessionScriptAbs enabled];
}
- (NSString *) sessionScript	{
	return [sessionScriptAbs path];
}


- (void) populateDefaultPresetPopupButton	{
	//NSLog(@"%s",__func__);
	
	[self.defaultPresetPopupButton setAutoenablesItems:NO];
	
	PrefsController		*pc = [PrefsController global];
	PresetObject		*defaultPreset = [pc defaultPreset];
	
	[pc populatePopUpButtonWithPresets:self.defaultPresetPopupButton];
	
	[self.defaultPresetPopupButton selectItemWithRepresentedObject:defaultPreset andOutput:YES];
}


@end
