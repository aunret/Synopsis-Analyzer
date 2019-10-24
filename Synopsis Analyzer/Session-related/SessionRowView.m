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
	
	[iconView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[nameField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[descriptionField setTranslatesAutoresizingMaskIntoConstraints:NO];
	[progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
	[progressButton setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	//	button pinned to the right
	[progressButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-3.0].active = true;
	[progressButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:3.0].active = true;
	[progressButton.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:1.0 constant:-6.0].active = true;
	[progressButton.widthAnchor constraintEqualToAnchor:progressButton.heightAnchor multiplier:1.0 constant:0.0].active = true;
	
	//	icon pinned to the left
	[iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3.0].active = true;
	[iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:3.0].active = true;
	[iconView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:1.0 constant:-6.0].active = true;
	[iconView.widthAnchor constraintEqualToAnchor:iconView.heightAnchor multiplier:1.0 constant:0.0].active = true;
	
	//	progress bar centered vertically
	[progressIndicator.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:3.0].active = true;
	[progressIndicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.0].active = true;
	[progressIndicator.trailingAnchor constraintEqualToAnchor:progressButton.leadingAnchor constant:-3.0].active = true;
	
	//	name field sprouts off the progress bar
	[nameField.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:3.0].active = true;
	[nameField.bottomAnchor constraintEqualToAnchor:progressIndicator.topAnchor constant:1.0].active = true;
	[nameField.trailingAnchor constraintEqualToAnchor:descriptionField.leadingAnchor constant:-8.0].active = true;
	
	//	description field sprouts off the progress bar
	[descriptionField.topAnchor constraintEqualToAnchor:progressIndicator.bottomAnchor constant:1.0].active = true;
	[descriptionField.trailingAnchor constraintEqualToAnchor:progressButton.leadingAnchor constant:-3.0].active = true;
	
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
		[progressIndicator setDoubleValue:0.0];
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
		[progressIndicator setDoubleValue:0.0];
	}
	else	{
		double			tmpProgress = [self.session calculateProgress];
		[progressIndicator setDoubleValue:tmpProgress];
	}
}



- (IBAction) progressButtonUsed:(id)sender	{
	switch (progressButton.state)	{
	case SSBState_Inactive:
		//	make the session inactive, but don't kill any in-progress jobs
		self.session.state = SessionState_Inactive;
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
