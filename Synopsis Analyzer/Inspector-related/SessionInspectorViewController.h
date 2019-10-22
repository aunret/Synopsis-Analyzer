//
//  SessionInspectorViewController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PathAbstraction.h"

@class SynSession;

NS_ASSUME_NONNULL_BEGIN




@interface SessionInspectorViewController : NSViewController	{
	IBOutlet NSPopUpButton			*presetsPUB;
	IBOutlet NSTextField			*presetDescriptionField;
	
	IBOutlet PathAbstraction		*outputFolderPathAbs;
	IBOutlet PathAbstraction		*tempFolderPathAbs;
	IBOutlet PathAbstraction		*opScriptPathAbs;
	IBOutlet PathAbstraction		*sessionScriptPathAbs;
	
	IBOutlet NSBox					*sessionWatchDirBox;
	IBOutlet NSButton				*copyNonMediaToggle;
}

- (void) inspectSession:(nullable SynSession *)n;

- (IBAction) presetsPUBItemSelected:(id)sender;
- (IBAction) copyNonMediaToggleUsed:(id)sender;

//	should be nil unless inspector is currently active
@property (readwrite,atomic,weak,nullable) SynSession * inspectedObject;

- (void) updateUI;

@end




NS_ASSUME_NONNULL_END
