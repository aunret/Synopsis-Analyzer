//
//  SessionRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionRowView.h"

#import "PrefsController.h"
#import "SynSession.h"

#import "NSPopUpButtonAdditions.h"
#import "InspectorViewController.h"

#import "SessionStateButton.h"
#import "SessionController.h"




@interface SessionRowView ()
- (void) generalInit;
@end




@implementation SessionRowView


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
	[self setWantsLayer:YES];
}

- (void) awakeFromNib	{
	
    CGFloat padding = 4.0;
    CGFloat twoPadding = padding * 2.0;


    //    icon pinned to the left
    [iconView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding].active = true;
    [iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0].active = true;
    [iconView.heightAnchor constraintEqualToConstant:36].active = true;
    [iconView.widthAnchor constraintEqualToConstant:36].active = true;

    //    progress bar centered vertically
    [progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [progressIndicator.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:twoPadding].active = true;
    [progressIndicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
    [progressIndicator.trailingAnchor constraintEqualToAnchor:progressButton.leadingAnchor constant:-twoPadding].active = true;

    //    name field sprouts off the progress bar, limited by width of description field - add 2 point optical alignment factor
    [nameField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [nameField.leadingAnchor constraintEqualToAnchor:progressIndicator.leadingAnchor constant:2].active = true;
    [nameField.bottomAnchor constraintEqualToAnchor:progressIndicator.topAnchor constant:0].active = true;
    [nameField.trailingAnchor constraintEqualToAnchor:descriptionField.leadingAnchor constant:-twoPadding].active = true;
    
	//	button pinned to the right
    [progressButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [progressButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-twoPadding].active = true;
	[progressButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
    [progressButton.heightAnchor constraintEqualToConstant:48].active = true;
    [progressButton.widthAnchor constraintEqualToConstant:48].active = true;

	//	description field sprouts off the progress bar - add 2 point optical alignment factor
    [descriptionField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[descriptionField.firstBaselineAnchor constraintEqualToAnchor:nameField.firstBaselineAnchor constant:0.0].active = true;
	[descriptionField.trailingAnchor constraintEqualToAnchor:progressButton.leadingAnchor constant:-(twoPadding + 2.0)].active = true;
	
}


- (void) refreshWithSession:(SynSession *)n	{
	self.session = n;
	[self refreshUI];
}
- (void) refreshUI	{
	//NSLog(@"%s",__func__);
	if (self.session == nil)	{
		[nameField setStringValue:@""];
		[descriptionField setStringValue:@"XXX"];
		[progressIndicator killAnimationSetDoubleValue:0.0];
		[progressButton setState:SSBState_CompletedSuccessfully];
		return;
	}
	
	
	//	populate the name field and icon view
	[nameField setStringValue:self.session.title];
	//	if it's a directory-type session
	if (self.session.type == SessionType_Dir)	{
		[nameField setEditable:NO];
		if (self.session.watchFolder)	{
			[iconView setImage:[NSImage imageNamed:@"WatchFolder"]];
		}
		else	{
			[iconView setImage:[NSImage imageNamed:@"ic_folder_white"]];
		}
	}
	//	else it's a list-type session
	else	{
		[nameField setEditable:YES];
		[iconView setImage:[NSImage imageNamed:@"ic_insert_drive_file_white"]];
	}
	
	//	populate the description field
	[descriptionField setStringValue:[self.session createDescriptionString]];
	
	//	populate the progress button
	if (self.session.watchFolder)	{
		[progressButton setState:SSBState_Spinning];
	}
	//	else it's not a watch folder...
	else	{
		if ([self.session processedAllOps])	{
			if ([self.session processedAllOpsSuccessfully])
				[progressButton setState:SSBState_CompletedSuccessfully];
			else
				[progressButton setState:SSBState_CompletedError];
		}
		else	{
			[progressButton setState:(self.session.state == SessionState_Active) ? SSBState_Active : SSBState_Inactive];
		}
	}
	
	//	populate the progress indicator
	if ([self.session processedAllOps])	{
		[progressIndicator killAnimationSetDoubleValue:0.0];
	}
	else	{
		double			tmpProgress = [self.session calculateProgress];
		if (tmpProgress == 0.0 || tmpProgress == 1.0)
			[progressIndicator killAnimationSetDoubleValue:tmpProgress];
		else
			[progressIndicator animateToValue:tmpProgress];
			//[progressIndicator killAnimationSetDoubleValue:tmpProgress];
			//[progressIndicator setDoubleValue:tmpProgress];
	}
}



- (IBAction) progressButtonUsed:(id)sender	{
	switch (progressButton.state)	{
	case SSBState_Inactive:
		//	make the session inactive, but don't kill any in-progress jobs
		self.session.state = SessionState_Inactive;
		//	tell the session controller to update the UI on the various op rows i have (they need to display "Pending")
		for (SynOp *op in self.session.ops)	{
			[[SessionController global] reloadRowForItem:op];
		}
		break;
	case SSBState_Active:
		{
			//	make the session active, start the session controller if it isn't running
			self.session.state = SessionState_Active;
			SessionController		*sc = [SessionController global];
			if (![sc processingFiles])	{
				[sc startButDontChangeSessionStates];
			}
			[sc makeSureRunningMaxPossibleOps];
			//	tell the session controller to update the UI on the various op rows i have (they need to display "Pending")
			for (SynOp *op in self.session.ops)	{
				[sc reloadRowForItem:op];
			}
		}
		break;
	case SSBState_Spinning:
	case SSBState_CompletedSuccessfully:
	case SSBState_CompletedError:
		return;
	}
}
- (IBAction) nameFieldUsed:(id)sender	{
	if (self.session == nil)
		return;
	if (self.session.type == SessionType_Dir)
		return;
	self.session.title = [sender stringValue];
}


@end
