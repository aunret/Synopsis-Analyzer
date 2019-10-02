//
//	PreferencesPresetViewController.m
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//
#import "PreferencesViewController.h"
#import "PreferencesPresetViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PresetGroup.h"
//#import "AVAssetWriterHapInput.h"
#import <HapInAVFoundation/HapInAVFoundation.h>

#import "PrefsController.h"

#import "PresetSettingsUIController.h"




@interface PreferencesPresetViewController ()  <NSOutlineViewDataSource, NSOutlineViewDelegate, NSSplitViewDelegate>

@property (weak) IBOutlet PresetSettingsUIController * settingsUIController;
@property (weak) IBOutlet NSSplitView* stupidFuckingSplitview;
@property (weak) IBOutlet NSBox* presetInfoContainerBox;

@property (weak) IBOutlet NSOutlineView* presetOutlineView;

@property (weak) IBOutlet NSView* overviewContainerView;

@property (weak) IBOutlet NSButton* overViewSavePresetButton;

//@property (atomic, readwrite, strong) PresetGroup* selectedPresetGroup;

@property (strong,readwrite,atomic) NSMutableDictionary * expandStateDict;

- (void) reloadData;
- (void) restoreExpandStates;

@end




@implementation PreferencesPresetViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self)
	{
		
		//self.standardPresets = [[PresetGroup alloc] initWithTitle:@"Standard Presets" editable:NO];
		//self.customPresets = [[PresetGroup alloc] initWithTitle:@"Custom Presets" editable:NO];
		
		[PresetGroup class];
		[PresetObject class];
		
		self.expandStateDict = [NSMutableDictionary dictionaryWithCapacity:0];
		//self.selectedPresetGroup = [PresetGroup customPresets];
		
		return self;
	}
	
	return nil;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.stupidFuckingSplitview.delegate = self;
	
	self.presetOutlineView.dataSource = self;
	self.presetOutlineView.delegate = self;
}

#pragma mark - SplitView Delegate


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return 400;
}


#pragma mark - Outline View Delegate


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView* view = (NSTableCellView*)[outlineView makeViewWithIdentifier:@"Preset" owner:self];
	
	if([item isKindOfClass:[PresetGroup class]])
	{
		PresetGroup* itemGroup = (PresetGroup*)item;
		view.objectValue = itemGroup;
		view.textField.stringValue = itemGroup.title;
		view.textField.editable = itemGroup.editable;
		view.textField.selectable = itemGroup.editable;
		view.imageView.image = [NSImage imageNamed:@"ic_folder_white"];
	}
	else if ([item isKindOfClass:[PresetObject class]])
	{
		PresetObject* presetItem = (PresetObject*)item;
		view.objectValue = presetItem;
		view.textField.stringValue = presetItem.title;
		view.textField.editable = presetItem.editable;
		view.textField.selectable = presetItem.editable;
		view.imageView.image = [NSImage imageNamed:@"ic_insert_drive_file_white"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellDidEditText:) name:NSControlTextDidEndEditingNotification object:view.textField];

	}
	else if([item isKindOfClass:[PresetAudioSettings class]])
	{
		view.textField.editable = NO;
		view.textField.selectable = NO;

		view.textField.stringValue = @"Audio Settings";
		view.imageView.image = [NSImage imageNamed:@"ic_volume_up_white"];
	}
	
	else if([item isKindOfClass:[PresetVideoSettings class]])
	{
		view.textField.editable = NO;
		view.textField.selectable = NO;
		
		view.textField.stringValue = @"Video Settings";
		view.imageView.image = [NSImage imageNamed:@"ic_local_movies_white"];
	}
	else if([item isKindOfClass:[PresetAnalysisSettings class]])
	{
		view.textField.editable = NO;
		view.textField.selectable = NO;
		
		view.textField.stringValue = @"Analysis Settings";
		view.imageView.image = [NSImage imageNamed:@"ic_info_white"];
	}
	
	return view;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	// DO we have any pending changes for a preset
	if(self.settingsUIController.presetChanged)
	{
		// Present modal alert, ask to save changes
		NSAlert* changesAlert = [[NSAlert alloc] init];
		changesAlert.messageText = @"You have unsaved changes to your current preset";

		[changesAlert addButtonWithTitle:@"Save"];
		[changesAlert addButtonWithTitle:@"Cancel"];
		[changesAlert addButtonWithTitle:@"Revert"];

		NSModalResponse response = [changesAlert runModal];
		//	if "SAVE"
		if(response == NSAlertFirstButtonReturn)	{
			[self savePreset:nil];
			return YES;
		}
		//	else if "CANCEL"
		else if (response == NSAlertSecondButtonReturn)	{
			return NO;
		}
		//	else if "REVERT"
		else if (response == NSAlertSecondButtonReturn)	{
			return YES;
		}
		
	}
	
	if([item isKindOfClass:[PresetObject class]])
	{
		return YES;
	}
	return NO;
}
- (void)outlineViewSelectionDidChange:(NSNotification *)notification	{
	//NSLog(@"%s",__func__);
	NSInteger		selRow = [self.presetOutlineView selectedRow];
	id				selObj = (selRow<0) ? nil : [self.presetOutlineView itemAtRow:selRow];
	if (selObj != nil && ![selObj isKindOfClass:[PresetObject class]])
		selObj = nil;
	PresetObject	*selPreset = (PresetObject *)selObj;
	
	if (selPreset == nil)	{
		[self.overviewContainerView removeFromSuperview];
	}
	else	{
		self.overviewContainerView.frame = self.presetInfoContainerBox.bounds;
		[self.presetInfoContainerBox setContentView:self.overviewContainerView];
		
		self.settingsUIController.selectedPreset = selPreset;
	}
	
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	
	if (item!=nil && [item isKindOfClass:[PresetGroup class]])	{
		PresetGroup		*tmpGroup = (PresetGroup *)item;
		if (tmpGroup.title != nil)
			self.expandStateDict[tmpGroup.title] = @YES;
	}
	
	return YES;
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	
	if (item!=nil && [item isKindOfClass:[PresetGroup class]])	{
		PresetGroup		*tmpGroup = (PresetGroup *)item;
		if (tmpGroup.title != nil)
			[self.expandStateDict removeObjectForKey:tmpGroup.title];
	}
	
	return YES;
}


#pragma mark - Outline View Data Source


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	// if item is nil, its our "root" item
	// we have 2 sources, built in and custom presets
	if(item == nil)
	{
		return 2;
	}
	else if([item isKindOfClass:[PresetGroup class]])
	{
		PresetGroup* itemGroup = (PresetGroup*)item;
		return itemGroup.children.count;
	}
	else if ([item isKindOfClass:[PresetObject class]])
	{
		// audio, video, analysis
		return 0; //3
	}
  
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	// root item
	if(item == nil)
	{
		if (index == 0)
		{
			return [PresetGroup standardPresets];
		}
		if(index == 1)
		{
			return [PresetGroup customPresets];
		}
	}
	
	else if([item isKindOfClass:[PresetGroup class]])
	{
		PresetGroup* itemGroup = (PresetGroup*)item;
		return itemGroup.children[index];
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if(item == nil || [item isKindOfClass:[PresetGroup class]] )//|| [item isKindOfClass:[PresetObject class]])
		return YES;
	
	return NO;
}

#pragma mark - Notification

- (void) cellDidEditText:(NSNotification*)notification
{
	//NSLog(@"Update Selected Preset Title");
	NSTextField* updatedTextField = (NSTextField*)notification.object;
	self.settingsUIController.selectedPreset.title = updatedTextField.stringValue;

	self.settingsUIController.presetChanged = YES;
}


#pragma mark - control


- (void) reloadData	{
	//	reload the data
	[self.presetOutlineView reloadData];
	
	//	restore the expand state of everything in the outline view
	[self restoreExpandStates];
}
- (void) restoreExpandStates	{
	NSInteger		tmpRow = 0;
	while (1)	{
		id				tmpObj = [self.presetOutlineView itemAtRow:tmpRow];
		if (tmpObj == nil)
			break;
		if ([tmpObj isKindOfClass:[PresetGroup class]])	{
			PresetGroup		*tmpGroup = (PresetGroup *)tmpObj;
			if (tmpGroup.title != nil)	{
				NSNumber		*tmpNum = self.expandStateDict[tmpGroup.title];
				if (tmpNum != nil && [tmpNum boolValue])	{
					[self.presetOutlineView expandItem:tmpObj expandChildren:NO];
				}
			}
		}
		++tmpRow;
	}
}


#pragma mark - Presets


- (NSArray*) allPresets
{
	return [[[PresetGroup standardPresets].children arrayByAddingObjectsFromArray:[PresetGroup customPresets].children] copy];
}
/*
- (IBAction)addPresetGroup:(id)sender
{
	PresetGroup* new = [[PresetGroup alloc] initWithTitle:@"New Group" editable:YES];
	
	//NSArray* newChildren = [[self.selectedPresetGroup children] arrayByAddingObject:new];
	
	//self.selectedPresetGroup.children = newChildren;
	if (new != nil)
		[self.selectedPresetGroup.children addObject:new];
	
	[self reloadData];
}
*/
- (IBAction) addPresetClicked:(id)sender
{
	NSInteger		selRow = [self.presetOutlineView selectedRow];
	id				selObj = (selRow<0) ? nil : [self.presetOutlineView itemAtRow:selRow];
	if (selObj != nil && ![selObj isKindOfClass:[PresetObject class]])
		selObj = nil;
	PresetObject	*selPreset = (PresetObject *)selObj;
	
	id				selParent = (selPreset==nil) ? nil : [self.presetOutlineView parentForItem:selPreset];
	if (selParent!=nil && ![selParent isKindOfClass:[PresetGroup class]])
		selParent = nil;
	PresetGroup		*selGroup = (PresetGroup *)selParent;
	if (selGroup==nil || ![selGroup editable])
		selGroup = [PresetGroup customPresets];
	if (selGroup == nil)
		return;
	
	//	set this so we don't get hit with a modal "preset has been modified" warning
	self.settingsUIController.presetChanged = NO;
	
	//	make the actual preset
	PresetObject* new = [[PresetObject alloc]
		initWithTitle:@"Unititled"
		audioSettings:[PresetAudioSettings none]
		videoSettings:[PresetVideoSettings none]
		analyzerSettings:[PresetAnalysisSettings none]
		useAudio:YES
		useVideo:YES
		useAnalysis:YES
		exportOption:SynopsisMetadataEncoderExportOptionNone
		editable:YES];
	
	//	add the preset to the group, make sure that the group will be expanded when we reload the outline view
	if (new != nil)	{
		[selGroup.children addObject:new];
		self.expandStateDict[ selGroup.title ] = @YES;
	}
	
	//	reload the outline view
	[self reloadData];
	
	//	select the preset we just created so the user can edit its UI
	NSInteger			rowToSelect = [self.presetOutlineView rowForItem:new];
	if (rowToSelect >= 0)	{
		[self.presetOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
		//	make sure the selected row is visible
		[self.presetOutlineView scrollRowToVisible:rowToSelect];
	}
}
- (IBAction) removePresetClicked:(id)sender	{
	NSInteger		selRow = [self.presetOutlineView selectedRow];
	if (selRow < 0)
		return;
	id				selObj = [self.presetOutlineView itemAtRow:selRow];
	if (selObj == nil || ![selObj isKindOfClass:[PresetObject class]])
		return;
	PresetObject	*selPreset = (PresetObject *)selObj;
	if (![selPreset editable])
		return;
	
	id				selParent = [self.presetOutlineView parentForItem:selPreset];
	if (selParent==nil || ![selParent isKindOfClass:[PresetGroup class]])
		return;
	PresetGroup		*selGroup = (PresetGroup *)selParent;
	if (![selGroup editable])
		return;
	
	//	set this so we don't get hit with a modal "preset has been modified" warning
	self.settingsUIController.presetChanged = NO;
	
	//	remove the object from the group
	[selGroup.children removeObjectIdenticalTo:selPreset];
	
	//	reload the outline view
	[self reloadData];
	
	//	deselect everything
	[self.presetOutlineView deselectAll:nil];
	[self outlineViewSelectionDidChange:nil];
	
	//	move the actual preset file to the trash
	NSArray<NSURL*>		*appSupportURLS = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	NSURL				*presetDirURL = [appSupportURLS[0] URLByAppendingPathComponent:@"Synopsis Analyzer" isDirectory:YES];
	presetDirURL = [presetDirURL URLByAppendingPathComponent:@"Presets"];
	
	NSURL				*presetURL = [presetDirURL URLByAppendingPathComponent:selPreset.uuid.UUIDString];
	presetURL = [presetURL URLByAppendingPathExtension:@"SynopsisPreset"];
	
	NSFileManager		*fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:[presetURL path] isDirectory:nil])	{
		[fm trashItemAtURL:presetURL resultingItemURL:nil error:nil];
	}
}


- (IBAction) savePreset:(id)sender
{
	[self.settingsUIController savePreset];
	
	/*
	PreferencesViewController* parent = (PreferencesViewController*) self.parentViewController;
	[parent buildPresetMenu];
	*/
	PrefsController			*pc = [PrefsController global];
	[pc.prefsViewController.preferencesGeneralViewController populateDefaultPresetPopupButton];
	
	//	post a notification so other UI items that list presets know to update their lists
	[[NSNotificationCenter defaultCenter]
		postNotificationName:kSynopsisPresetsChangedNotification
		object:nil
		userInfo:nil];
}




@end
