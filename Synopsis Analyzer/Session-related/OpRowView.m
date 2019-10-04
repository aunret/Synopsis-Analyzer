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
	//NSLog(@"op is %@",self.op);
	//NSLog(@"op src is %@",self.op.src);
	switch (self.op.status)	{
	case OpStatus_Pending:
		[tabView selectTabViewItemAtIndex:0];
		[statusField setStringValue:[self.op createStatusString]];
		statusField.toolTip = nil;
		break;
	case OpStatus_PreflightErr:
		[tabView selectTabViewItemAtIndex:0];
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = self.op.job.jobErrString;
		break;
	case OpStatus_Complete:
		[tabView selectTabViewItemAtIndex:0];
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = nil;
		break;
	case OpStatus_Err:
		[tabView selectTabViewItemAtIndex:0];
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = self.op.job.jobErrString;
		break;
	case OpStatus_Analyze:
	case OpStatus_Cleanup:
		[tabView selectTabViewItemAtIndex:1];
		[progressIndicator setDoubleValue:(self.op.job==nil) ? 0.0 : [self.op.job jobProgress]];
		double			rawSecondsRemaining = self.op.job.jobTimeRemaining;
		long			secondsRemaining = rawSecondsRemaining;
		
		long			minutesRemaining = secondsRemaining/60;
		secondsRemaining -= (minutesRemaining * 60);
		
		long			hoursRemaining = minutesRemaining/60;
		minutesRemaining -= (hoursRemaining * 60);
		
		if (hoursRemaining > 0)
			[timeRemainingField setStringValue:[NSString stringWithFormat:@"%ld:%0.2ld:%0.2ld Remaining",hoursRemaining,minutesRemaining,secondsRemaining]];
		else if (minutesRemaining > 0)
			[timeRemainingField setStringValue:[NSString stringWithFormat:@"%0.2ld:%0.2ld Remaining",minutesRemaining,secondsRemaining]];
		else
			[timeRemainingField setStringValue:[NSString stringWithFormat:@":%0.2ld Remaining",secondsRemaining]];
		
		statusField.toolTip = nil;
		break;
	}
}

- (IBAction) enableToggleUsed:(id)sender	{
}


@end
