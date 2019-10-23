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

#import "ProgressButton.h"
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
		[progressButton setState:ProgressButtonState_CompletedSuccessfully];
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
		[progressButton setState:ProgressButtonState_Spinning];
	}
	//	else it's not a watch folder...
	else	{
		if ([self.session processedAllOps])	{
			if ([self.session processedAllOpsSuccessfully])
				[progressButton setState:ProgressButtonState_CompletedSuccessfully];
			else
				[progressButton setState:ProgressButtonState_CompletedError];
		}
		else	{
			[progressButton setState:(self.session.state == SessionState_Active) ? ProgressButtonState_Active : ProgressButtonState_Inactive];
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
	case ProgressButtonState_Inactive:
		//	make the session inactive, but don't kill any in-progress jobs
		self.session.state = SessionState_Inactive;
		break;
	case ProgressButtonState_Active:
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
	case ProgressButtonState_Spinning:
	case ProgressButtonState_CompletedSuccessfully:
	case ProgressButtonState_CompletedError:
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
