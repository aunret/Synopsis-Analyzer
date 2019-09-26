//
//  PathAbstraction.h
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
		like 'PrefsPathAbstraction', but doesn't use the prefs to populate initial vals (must be 
		done manually)
*/




@interface PathAbstraction : NSObject	{
	//	wire these up in IB
	IBOutlet NSButton		*enableToggle;	//	the enable toggle
	IBOutlet NSButton		*statusButton;	//	the status indicator button (red/green/disabled)
	IBOutlet NSTextField	*statusTextField;	//	the text field that displays the selected path
}

//	required.  wire these up in IB
- (IBAction) enableToggleUsed:(nullable id)sender;
- (IBAction) selectButtonUsed:(nullable id)sender;
- (IBAction) revealButtonUsed:(nullable id)sender;

@property (atomic,strong,nullable) NSString * path;
@property (atomic) BOOL enabled;

//	required for minimal functionality.  this block is executed when the user clicks the select 
//	button- create, configure, and open an NSOpenPanel to pick the relevant file. 'inParentAbstraction' 
//	is the instance of PathAbstraction that is responding to the 'selectButton' action.
@property (copy,nullable) void (^selectButtonBlock)(PathAbstraction *);

//	optional- this block is executed after you change the state of 'enableToggle'.
@property (copy,nullable) void (^enableToggleBlock)(PathAbstraction *);

@end



NS_ASSUME_NONNULL_END

