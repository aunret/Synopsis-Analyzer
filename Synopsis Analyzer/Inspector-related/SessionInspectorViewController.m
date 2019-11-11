//
//  SessionInspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionInspectorViewController.h"

#import "SynSession.h"
#import "PrefsController.h"
#import "NSPopUpButtonAdditions.h"
#import "InspectorViewController.h"
#import "SessionController.h"




@interface SessionInspectorViewController ()
- (void) _updatePresetsPUB;
@end




@implementation SessionInspectorViewController


- (id) initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle	{
	//NSLog(@"%s",__func__);
	self = [super initWithNibName:inNibName bundle:inBundle];
	if (self != nil)	{
		//	register to receive notifications that the list of presets have updated
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(presetUpdateNotification:)
			name:kSynopsisPresetsChangedNotification
			object:nil];
	}
	return self;
}
- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
	[super viewDidLoad];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	__weak SessionInspectorViewController		*bss = self;
	
	//	configure the presets PUB
	[self _updatePresetsPUB];
	
	//	configure the output folder path UI items to update the selected object
	[outputFolderPathAbs setUserDefaultsKey:kSynopsisAnalyzerOutputFolderURLKey];
	[outputFolderPathAbs setDisabledLabelString:@"Same as source location"];
	[outputFolderPathAbs setCustomPathLabelString:@"Custom output folder..."];
	[outputFolderPathAbs setRecentPathLabelString:@"Recent output folders"];
	[outputFolderPathAbs setPrefsValueLabelString:@"Output folder from prefs"];
	[outputFolderPathAbs updateUI];
	[outputFolderPathAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Output Folder";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				
				//	update the inspected object's output dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setOutputDir:nil];
						else
							[bss.inspectedObject setOutputDir:inAbs.path];
					}
				});
			}
		}];
	}];
	[outputFolderPathAbs setPathChangeBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setOutputDir:nil];
				else
					[bss.inspectedObject setOutputDir:inAbs.path];
			}
		});
	}];
	
	//	configure the temp folder path UI items to update the selected object
	[tempFolderPathAbs setUserDefaultsKey:kSynopsisAnalyzerTempFolderURLKey];
	[tempFolderPathAbs setDisabledLabelString:@"Same as source location"];
	[tempFolderPathAbs setCustomPathLabelString:@"Custom output folder..."];
	[tempFolderPathAbs setRecentPathLabelString:@"Recent output folders"];
	[tempFolderPathAbs setPrefsValueLabelString:@"Output folder from prefs"];
	[tempFolderPathAbs updateUI];
	[tempFolderPathAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Temporary Items Folder";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* tempFolderURL = [openPanel URL];
				[inAbs setPath:[tempFolderURL path]];
				
				//	update the inspected object's temp dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setTempDir:nil];
						else
							[bss.inspectedObject setTempDir:inAbs.path];
					}
				});
			}
		}];
	}];
	[tempFolderPathAbs setPathChangeBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setTempDir:nil];
				else
					[bss.inspectedObject setTempDir:inAbs.path];
			}
		});
	}];
	
	//	configure the file script folder path UI items to update the selected object
	[opScriptPathAbs setUserDefaultsKey:kSynopsisAnalyzerOperationScriptKey];
	[opScriptPathAbs setDisabledLabelString:@"No script selected"];
	[opScriptPathAbs setCustomPathLabelString:@"Custom script..."];
	[opScriptPathAbs setRecentPathLabelString:@"Recent scripts"];
	[opScriptPathAbs setPrefsValueLabelString:@"Use script from prefs"];
	[opScriptPathAbs updateUI];
	[opScriptPathAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = NO;
		openPanel.canCreateDirectories = NO;
		openPanel.canChooseFiles = YES;
		openPanel.allowedFileTypes = @[ @"py" ];
		openPanel.message = @"Select Python script to use per-file";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* tempFolderURL = [openPanel URL];
				[inAbs setPath:[tempFolderURL path]];
				
				//	update the inspected object's temp dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setSessionScript:nil];
						else
							[bss.inspectedObject setSessionScript:inAbs.path];
					}
				});
			}
		}];
	}];
	[opScriptPathAbs setPathChangeBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setSessionScript:nil];
				else
					[bss.inspectedObject setSessionScript:inAbs.path];
			}
		});
	}];
	
	//	configure the session script folder path UI items to update the selected object
	[sessionScriptPathAbs setUserDefaultsKey:kSynopsisAnalyzerSessionScriptKey];
	[sessionScriptPathAbs setDisabledLabelString:@"No script selected"];
	[sessionScriptPathAbs setCustomPathLabelString:@"Custom script..."];
	[sessionScriptPathAbs setRecentPathLabelString:@"Recent scripts"];
	[sessionScriptPathAbs setPrefsValueLabelString:@"Use script from prefs"];
	[sessionScriptPathAbs updateUI];
	[sessionScriptPathAbs setOpenPanelBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = NO;
		openPanel.canCreateDirectories = NO;
		openPanel.canChooseFiles = YES;
		openPanel.allowedFileTypes = @[ @"py" ];
		openPanel.message = @"Select Python script to use per-session";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* tempFolderURL = [openPanel URL];
				[inAbs setPath:[tempFolderURL path]];
				
				//	update the inspected object's temp dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setOpScript:nil];
						else
							[bss.inspectedObject setOpScript:inAbs.path];
					}
				});
			}
		}];
	}];
	[sessionScriptPathAbs setPathChangeBlock:^(PrefsPathPickerAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setOpScript:nil];
				else
					[bss.inspectedObject setOpScript:inAbs.path];
			}
		});
	}];
}

- (void) inspectSession:(SynSession *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	self.inspectedObject = n;
	
	[self updateUI];
}


- (void) updateUI	{
	if (self.inspectedObject == nil)	{
		return;
	}
	
	if ([[SessionController global] processingFilesFromSession:self.inspectedObject])	{
		[sessionStateTabView selectTabViewItemAtIndex:1];
		return;
	}
	
	[sessionStateTabView selectTabViewItemAtIndex:0];
	
	//	populate the presets PUB
	if (self.inspectedObject.preset != nil)	{
		[presetsPUB selectItemWithRepresentedObject:self.inspectedObject.preset andOutput:NO];
		[presetDescriptionField setStringValue:[self.inspectedObject.preset lengthyDescription]];
	}
	else	{
		[presetsPUB selectItemWithRepresentedObject:[[PrefsController global] defaultPreset]];
		[presetDescriptionField setStringValue:[[[PrefsController global] defaultPreset] lengthyDescription]];
	}
	
	//	populate the output folder path UI items
	NSString		*tmpString = self.inspectedObject.outputDir;
	if (tmpString == nil)	{
		outputFolderPathAbs.enabled = NO;
		outputFolderPathAbs.path = [[PrefsController global] outputFolder];
	}
	else	{
		outputFolderPathAbs.enabled = YES;
		outputFolderPathAbs.path = tmpString;
	}
	
	//	populate the temp dir UI items
	tmpString = self.inspectedObject.tempDir;
	if (tmpString == nil)	{
		tempFolderPathAbs.enabled = NO;
		tempFolderPathAbs.path = [[PrefsController global] tempFolder];
	}
	else	{
		tempFolderPathAbs.enabled = YES;
		tempFolderPathAbs.path = tmpString;
	}
	
	//	update the script UI items
	tmpString = self.inspectedObject.sessionScript;
	if (tmpString == nil)	{
		sessionScriptPathAbs.enabled = NO;
		sessionScriptPathAbs.path = [[PrefsController global] sessionScript];
	}
	else	{
		sessionScriptPathAbs.enabled = YES;
		sessionScriptPathAbs.path = tmpString;
	}
	
	tmpString = self.inspectedObject.opScript;
	if (tmpString == nil)	{
		opScriptPathAbs.enabled = NO;
		opScriptPathAbs.path = [[PrefsController global] opScript];
	}
	else	{
		opScriptPathAbs.enabled = YES;
		opScriptPathAbs.path = tmpString;
	}
	
	//	populate the UI items that reside in the box that's only visible if it's a dir-type session
	if (self.inspectedObject.type == SessionType_Dir && self.inspectedObject.watchFolder)	{
		[sessionWatchDirBox setHidden:NO];
		[copyNonMediaToggle setIntValue:(self.inspectedObject.copyNonMediaFiles) ? NSControlStateValueOn : NSControlStateValueOff];
	}
	else	{
		[sessionWatchDirBox setHidden:YES];
	}
}


- (IBAction) presetsPUBItemSelected:(id)sender	{
	if (self.inspectedObject == nil)
		return;
	PresetObject		*newPreset = [sender representedObject];
	if (newPreset == nil || ![newPreset isKindOfClass:[PresetObject class]])
		return;
	self.inspectedObject.preset = newPreset;
	[presetDescriptionField setStringValue:[newPreset lengthyDescription]];
	
	//	if we changed the preset then we need to refresh the corresponding row in the table view...
	[[InspectorViewController global] reloadRowForItem:self.inspectedObject];
}
- (IBAction) copyNonMediaToggleUsed:(id)sender	{
	if (self.inspectedObject == nil || sender == nil)
		return;
	
	if ([sender intValue] == NSControlStateValueOn)
		self.inspectedObject.copyNonMediaFiles = YES;
	else
		self.inspectedObject.copyNonMediaFiles = NO;
}


- (void) presetUpdateNotification:(NSNotification *)note	{
	[self _updatePresetsPUB];
}
- (void) _updatePresetsPUB	{
	[presetsPUB setAutoenablesItems:NO];
	PrefsController		*pc = [PrefsController global];
	PresetObject		*defaultPreset = [pc defaultPreset];
	[pc populatePopUpButtonWithPresets:presetsPUB];
	
	if (self.inspectedObject != nil)	{
		if (self.inspectedObject.preset != nil)	{
			[presetsPUB selectItemWithRepresentedObject:self.inspectedObject.preset andOutput:NO];
			[presetDescriptionField setStringValue:[self.inspectedObject.preset lengthyDescription]];
		}
		else	{
			[presetsPUB selectItemWithRepresentedObject:defaultPreset andOutput:YES];
			[presetDescriptionField setStringValue:[self.inspectedObject.preset lengthyDescription]];
		}
	}
}


@end
