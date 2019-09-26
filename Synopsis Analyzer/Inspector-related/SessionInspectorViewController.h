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
	IBOutlet NSButton				*copyNonMediaToggle;
	IBOutlet PathAbstraction		*watchFolderPathAbs;
	IBOutlet PathAbstraction		*scriptPathAbs;
}

- (void) inspectSession:(SynSession *)n;

- (IBAction) presetsPUBUsed:(id)sender;
- (IBAction) copyNonMediaToggleUsed:(id)sender;

@end




NS_ASSUME_NONNULL_END
