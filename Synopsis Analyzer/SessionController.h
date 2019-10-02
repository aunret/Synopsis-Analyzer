//
//  SessionController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "DropFilesView.h"

//@class SynSession;
//#import "SynSession.h"
#import "SynOp.h"




@interface SessionController : NSObject <DropFileHelper,SynOpDelegate>	{
	IBOutlet NSWindow			*window;
	IBOutlet NSOutlineView		*outlineView;
	IBOutlet NSTableColumn		*theColumn;
	IBOutlet DropFilesView		*dropView;
	
	IBOutlet NSToolbarItem		*runPauseButton;
	IBOutlet NSToolbarItem		*stopButton;
	
	IBOutlet NSToolbarItem		*addItem;
	IBOutlet NSToolbarItem		*removeItem;
	IBOutlet NSToolbarItem		*clearItem;
}

+ (SessionController *) global;

- (IBAction) runPauseButtonClicked:(id)sender;
- (IBAction) cancelButtonClicked:(id)sender;

- (IBAction) openMovies:(id)sender;
- (IBAction) removeSelectedItems:(id)sender;
- (IBAction) clearClicked:(id)sender;

- (IBAction) revealLog:(id)sender;
- (IBAction) revealPreferences:(id)sender;

- (void) newSessionWithFiles:(NSArray<NSURL*> *)n;
//- (void) newSessionWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

- (void) reloadData;
- (void) reloadRowForItem:(id)n;

- (void) start;
- (void) pause;
- (void) resume;
- (void) stop;

@end


