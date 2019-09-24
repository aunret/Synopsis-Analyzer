//
//  OpRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpRowView.h"

#import "SynOp.h"




@interface OpRowView ()
- (void) generalInit;
@end




@implementation OpRowView


- (instancetype) initWithFrame:(NSRect)n	{
	self = [super initWithFrame:n];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder *)n	{
	self = [super initWithCoder:n];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
}


- (void) refreshWithOp:(SynOp *)n	{
	self.op = n;
	[self refreshUI];
}
- (void) refreshUI	{
	if (self.op == nil)	{
		[enableToggle setIntValue:NSControlStateValueOff];
		[preview setImage:nil];
		[nameField setStringValue:@""];
		[tabView selectTabViewItemAtIndex:0];
		[statusField setStringValue:@"XXX"];
		return;
	}
	
	//[enableToggle setIntValue:NSOnState];
	[preview setImage:self.op.thumb];
	[nameField setStringValue:self.op.src.lastPathComponent.stringByDeletingPathExtension];
	switch (self.op.status)	{
	case OpStatus_Pending:
	case OpStatus_PreflightErr:
	case OpStatus_Complete:
	case OpStatus_Err:
		[tabView selectTabViewItemAtIndex:0];
		[statusField setStringValue:[self.op createStatusString]];
		break;
	case OpStatus_Analyze:
	case OpStatus_Cleanup:
		[tabView selectTabViewItemAtIndex:1];
		[progressIndicator setDoubleValue:(self.op.job==nil) ? 0.0 : [self.op.job jobProgress]];
		break;
	}
}

- (IBAction) enableToggleUsed:(id)sender	{
}


@end
