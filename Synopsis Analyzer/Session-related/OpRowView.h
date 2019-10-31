//
//  OpRowView.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSProgressIndicatorAnimated.h"

@class SynOp;




@interface OpRowView : NSTableCellView	{
	IBOutlet NSImageView	*preview;
	IBOutlet NSTextField	*nameField;
	
	IBOutlet NSTextField	*statusField;
	
	IBOutlet NSProgressIndicatorAnimated		*progressIndicator;
	
	IBOutlet NSTextField	*pathField;
	IBOutlet NSButton		*showFileButton;
	//IBOutlet NSTextField	*timeRemainingField;
}

- (void) refreshWithOp:(SynOp *)n;
- (void) refreshUI;

- (IBAction) showFileClicked:(id)sender;

@property (atomic,weak) SynOp * op;

@end


