//
//  PrefsPathPickerAbstraction.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/30/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PrefsPathPickerAbstraction.h"




NSString * const kPrefsPathPickerReloadNotificationName = @"kPrefsPathPickerReloadNotificationName";




@interface PrefsPathPickerAbstraction ()

//	this property stores the key at which the path is saved in NSUserDefaults
@property (atomic,strong,nullable) NSString * internalUserDefaultsKey;
//	these properties store the user-provided strings used to populate the text of the various menu items
@property (atomic,strong,nullable) NSString * internalDisabledLabel;
@property (atomic,strong,nullable) NSString * internalCustomPathLabel;
@property (atomic,strong,nullable) NSString * internalRecentPathLabel;
@property (atomic,strong,nullable) NSString * internalPrefsValLabel;
//	if YES, this instance will save its current value in the user defaults (YES by default in this class, NO by default in a subclass)
//	if NO, vals will instead be stored in "nonDefaultsEnabled" and "nonDefaultsPath"
@property (atomic,readwrite) BOOL saveToUserDefaults;

@property (atomic,readwrite) BOOL nonDefaultsEnabled;
@property (atomic,strong,readwrite) NSString *nonDefaultsPath;

- (IBAction) sameAsSourceItemUsed:(id)sender;
- (IBAction) defaultFolderItemUsed:(id)sender;
- (IBAction) customFolderItemUsed:(id)sender;
- (IBAction) recentFolderItemUsed:(id)sender;

- (void) _updateUI;
- (void) _updateStatusUI;
- (void) _updatePickerPUBContents;
- (void) _updatePickerPUBUI;
- (NSString *) _deriveEnableKey;
- (NSString *) _deriveRecentFoldersKey;

@end




@implementation PrefsPathPickerAbstraction


- (id) init	{
	self = [super init];
	if (self != nil)	{
		self.saveToUserDefaults = YES;
		//	register to receive notifications that we need to reload our UI
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(reloadUINotification:)
			name:kPrefsPathPickerReloadNotificationName
			object:nil];
	}
	return self;
}
- (void) dealloc	{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kPrefsPathPickerReloadNotificationName object:nil];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	[self _updateUI];
}


- (void) reloadUINotification:(NSNotification *)note	{
	NSDictionary		*userInfo = [note userInfo];
	if (userInfo == nil)
		return;
	NSString			*tmpKey = userInfo[@"internalUserDefaultsKey"];
	if (tmpKey != nil && self.internalUserDefaultsKey != nil && [tmpKey isEqualToString:self.internalUserDefaultsKey])
		[self _updateUI];
}


- (IBAction) revealButtonUsed:(id)sender	{
	if (![self enabled])
		return;
	NSURL			*tmpURL = [self url];
	if (tmpURL == nil)
		return;
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ tmpURL ]];
}


- (IBAction) sameAsSourceItemUsed:(id)sender	{
	//	set enable to NO, leave value alone
	if (self.saveToUserDefaults)	{
		NSString			*enableKey = [self _deriveEnableKey];
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		if (enableKey != nil)	{
			[def setBool:NO forKey:enableKey];
			[def synchronize];
		}
	}
	else	{
		self.nonDefaultsEnabled = NO;
	}
	
	//	update UI
	[self _updateUI];
	
	//	execute the path changed block
	if (self.pathChangeBlock != nil)
		self.pathChangeBlock(self);
}
- (IBAction) defaultFolderItemUsed:(id)sender	{
	//	if we're saving to the user defaults then we shouldn't be here, because the menu item that calls this shouldn't have been added...
	if (self.saveToUserDefaults)
		return;
	
	
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	if (self.internalUserDefaultsKey != nil)	{
		NSString			*tmpString = [def objectForKey:self.internalUserDefaultsKey];
		if (tmpString != nil)	{
			self.nonDefaultsEnabled = YES;
			self.nonDefaultsPath = tmpString;
		}
	}
	
	//	update UI
	[self _updateUI];
	
	//	execute the path changed block
	if (self.pathChangeBlock != nil)
		self.pathChangeBlock(self);
}
- (IBAction) customFolderItemUsed:(id)sender	{
	//	open picker for selecting a new directory
	if (self.openPanelBlock != nil)
		self.openPanelBlock(self);
}
- (IBAction) recentFolderItemUsed:(id)sender	{
	if (sender==nil || ![sender isKindOfClass:[NSMenuItem class]])
		return;
	NSMenuItem			*senderItem = (NSMenuItem *)sender;
	
	//	set enable to YES, set path to passed val
	if (self.saveToUserDefaults)	{
		NSString			*enableKey = [self _deriveEnableKey];
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		if (enableKey != nil)	{
			[def setBool:YES forKey:enableKey];
		}
		if (senderItem.representedObject != nil && [senderItem.representedObject isKindOfClass:[NSString class]] && self.internalUserDefaultsKey)
			[def setObject:senderItem.representedObject forKey:self.internalUserDefaultsKey];
	
		[def synchronize];
	}
	else	{
		self.nonDefaultsEnabled = YES;
		if (senderItem.representedObject != nil && [senderItem.representedObject isKindOfClass:[NSString class]])
			self.nonDefaultsPath = senderItem.representedObject;
	}
	
	//	update UI
	[self _updateUI];
	
	//	execute the path changed block
	if (self.pathChangeBlock != nil)
		self.pathChangeBlock(self);
}


- (void) setUserDefaultsKey:(nonnull NSString *)n	{
	self.internalUserDefaultsKey = n;
}
- (void) setDisabledLabelString:(NSString *)n	{
	self.internalDisabledLabel = n;
}
- (void) setCustomPathLabelString:(NSString *)n	{
	self.internalCustomPathLabel = n;
}
- (void) setRecentPathLabelString:(NSString *)n	{
	self.internalRecentPathLabel = n;
}


- (void) setPath:(NSString *)p	{
	if (p == nil)
		return;
	
	//	we need the user defaults regardless (we want to add to the recent paths array)
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	
	//	set enable key YES, set val for user defaults key
	if (self.saveToUserDefaults)	{
		NSString			*enableKey = [self _deriveEnableKey];
		if (enableKey != nil)	{
			[def setBool:YES forKey:enableKey];
		}
		if (self.internalUserDefaultsKey != nil)
			[def setObject:p forKey:self.internalUserDefaultsKey];
	}
	else	{
		//self.nonDefaultsEnabled = YES;
		self.nonDefaultsPath = p;
	}
	
	//	add the path we were just passed to the top of the array of recent paths
	NSString			*recentKey = [self _deriveRecentFoldersKey];
	if (recentKey != nil)	{
		NSArray				*origArray = [def objectForKey:recentKey];
		NSMutableArray		*mutArray = (origArray==nil) ? [[NSMutableArray alloc] init] : [origArray mutableCopy];
		[mutArray removeObject:p];
		[mutArray insertObject:p atIndex:0];
		while (mutArray.count > 10)
			[mutArray removeObjectAtIndex:10];
		if (recentKey != nil)
			[def setObject:[NSArray arrayWithArray:mutArray] forKey:recentKey];
	}
	
	[def synchronize];
	
	//	update UI (post a notification if we can so other instances using the same user defaults key will also reload)
	if (self.internalUserDefaultsKey == nil)
		[self _updateUI];
	else	{
		[[NSNotificationCenter defaultCenter]
			postNotificationName:kPrefsPathPickerReloadNotificationName
			object:nil
			userInfo:@{ @"internalUserDefaultsKey": self.internalUserDefaultsKey }];
	}
	
	//	execute the path changed block
	if (self.pathChangeBlock != nil)	{
		dispatch_async(dispatch_get_main_queue(), ^{
			self.pathChangeBlock(self);
		});
	}
}


- (nullable NSString *) path	{
	if (self.saveToUserDefaults)	{
		NSString			*valKey = self.internalUserDefaultsKey;
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		NSString			*tmpString = (valKey==nil) ? nil : [def stringForKey:valKey];
		return tmpString;
	}
	else	{
		return self.nonDefaultsPath;
	}
}
- (nullable NSURL *) url	{
	NSString			*tmpString = [self path];
	return (tmpString==nil) ? nil : [NSURL fileURLWithPath:tmpString];
}
- (BOOL) enabled	{
	if (self.saveToUserDefaults)	{
		NSString			*enableKey = [self _deriveEnableKey];
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		BOOL				tmpBool = (enableKey==nil) ? NO : [def boolForKey:enableKey];
		return tmpBool;
	}
	else	{
		return self.nonDefaultsEnabled;
	}
}


- (void) updateUI	{
	[self _updateUI];
}
- (void) _updateUI	{
	//NSLog(@"%s",__func__);
	[self _updateStatusUI];
	[self _updatePickerPUBContents];
	[self _updatePickerPUBUI];
}
- (void) _updateStatusUI	{
	BOOL			isEnabled = [self enabled];
	NSString		*currentPath = [self path];
	[statusTextField setStringValue:(currentPath==nil) ? @"" : currentPath];
	//	if the enable toggle is disabled, the status button is disabled
	if (!isEnabled)	{
		NSString		*tmpString = (self.internalDisabledLabel==nil)
			? @"(disabled)"
			: [NSString stringWithFormat:@"(%@)",self.internalDisabledLabel];
		[statusTextField setStringValue:tmpString];
		
		[statusButton setImage:[NSImage imageNamed:NSImageNameStatusNone]];
	}
	//	else the enable toggle is enabled...
	else	{
		[statusTextField setStringValue:(currentPath==nil) ? @"" : currentPath];
		
		NSFileManager			*fm = [NSFileManager defaultManager];
		//	if there's a path AND the path is a valid file/folder, the enable toggle is enabled
		if (currentPath!=nil && [fm fileExistsAtPath:currentPath])	{
			[statusButton setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
		}
		//	else the enable toggle is disabled
		else	{
			[statusButton setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
		}
	}
}
- (void) _updatePickerPUBContents	{
	//NSLog(@"%s",__func__);
	NSUserDefaults	*def = [NSUserDefaults standardUserDefaults];
	
	//	populate the top-level menu
	NSMenu			*menu = [[NSMenu alloc] init];
	menu.autoenablesItems = NO;
	NSMenuItem		*item = nil;
	
	item = [[NSMenuItem alloc]
		initWithTitle:(self.internalDisabledLabel==nil) ? @"(disabled)" : self.internalDisabledLabel
		action:@selector(sameAsSourceItemUsed:)
		keyEquivalent:@""];
	item.target = self;
	[menu addItem:item];
	
	item = [NSMenuItem separatorItem];
	[menu addItem:item];
	
	//	only add this item in the subclass which isn't setting the val for the prefs!
	if (!self.saveToUserDefaults)	{
		item = [[NSMenuItem alloc]
			initWithTitle:(self.internalPrefsValLabel==nil) ? @"Path from prefs" : self.internalPrefsValLabel
			action:@selector(defaultFolderItemUsed:)
			keyEquivalent:@""];
		item.target = self;
		[menu addItem:item];
	}
	
	item = [[NSMenuItem alloc]
		initWithTitle:(self.internalCustomPathLabel==nil) ? @"Custom path" : self.internalCustomPathLabel
		action:@selector(customFolderItemUsed:)
		keyEquivalent:@""];
	item.target = self;
	[menu addItem:item];
	
	//item = [NSMenuItem separatorItem];
	//[menu addItem:item];
	
	//item = [[NSMenuItem alloc]
	//	initWithTitle:(self.internalRecentPathLabel==nil) ? @"Recent paths" : self.internalRecentPathLabel
	//	action:nil
	//	keyEquivalent:@""];
	//[menu addItem:item];
	
	//	populate the submenu
	//NSMenu			*submenu = [[NSMenu alloc] init];
	//submenu.autoenablesItems = NO;
	//item.submenu = submenu;
	
	NSString		*recentFoldersKey = [self _deriveRecentFoldersKey];
	NSArray			*recentFoldersArray = (recentFoldersKey==nil) ? nil : [def objectForKey:recentFoldersKey];
	if (recentFoldersArray!=nil && [recentFoldersArray isKindOfClass:[NSArray class]] && recentFoldersArray.count > 0)	{
		//	add a separator
		item = [NSMenuItem separatorItem];
		[menu addItem:item];
		//	add a disabled "Recent Paths" menu item
		item = [[NSMenuItem alloc]
			initWithTitle:@"Recent Paths:"
			action:nil
			keyEquivalent:@""];
		[item setEnabled:NO];
		[menu addItem:item];
		
		for (NSString *recentFolder in recentFoldersArray)	{
			if (![recentFolder isKindOfClass:[NSString class]])
				continue;
			NSString		*tmpTitle = [NSString stringWithFormat:@"%@ (%@)", recentFolder.lastPathComponent, [recentFolder stringByAbbreviatingWithTildeInPath]];
			NSMenuItem		*subitem = [[NSMenuItem alloc] initWithTitle:tmpTitle action:@selector(recentFolderItemUsed:) keyEquivalent:@""];
			subitem.target = self;
			subitem.representedObject = recentFolder;
			subitem.toolTip = recentFolder;
			//[submenu addItem:subitem];
			[menu addItem:subitem];
		}
	}
	//	if there are no items in the menu, add a fallback item
	//if (submenu.itemArray.count < 1)	{
	//	NSMenuItem		*subitem = [[NSMenuItem alloc] initWithTitle:@"No recent items yet!" action:nil keyEquivalent:@""];
	//	subitem.enabled = NO;
	//	[submenu addItem:subitem];
	//}
	
	//	apply the menu to the PUB
	[pickerPUB setMenu:menu];
}
- (void) _updatePickerPUBUI	{
	//NSLog(@"%s",__func__);
	BOOL			enabled = [self enabled];
	//NSString		*currentPath = [self path];
	if (!enabled)
		[pickerPUB selectItemAtIndex:0];
	else	{
		//[pickerPUB selectItemAtIndex:2];
		if (self.saveToUserDefaults)	{
			[pickerPUB selectItemAtIndex:2];
		}
		else	{
			[pickerPUB selectItemAtIndex:3];
		}
	}
}
- (NSString *) _deriveEnableKey	{
	NSString		*returnMe = self.internalUserDefaultsKey;
	if (returnMe == nil)
		return returnMe;
	return [returnMe stringByAppendingString:@"_enableKey"];
}
- (NSString *) _deriveRecentFoldersKey	{
	NSString		*returnMe = self.internalUserDefaultsKey;
	if (returnMe == nil)
		return returnMe;
	return [returnMe stringByAppendingString:@"_recentFoldersKey"];
}


@end








@implementation PathPickerAbstraction

- (id) init	{
	self = [super init];
	if (self != nil)	{
		self.saveToUserDefaults = NO;
	}
	return self;
}

- (void) setEnabled:(BOOL)n	{
	self.nonDefaultsEnabled = n;
	//[self _updateUI];
}

- (void) setPrefsValueLabelString:(NSString *)n	{
	self.internalPrefsValLabel = n;
}

@end

