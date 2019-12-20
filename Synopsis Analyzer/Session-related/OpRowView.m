//
//	OpRowView.m
//	Synopsis Analyzer
//
//	Created by testAdmin on 9/16/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpRowView.h"

#import "SynOp.h"
#import "SynSession.h"




static dispatch_queue_t		iconGenQueue = NULL;
static dispatch_semaphore_t		iconGenSem = NULL;
static NSMutableArray		*iconGenArray = nil;




@interface OpRowView ()
- (void) generalInit;
- (void) _updateStatusFieldWidthConstraint;
@property (strong,readwrite) NSLayoutConstraint * statusFieldWidthConstraint;
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
	self.statusFieldWidthConstraint = nil;
	[self setWantsLayer:YES];
}
- (void) awakeFromNib	{
	
	[preview setWantsLayer:YES];
	preview.layer.cornerRadius = 2.0;
	preview.layer.backgroundColor = [NSColor blackColor].CGColor;
	
	[preview setTranslatesAutoresizingMaskIntoConstraints:NO];
	[nameField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[statusField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
	[pathField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[showFileButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	CGFloat		padding = 2.0;
	
	//	preview pinned to the left
	
	[preview.heightAnchor constraintEqualToConstant:36].active = true;
	[preview.widthAnchor constraintEqualToConstant:36].active = true;
	
	//[preview.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding].active = true;
	[preview.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0].active = true;
	[preview.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
	
	
	
	
	//	show file button down slightly from vertical center, left-aligned
	[showFileButton.widthAnchor constraintEqualToConstant:20].active = true;
	[showFileButton.heightAnchor constraintEqualToAnchor:pathField.heightAnchor constant:0.0].active = true;
	[showFileButton.leadingAnchor constraintEqualToAnchor:preview.trailingAnchor constant:2.0*padding].active = true;
	//[showFileButton.centerYAnchor constraintEqualToAnchor:pathField.centerYAnchor constant:0.0].active = true;
	[showFileButton.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
	
	//	progress bar down slightly from vertical center
	[progressIndicator.leadingAnchor constraintEqualToAnchor:showFileButton.trailingAnchor constant:2.0*padding].active = true;
	//[progressIndicator.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:-padding].active = true;
	[progressIndicator.centerYAnchor constraintEqualToAnchor:showFileButton.centerYAnchor constant:0.0].active = true;
	[progressIndicator.trailingAnchor constraintEqualToAnchor:statusField.trailingAnchor constant:-2.0*padding].active = true;
	
	//	path field located in the same place as the progress bar (they switch off)
	[pathField.leadingAnchor constraintEqualToAnchor:showFileButton.trailingAnchor constant:2.0*padding].active = true;
	//[pathField.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:padding].active = true;
	[pathField.centerYAnchor constraintEqualToAnchor:showFileButton.centerYAnchor constant:0.0].active = true;
	[pathField.trailingAnchor constraintEqualToAnchor:statusField.trailingAnchor constant:-2.0*padding].active = true;
	
	//	name field slightly up from vertical center
	[nameField.leadingAnchor constraintEqualToAnchor:preview.trailingAnchor constant:4.0*padding].active = true;
	[nameField.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:-padding].active = true;
	[nameField.trailingAnchor constraintEqualToAnchor:statusField.leadingAnchor constant:-2.0*padding].active = true;
	
	//	status field sprouts off the superview
	[statusField.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:-padding].active = true;
	[statusField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12.0*padding].active = true;
}


- (void) refreshWithOp:(SynOp *)n	{
	BOOL			changed = (self.op == n) ? NO : YES;
	self.op = n;
	if (changed)	{
		[progressIndicator killAnimationSetDoubleValue:0.0];
	}
	
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
	[nameField sizeToFit];
	nameField.toolTip = self.op.src;
	[pathField setStringValue:self.op.src];
	[pathField setToolTip:self.op.src];
	[pathField sizeToFit];
	
	//	if my session hasn't been cleared to process stuff, hide the progress indicator
	if (self.op.session == nil)	{
		[progressIndicator setHidden:YES];
		[pathField setHidden:NO];
		[showFileButton setHidden:NO];
	}
	else	{
		BOOL		wantsVisibleProgressBar = NO;
		BOOL		needsVisibleProgressBar = NO;
		switch (self.op.status)	{
		case OpStatus_PreflightErr:
		case OpStatus_Err:
		case OpStatus_Complete:
			break;
		case OpStatus_Pending:
			wantsVisibleProgressBar = YES;
			break;
		case OpStatus_Preflight:
		case OpStatus_Analyze:
		case OpStatus_Cleanup:
			wantsVisibleProgressBar = YES;
			needsVisibleProgressBar = YES;
			break;
		}
		
		if ((self.op.session.state == SessionState_Active && wantsVisibleProgressBar) || needsVisibleProgressBar)	{
			[progressIndicator setHidden:NO];
			[pathField setHidden:YES];
			[showFileButton setHidden:NO];
		}
		else	{
			[progressIndicator setHidden:YES];
			[pathField setHidden:NO];
			[showFileButton setHidden:NO];
		}
	}
	
	//NSLog(@"op is %@",self.op);
	//NSLog(@"op src is %@",self.op.src);
	switch (self.op.status)	{
	case OpStatus_Pending:
		//[statusField setStringValue:[self.op createStatusString]];
		//statusField.toolTip = nil;
		if (self.op.session.state == SessionState_Active)	{
			[statusField setStringValue:[self.op createStatusString]];
			//statusField.toolTip = nil;
			[statusField sizeToFit];
			[self _updateStatusFieldWidthConstraint];
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
		[self _updateStatusFieldWidthConstraint];
		[statusField setHidden:NO];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Complete:
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = nil;
		[statusField sizeToFit];
		[self _updateStatusFieldWidthConstraint];
		[statusField setHidden:NO];
		[progressIndicator killAnimationSetDoubleValue:1.0];
		//[timeRemainingField setHidden:YES];
		break;
	case OpStatus_Err:
		//[statusField setStringValue:[self.op createStatusString]];
		[statusField setAttributedStringValue:[self.op createAttributedStatusString]];
		statusField.toolTip = self.op.errString;
		[statusField sizeToFit];
		[self _updateStatusFieldWidthConstraint];
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
		if (isnan(rawSecondsRemaining) || isinf(rawSecondsRemaining))	{
			[statusField setStringValue:@"Calculating..."];
		}
		else	{
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
		}
		[statusField sizeToFit];
		[self _updateStatusFieldWidthConstraint];
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
- (void) _updateStatusFieldWidthConstraint	{
	if (self.statusFieldWidthConstraint != nil)
		[statusField removeConstraint:self.statusFieldWidthConstraint];
	self.statusFieldWidthConstraint = [statusField.widthAnchor constraintEqualToConstant:statusField.frame.size.width];
	self.statusFieldWidthConstraint.active = true;
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






