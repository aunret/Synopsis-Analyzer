//
//  OpRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpRowView.h"

#import "SynOp.h"
#import "SynSession.h"




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
- (void) awakeFromNib	{
	
    CGFloat padding = 4.0;
    CGFloat twoPadding = padding * 2.0;
    
	//	preview pinned to the left
    [preview setWantsLayer:YES];
    preview.layer.cornerRadius = 2.0;
    preview.layer.backgroundColor = [NSColor  blackColor].CGColor;
    [preview setTranslatesAutoresizingMaskIntoConstraints:NO];
    [preview.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding].active = true;
    [preview.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0].active = true;
    [preview.heightAnchor constraintEqualToConstant:36].active = true;
    [preview.widthAnchor constraintEqualToConstant:36].active = true;

	//	progress bar centered vertically
    [progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [progressIndicator setControlTint:NSGraphiteControlTint];

    [progressIndicator.leadingAnchor constraintEqualToAnchor:preview.trailingAnchor constant:twoPadding].active = true;
	[progressIndicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
	[progressIndicator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-twoPadding].active = true;
	
	//	name field sprouts off the progress bar, limited to the width of the status field - add 2 point optical alignment factor
    [nameField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[nameField.leadingAnchor constraintEqualToAnchor:progressIndicator.leadingAnchor constant:2.0].active = true;
	[nameField.bottomAnchor constraintEqualToAnchor:progressIndicator.topAnchor constant:0.0].active = true;
	[nameField.trailingAnchor constraintEqualToAnchor:progressIndicator.trailingAnchor constant:0].active = true;
	
	//	status field sprouts off the progress bar, is limited to width of superview - add 2 point optical alignment factor
    [statusField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[statusField.bottomAnchor constraintEqualToAnchor:progressIndicator.topAnchor constant:0.0].active = true;
	[statusField.trailingAnchor constraintEqualToAnchor:progressIndicator.trailingAnchor constant:-2.0].active = true;
	
	//	time remaining field sprouts off the progress bar
//    [timeRemainingField setTranslatesAutoresizingMaskIntoConstraints:NO];
//	[timeRemainingField.trailingAnchor constraintEqualToAnchor:progressIndicator.trailingAnchor constant:0].active = true;
//	[timeRemainingField.topAnchor constraintEqualToAnchor:progressIndicator.bottomAnchor constant:0.0].active = true;
	
	//	path field sprouts off the progress bar
    [pathField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[pathField.leadingAnchor constraintEqualToAnchor:nameField.leadingAnchor constant:0.0].active = true;
	[pathField.topAnchor constraintEqualToAnchor:progressIndicator.bottomAnchor constant:0.0].active = true;
	
	//	show file button sprouts off the path field
    [showFileButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	[showFileButton.leadingAnchor constraintEqualToAnchor:pathField.trailingAnchor constant:twoPadding].active = true;
	[showFileButton.centerYAnchor constraintEqualToAnchor:pathField.centerYAnchor constant:0.0].active = true;
	[showFileButton.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:twoPadding].active = true;
    
	[showFileButton.widthAnchor constraintEqualToConstant:11].active = true;
	[showFileButton.heightAnchor constraintEqualToConstant:11].active = true;
}


- (void) refreshWithOp:(SynOp *)n	{
	self.op = n;
	[self refreshUI];
}
- (void) refreshUI	{
	//NSLog(@"%s ... %@",__func__,self.op);
	if (self.op == nil)	{
		[preview setImage:nil];
		[nameField setStringValue:@""];
		[statusField setStringValue:@"XXX"];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		[pathField setStringValue:@"XXX"];
		[pathField sizeToFit];
		//[timeRemainingField setStringValue:@"XXX"];
		return;
	}
	
	if (self.op.thumb == nil)	{
		[OpRowView addOpToIconGenQueue:self.op];
		[preview setImage:[SynOp genericMovieThumbnail]];
	}
	else	{
		[preview setImage:self.op.thumb];
	}
	[nameField setStringValue:self.op.src.lastPathComponent.stringByDeletingPathExtension];
	[pathField setStringValue:self.op.src];
	[pathField sizeToFit];
	//NSLog(@"op is %@",self.op);
	//NSLog(@"op src is %@",self.op.src);
	switch (self.op.status)	{
	case OpStatus_Pending:
		if (self.op.session.state == SessionState_Active)	{
			[statusField setStringValue:[self.op createStatusString]];
			//statusField.toolTip = nil;
			[statusField sizeToFit];
			[statusField setHidden:NO];
		}
		else
			[statusField setHidden:YES];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Preflight:
		//[statusField setStringValue:[self.op createStatusString]];
		//[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		//statusField.toolTip = self.op.errString;
		[statusField setHidden:YES];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_PreflightErr:
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = self.op.errString;
		[statusField sizeToFit];
		[statusField setHidden:NO];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Complete:
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = nil;
		[statusField sizeToFit];
		[statusField setHidden:NO];
		[progressIndicator killAnimationSetDoubleValue:1.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Err:
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = self.op.errString;
		[statusField setHidden:NO];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Analyze:
	case OpStatus_Cleanup:
		//[progressIndicator setDoubleValue:(self.op.job==nil) ? 0.0 : [self.op.job jobProgress]];
		if (self.op.job == nil)
			[progressIndicator killAnimationSetDoubleValue:0.0];
		else
			[progressIndicator animateToValue:[self.op.job jobProgress]];
		double			rawSecondsRemaining = self.op.job.jobTimeRemaining;
		long			secondsRemaining = rawSecondsRemaining;
		
		long			minutesRemaining = secondsRemaining/60;
		secondsRemaining -= (minutesRemaining * 60);
		
		long			hoursRemaining = minutesRemaining/60;
		minutesRemaining -= (hoursRemaining * 60);
		
		if (hoursRemaining > 0)
			[statusField setStringValue:[NSString stringWithFormat:@"%ld:%0.2ld:%0.2ld Remaining",hoursRemaining,minutesRemaining,secondsRemaining]];
		else if (minutesRemaining > 0)
			[statusField setStringValue:[NSString stringWithFormat:@"%0.2ld:%0.2ld Remaining",minutesRemaining,secondsRemaining]];
		else
			[statusField setStringValue:[NSString stringWithFormat:@":%0.2ld Remaining",secondsRemaining]];
		[statusField sizeToFit];
		[statusField setHidden:NO];
		
		/*
		if (hoursRemaining > 0)
			[timeRemainingField setStringValue:[NSString stringWithFormat:@"%ld:%0.2ld:%0.2ld Remaining",hoursRemaining,minutesRemaining,secondsRemaining]];
		else if (minutesRemaining > 0)
			[timeRemainingField setStringValue:[NSString stringWithFormat:@"%0.2ld:%0.2ld Remaining",minutesRemaining,secondsRemaining]];
		else
			[timeRemainingField setStringValue:[NSString stringWithFormat:@":%0.2ld Remaining",secondsRemaining]];
		[timeRemainingField sizeToFit];
		[timeRemainingField setHidden:NO];
		*/
		
		//statusField.toolTip = nil;
		//[statusField setHidden:YES];
		break;
	}
}

- (IBAction) showFileClicked:(id)sender	{
	//NSLog(@"%s",__func__);
	if (self.op == nil)
		return;
	NSWorkspace			*ws = [NSWorkspace sharedWorkspace];
	NSURL				*tmpURL = nil;
	switch (self.op.status)	{
	case OpStatus_Pending:
	case OpStatus_Preflight:
	case OpStatus_PreflightErr:
	case OpStatus_Err:
	case OpStatus_Analyze:
	case OpStatus_Cleanup:
		tmpURL = [NSURL fileURLWithPath:self.op.src isDirectory:NO];
		break;
	case OpStatus_Complete:
		tmpURL = [NSURL fileURLWithPath:self.op.dst isDirectory:NO];
		break;
	}
	
	if (tmpURL == nil)
		return;
	
	[ws activateFileViewerSelectingURLs:@[ tmpURL ]];
}


@end






