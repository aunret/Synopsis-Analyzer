//
//  PrefsPathPickerAbstraction.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/30/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN




/*
		several places in the prefs & app have a UI that requires the user to select a target folder.  this
	is an abstraction that manages a number of UI items that work cohesively to provide the user with a
	simplified workflow for specifying that target folder.
 
		features:
	- populates a pop-up button with menu items for choosing between "no special location",
	"custom location" (triggers an NSOpenPanel), or a list of recently-chosen locations
	- populates "statusButton" with a colored icon indicating the state of the UI item (grey for "no
	special location", red for a location that cannot be found, or green for a custom specified location)
	- populates "statusTextField" with the custom specified location (or a note indicating that no special location has been chosen)
	- responds to a "reveal button" that shows the selected location in the finder (or does nothing if no location is chosen)
	- lets the dev provide a block for opening a custom NSOpenPanel for selecting the location
	- lets the dev provide a block for responding to the user changing the specified location
 
		how to use it:
	- make an instance of this class in IB
	- wire up the outlets of this class to the corresponding UI items
	- connect the reveal button's action to - (IBAction) revealButtonUsed:(id)sender;
	- in your app's "awakeFromNib" method:
		- call -[PrefsPathPickerAbstraction setUserDefaultsKey:XXX] with the relelvant key value.  this key
		determines where your value will be stored in the NSUserDefaults.
		- set the "openPanelBlock" property- this block should open a customized NSOpenPanel that allows
		the user to select a target folder.  within the NSOpenPanel's completion block, be sure to
		call -[PrefsPathPickerPUB setPath:] (this passes the selected path back to the abstraction)
		- set the "pathChangeBlock" property- this block is called every time the instance's path is changed
	- you're basically done: if -[PrefsPathPickerAbstraction enabled] returns YES, you need to store the file
	somewhere other than adjacent to the source file, and you can call -[PrefsPathPickerAbstraction path] to
	get the specified location.
*/




@interface PrefsPathPickerAbstraction : NSObject	{
	IBOutlet NSPopUpButton		*pickerPUB;
	IBOutlet NSButton			*statusButton;
	IBOutlet NSTextField		*statusTextField;
}

- (IBAction) revealButtonUsed:(id)sender;

//	you must specify a user defaults key (even if you're using PathPickerAbstraction, as it needs to load the recently used paths from the defaults)
- (void) setUserDefaultsKey:(nonnull NSString *)n;

//	this string will be displayed in the menu (and status text field) if no path is selected ("same as source location", or "no script selected")
- (void) setDisabledLabelString:(NSString *)n;
//	this string will be displayed in the menu as the option for selecting a custom path ("custom output folder", or "select a script")
- (void) setCustomPathLabelString:(NSString *)n;
//	this string will be displayed in the menu as the option for selecting a recently-used path ("recent output folders", or "recent scripts")
- (void) setRecentPathLabelString:(NSString *)n;

//	provide a block that opens a customized NSOpenPanel for picking the destination folder
@property (copy,nonnull) void (^openPanelBlock)(PrefsPathPickerAbstraction *);
//	provide a block that will respond to this instance's path and/or enabled state changing
@property (copy,nonnull) void (^pathChangeBlock)(PrefsPathPickerAbstraction *);

//	only call this method from inside the 'openPanelBlock' (after the open panel has selected a path to use)
- (void) setPath:(NSString *)p;

//	causes the UI to be refreshed (call after populating initial values)
- (void) updateUI;

//	returns the path selected
- (nullable NSString *) path;
- (nullable NSURL *) url;
//	returns YES if user has selected a non-default path
- (BOOL) enabled;

@end




/*
	this subclass of PrefsPathPickerAbstraction differs in only way: it doesn't save its
*/




@interface PathPickerAbstraction : PrefsPathPickerAbstraction
//	sets the initial enabled state (setPath: is used to set the initial path value for this subclass)
- (void) setEnabled:(BOOL)n;
//	this string will be displayed in the menu as the option for selecting the default value stored in the prefs ("preferences output folder", or "preferences script")
- (void) setPrefsValueLabelString:(NSString *)n;
@end




NS_ASSUME_NONNULL_END
