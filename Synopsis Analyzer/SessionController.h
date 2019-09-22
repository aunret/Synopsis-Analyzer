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

@class SynSession;




@interface SessionController : NSObject <DropFileHelper>	{
	IBOutlet NSWindow			*window;
	IBOutlet NSOutlineView		*outlineView;
	IBOutlet DropFilesView		*dropView;
	
}

+ (SessionController *) global;

- (IBAction) runAnalysisAndTranscode:(id)sender;
- (IBAction) openMovies:(id)sender;
- (IBAction) revealLog:(id)sender;
- (IBAction) revealPreferences:(id)sender;

- (void) newSessionWithFiles:(NSArray<NSURL*> *)n;
- (void) newSessionWithDir:(NSURL *)n recursively:(BOOL)isRecursive;

- (void) reloadData;

@end


