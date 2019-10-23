//
//  SessionRowView.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynSession;
@class SessionStateButton;




@interface SessionRowView : NSTableCellView	{
	IBOutlet NSImageView	*iconView;
	IBOutlet NSTextField	*nameField;
	//IBOutlet NSPopUpButton	*presetPUB;
	
	IBOutlet NSTextField	*descriptionField;
	
	IBOutlet NSProgressIndicator		*progressIndicator;
	IBOutlet SessionStateButton				*progressButton;
}

- (void) refreshWithSession:(SynSession *)n;
- (void) refreshUI;

//- (IBAction) enableToggleUsed:(id)sender;
//- (IBAction) presetPUBItemSelected:(id)sender;
- (IBAction) progressButtonUsed:(id)sender;
- (IBAction) nameFieldUsed:(id)sender;

@property (atomic,weak) SynSession * session;

@end


