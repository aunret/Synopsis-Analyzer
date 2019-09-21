//
//  OpRowView.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynOp;




@interface OpRowView : NSTableCellView	{
	IBOutlet NSButton		*enableToggle;
	IBOutlet NSImageView	*preview;
	IBOutlet NSTextField	*nameField;
	IBOutlet NSTextField	*statusField;
}

- (void) refreshWithOp:(SynOp *)n;
- (void) refreshUI;

- (IBAction) enableToggleUsed:(id)sender;

@property (atomic,weak) SynOp * op;

@end


