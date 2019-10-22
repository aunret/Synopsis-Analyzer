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




@interface AppDelegate : NSObject <NSApplicationDelegate,NSAnimationDelegate>	{
	IBOutlet NSWindow				*window;
	
	IBOutlet NSView					*windowContentView;
	IBOutlet NSView					*sessionSubview;
	IBOutlet NSView					*previewSubview;
}

- (void) showPreview;
- (void) hidePreview;

- (IBAction) openMovies:(id)sender;
- (IBAction) openPreferences:(id)sender;

- (IBAction) addWatchFolder:(id)sender;

@end


