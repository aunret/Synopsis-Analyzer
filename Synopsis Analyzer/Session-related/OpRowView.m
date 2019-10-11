//
//  OpRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpRowView.h"

#import "SynOp.h"




static dispatch_queue_t		iconGenQueue = NULL;
static dispatch_semaphore_t		iconGenSem = NULL;
static NSMutableArray		*iconGenArray = nil;




@interface OpRowView ()
- (void) generalInit;
@end




@implementation OpRowView


+ (void) initialize	{
	@synchronized (self)	{
		if (iconGenQueue == NULL)	{
			iconGenQueue = dispatch_queue_create("info.synopsis.icongenqueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
			iconGenSem = dispatch_semaphore_create(12);
			iconGenArray = [[NSMutableArray alloc] init];
		}
	}
}
+ (void) addOpToIconGenQueue:(SynOp *)n	{
	//	add the op we just requested to the top of the queue
	@synchronized (iconGenArray)	{
		[iconGenArray removeObjectIdenticalTo:n];
		[iconGenArray insertObject:n atIndex:0];
	}
	
	dispatch_async(iconGenQueue, ^{
		//	wait for the concurrency semaphore to signal we're free to process
		dispatch_semaphore_wait(iconGenSem, DISPATCH_TIME_FOREVER);
		
		//	pull the first op out of the array (the most recently-added op to the array, not necessarily the one we just requested)
		SynOp			*opToGen = nil;
		@synchronized (iconGenArray)	{
			if ([iconGenArray count]>0)	{
				opToGen = [iconGenArray objectAtIndex:0];
				[iconGenArray removeObjectAtIndex:0];
			}
		}
		//	populate it
		if (opToGen != nil)
			[opToGen populateThumb];
		
		//	signal the concurrency semaphore that we're done, and another op may begin
		dispatch_semaphore_signal(iconGenSem);
	});
}


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
	if (self.op.thumb == nil)	{
		[OpRowView addOpToIconGenQueue:self.op];
		[preview setImage:[SynOp genericMovieThumbnail]];
	}
	else	{
		[preview setImage:self.op.thumb];
	}
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
		//statusField.toolTip = self.op.job.jobErrString;
		statusField.toolTip = self.op.errString;
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
		//statusField.toolTip = self.op.job.jobErrString;
		statusField.toolTip = self.op.errString;
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
