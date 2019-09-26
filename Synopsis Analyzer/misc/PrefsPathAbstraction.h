//
//  PrefsPathAbstraction.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/19/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN




/*
		several places in the prefs have a UI that consists of:
	- an enable/disable toggle that indicates whether or not an action should be performed with a filepath
	- a button for opening a file-picker for specifying the filepath
	- a status button (red/green/grey) indicating whether or not a filepath hasbeen specified, exists, and the toggle is enabled
	- a status text field that displays a descriptive phrase (if no path) or the specified path
	- a "reveal" button that shows the filepath in the finder
	
	...this class is an abstraction that handles all the logic around this.  here's how to use it:
		- make an instance of this class in IB.
		- wire up the outlets/actions of this instance in IB.  the UI items can be customized, this class is basically logic-only.
		- in your app's 'awakeFromNib' method:
			- call -[PrefsPathAbstraction setUserDefaultsKey:XXX] with the relevant key value.  this is where your val will be stored in the NSUserDefaults.
			- set the 'selectButtonBlock' property.  this block should create an NSOpenPanel that, within its completion block, calls -[PrefsPathAbstraction setPath:XXX] with the returned path.
			- optional: set the 'enableToggleBlock' property.  this block will be executed every time the user interacts with 'enableToggle'
		- ...that's it, you're done.  once you do these, you can call -[PrefsPathAbstraction path] or -[PrefsPathAbstraction url] to retrieve the value you're looking for.
*/




@interface PrefsPathAbstraction : NSObject	{
	//	wire these up in IB
	IBOutlet NSButton		*enableToggle;	//	the enable toggle
	IBOutlet NSButton		*statusButton;	//	the status indicator button (red/green/disabled)
	IBOutlet NSTextField	*statusTextField;	//	the text field that displays the selected path
}

//	required.  wire these up in IB
- (IBAction) enableToggleUsed:(nullable id)sender;
- (IBAction) selectButtonUsed:(nullable id)sender;
- (IBAction) revealButtonUsed:(nullable id)sender;

//	required.  this string is the key in NSUserDefaults at which the value (the path) is stored.
- (void) setUserDefaultsKey:(nonnull NSString *)n;

//	required for minimal functionality.  this block is executed when the user clicks the select 
//	button- create, configure, and open an NSOpenPanel to pick the relevant file. 'inParentAbstraction' 
//	is the instance of PrefsPathAbstraction that is responding to the 'selectButton' action.
@property (copy,nullable) void (^selectButtonBlock)(PrefsPathAbstraction *);

//	optional- this block is executed after you change the state of 'enableToggle'.
@property (copy,nullable) void (^enableToggleBlock)(void);

//	this is the path which gets stored in the user defaults.
//	calling this method updates the UI, but you should only really call it from within 'selectButtonBlock'...
- (void) setPath:(nonnull NSString *)n;

//	other objects can query these to retrieve the path/URL.  returns nil if not enabled, or if no path has been stored.  returns a non-nil value only if enabled && a value is stored
- (nullable NSString *) path;
- (nullable NSURL *) url;

@end





NS_ASSUME_NONNULL_END
