//
//	AppDelegate.h
//	MetadataTranscoderTestHarness
//
//	Created by vade on 3/31/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//

//#import "Constants.h"
#import <Cocoa/Cocoa.h>

@class SessionController;




@interface AppDelegate : NSObject <NSApplicationDelegate,NSSplitViewDelegate>	{
	IBOutlet NSWindow				*window;
	
	IBOutlet NSSplitView			*splitView;
	IBOutlet NSView					*sessionSubview;
	IBOutlet NSView					*previewSubview;
}

- (IBAction) openMovies:(id)sender;

@end


