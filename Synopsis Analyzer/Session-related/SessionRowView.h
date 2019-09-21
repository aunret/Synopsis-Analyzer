//
//  SessionRowView.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynSession;




@interface SessionRowView : NSTableCellView	{
	IBOutlet NSButton		*enableToggle;
	IBOutlet NSTextField	*nameField;
	IBOutlet NSPopUpButton	*presetPUB;
	IBOutlet NSTextField	*descriptionField;
}

- (void) refreshWithSession:(SynSession *)n;
- (void) refreshUI;

- (IBAction) enableToggleUsed:(id)sender;
- (IBAction) presetPUBUsed:(id)sender;
- (IBAction) nameFieldUsed:(id)sender;

@property (atomic,weak) SynSession * session;

@end


