//
//	PrefsController.m
//	Synopsis Analyzer
//
//	Created by testAdmin on 9/17/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import "PrefsController.h"
#import "PreferencesViewController.h"

#import "NSPopUpButtonAdditions.h"
#import "NSMenuAdditions.h"




PrefsController			*globalPrefsController = nil;




@interface PrefsController ()
- (void) generalInit;
- (void) recursivelyPopulateMenu:(NSMenu *)inMenu withVals:(NSArray *)inVals forNSPUB:(NSPopUpButton *)inPUB;
- (PresetObject *) recursiveCheckArray:(NSArray *)inArray forPresetWithUUID:(NSUUID *)inUUID;
@end




@implementation PrefsController


+ (PrefsController *) global	{
	if (globalPrefsController == nil)	{
		PrefsController		*asdf = [[PrefsController alloc] init];
		asdf = nil;
	}
	return globalPrefsController;
}


- (id) init	{
	self = [super initWithWindowNibName:[NSString stringWithFormat:@"%@",[[self class] className]]];
	if (self != nil)	{
		static dispatch_once_t		onceToken;
		dispatch_once(&onceToken, ^{
			globalPrefsController = self;
		});
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	[self window];
}
- (void) dealloc	{
	NSLog(@"%s",__func__);
}
- (void)windowDidLoad {
	//NSLog(@"%s",__func__);
	[super windowDidLoad];
	
	// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	[self.prefsViewController view];
}

- (void) populatePopUpButtonWithPresets:(NSPopUpButton *)inPUB	{
	//NSLog(@"%s",__func__);
	if (inPUB == nil)
		return;
	PrefsController		*pc = [PrefsController global];
	NSArray				*allPresets = [pc allPresets];
	//NSLog(@"\t\tallPresets are %@",allPresets);
	//NSLog(@"\t\tpassthru are %@",[(PresetGroup*)[allPresets objectAtIndex:0] children]);
	[inPUB.menu removeAllItems];
	
	[self recursivelyPopulateMenu:[inPUB menu] withVals:allPresets forNSPUB:inPUB];
	//NSLog(@"\t\tdone, itemArray is %@",[[inPUB menu] itemArray]);
}
- (NSUUID *) defaultPresetUUID	{
	NSString		*defaultPresetUUIDString = [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerDefaultPresetPreferencesKey];
	NSUUID			*defaultPresetUUID = [[NSUUID alloc] initWithUUIDString:defaultPresetUUIDString];
	return defaultPresetUUID;
}
- (PresetObject *) presetForUUID:(NSUUID *)n	{
	return [self recursiveCheckArray:[self allPresets] forPresetWithUUID:n];
}
- (PresetObject *) defaultPreset	{
	//	get the default preset's NSUUID
	NSUUID			*defaultPresetUUID = [self defaultPresetUUID];
	//	run through the presets, find the preset with that NSUUID
	PresetObject	*returnMe = [self presetForUUID:defaultPresetUUID];
	//	if we couldn't find the default preset, default to the passthru preset
	if (returnMe == nil)
		returnMe = [self recursiveCheckArray:[self allPresets] forPresetWithUUID:[[NSUUID alloc] initWithUUIDString:@"DDCEA125-B93D-464B-B369-FB78A5E890B4"]];
	//	return it!
	return returnMe;
}
- (NSArray *) allPresets	{
	return [self.prefsViewController.preferencesPresetViewController allPresets];
}
- (BOOL) outputFolderEnabled	{
	return [self.prefsViewController.preferencesFileViewController outputFolderEnabled];
}
- (NSString *) outputFolder	{
	return [self.prefsViewController.preferencesFileViewController outputFolder];
}
/*
- (BOOL) watchFolderEnabled	{
	return [self.prefsViewController.preferencesFileViewController watchFolderEnabled];
}
- (NSURL*) watchFolderURL	{
	return [self.prefsViewController.preferencesFileViewController watchFolderURL];
}
*/
- (BOOL) tempFolderEnabled	{
	return [self.prefsViewController.preferencesFileViewController tempFolderEnabled];
}
- (NSString *) tempFolder	{
	return [self.prefsViewController.preferencesFileViewController tempFolder];
}
- (BOOL) opScriptEnabled	{
	return [self.prefsViewController.preferencesGeneralViewController opScriptEnabled];
}
- (NSString *) opScript	{
	return [self.prefsViewController.preferencesGeneralViewController opScript];
}
- (BOOL) sessionScriptEnabled	{
	return [self.prefsViewController.preferencesGeneralViewController sessionScriptEnabled];
}
- (NSString *) sessionScript	{
	return [self.prefsViewController.preferencesGeneralViewController sessionScript];
}


- (void) recursivelyPopulateMenu:(NSMenu *)inMenu withVals:(NSArray *)inVals forNSPUB:(NSPopUpButton *)inPUB	{
	//NSLog(@"%s",__func__);
	
	[inMenu removeAllItems];
	inMenu.autoenablesItems = NO;
	
	
	//	pull-down NSPUBs "eat" their first item (unavailable for display if you select something 
	//	else & its submenu is always unavailable), so we attempt to work around that by making a 
	//	dummy first item.  try commenting this out and observe the pull-down's behavior.
	if (inPUB.pullsDown && inMenu.supermenu==nil)
		[inMenu addItem:[[NSMenuItem alloc] initWithTitle:@"dummy_item" action:nil keyEquivalent:@""]];
	
	
	for (id inValsObj in inVals)	{
		if ([inValsObj isKindOfClass:[PresetGroup class]])	{
			PresetGroup		*recast = (PresetGroup *)inValsObj;
			
			NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:recast.title action:nil keyEquivalent:@""];
			newItem.representedObject = recast;
			
			[inMenu addItem:newItem];
			
			NSMenu			*newMenu = [[NSMenu alloc] initWithTitle:recast.title];
			newItem.submenu = newMenu;
			
			[self recursivelyPopulateMenu:newItem.submenu withVals:recast.children forNSPUB:inPUB];
		}
		else if ([inValsObj isKindOfClass:[PresetObject class]])	{
			PresetObject	*recast = (PresetObject *)inValsObj;
			
			NSMenuItem		*newItem = [[NSMenuItem alloc] initWithTitle:recast.title action:nil keyEquivalent:@""];
			newItem.representedObject = recast;
			
			//	make the menu item call a method on its parent PUB (which in turn will utilize the parent's target/action)
			newItem.target = inPUB;
			newItem.action = @selector(sanityHack_menuItemChosen:);
			
			[inMenu addItem:newItem];
		}
	}
	
	
	/*
	//[inMenu removeAllItems];
	[inMenu setAutoenablesItems:NO];
	
	for (id preset in inVals)	{
		
		if ([preset isKindOfClass:[PresetGroup class]])	{
			PresetGroup		*tmpGroup = (PresetGroup *)preset;
			
			NSMenuItem		*item = [[NSMenuItem alloc] initWithTitle:tmpGroup.title action:nil keyEquivalent:@""];
			//item.representedObject = tmpGroup;
			
			NSMenu			*submenu = [[NSMenu alloc] initWithTitle:tmpGroup.title];
			[submenu removeAllItems];
			//[self recursivelyPopulateMenu:submenu forPUB:inPUB withPresetObjects:tmpGroup.children];
			[self recursivelyPopulateMenu:submenu withVals:tmpGroup.children forNSPUB:inPUB];
			item.submenu = submenu;
			
			[inMenu addItem:item];
		}
		
		if ([preset isKindOfClass:[PresetObject class]])	{
			PresetObject	*tmpObject = (PresetObject *)preset;
			
			NSMenuItem		*item = [[NSMenuItem alloc] initWithTitle:tmpObject.title action:inPUB.action keyEquivalent:@""];
			item.representedObject = preset;
			item.target = inPUB.target;
			
			[inMenu addItem:item];
		}
		
	}
	*/
}

- (PresetObject *) recursiveCheckArray:(NSArray *)inArray forPresetWithUUID:(NSUUID *)inUUID	{
	if (inArray == nil || inUUID == nil)
		return nil;
	
	PresetObject		*returnMe = nil;
	
	for (id presetObject in inArray)	{
		if ([presetObject isKindOfClass:[PresetObject class]])	{
			PresetObject		*recast = (PresetObject *)presetObject;
			if ([recast.uuid isEqual:inUUID])
				return recast;
		}
		if ([presetObject isKindOfClass:[PresetGroup class]])	{
			PresetGroup			*recast = (PresetGroup *)presetObject;
			returnMe = [self recursiveCheckArray:recast.children forPresetWithUUID:inUUID];
			if (returnMe != nil)
				return returnMe;
		}
	}
	
	return returnMe;
}



@end
