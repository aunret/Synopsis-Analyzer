//
//	SessionController.m
//	Synopsis Analyzer
//
//	Created by testAdmin on 9/16/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionController.h"
#import <Synopsis/Synopsis.h>
#import "LogController.h"
#import "PrefsController.h"

#import "SynOp.h"
#import "SynSession.h"

#import "OpRowView.h"
#import "SessionRowView.h"




static SessionController			*globalSessionController = nil;




@interface SessionController ()
- (void) generalInit;
@property (strong) NSMutableArray<SynSession*> * sessions;
@property (atomic,readwrite) BOOL running;
@end




@implementation SessionController


+ (SessionController *) global	{
	return globalSessionController;
}


- (id) init	{
	self = [super init];
	if (self != nil)	{
		globalSessionController = self;
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	self.sessions = [[NSMutableArray alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	//[self window];
}
- (void) awakeFromNib	{
	[dropView setDragDelegate:self];
	outlineView.outlineTableColumn = theColumn;
}


- (void) applicationDidFinishLaunching:(NSNotification *)note	{
	
}
- (void) applicationWillTerminate:(NSNotification *)note	{
}


#pragma mark - UI


//static BOOL isRunning = NO;
- (IBAction) runAnalysisAndTranscode:(id)sender {
	
}

- (IBAction)openMovies:(id)sender	{
	NSLog(@"should be adding movies here");
	// Open a movie or two
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowedFileTypes:SynopsisSupportedFileTypes()];
	
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result)	{
		if (result == NSModalResponseOK)	{
			[self analysisSessionForFiles:openPanel.URLs sessionCompletionBlock:^{
				 
			}];
		}
	}];
}

- (IBAction) revealLog:(id)sender	{
	//[self revealHelper:self.logWindow sender:sender];
	NSLog(@"should be opening log window here");
}

- (IBAction) revealPreferences:(id)sender	{
	//[self revealHelper:self.prefsWindow sender:sender];
	NSLog(@"should be opening preferences here");
	[[[PrefsController global] window] makeKeyAndOrderFront:nil];
}


- (void) newSessionWithFiles:(NSArray<NSURL*> *)n	{
	if (n == nil || [n count] < 1)
		return;
	//	make a session
	SynSession			*newSession = [SynSession createWithFiles:n];
	if (newSession == nil)
		return;
	//	add the session to our list of sessions
	@synchronized (self)	{
		[self.sessions addObject:newSession];
	}
	//	reload the table view
	[self reloadData];
	//	expand the item for the session we just created
	[outlineView expandItem:newSession expandChildren:YES];
}
- (void) newSessionWithDir:(NSURL *)n recursively:(BOOL)isRecursive	{
	if (n == nil)
		return;
	//	make a session
	SynSession			*newSession = [SynSession createWithDir:n recursively:isRecursive];
	if (newSession == nil)
		return;
	//	add the session to our list of sessions
	@synchronized (self)	{
		[self.sessions addObject:newSession];
	}
	//	reload the table view
	[self reloadData];
	//	expand the item for the session we just created
	[outlineView expandItem:newSession expandChildren:YES];
}


- (void) reloadData	{
	[outlineView reloadData];
}


#pragma mark - DropFileHelper


- (void) analysisSessionForFiles:(NSArray *)fileURLArray sessionCompletionBlock:(void (^)(void))completionBlock {
	NSLog(@"%s ... %@",__func__,fileURLArray);
	[self newSessionWithFiles:fileURLArray];
	completionBlock();
}


#pragma mark - outline view data source/delegate


/*
- (NSTableRowView *)outlineView:(NSOutlineView *)ov rowViewForItem:(id)item	{
	NSTableRowView		*returnMe = [[CustomRowView alloc] init];
	[returnMe setIdentifier:@"row"];
	return returnMe;
}
*/
- (NSInteger) outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item	{
	if (item == nil)	{
		return self.sessions.count;
	}
	
	if ([item isKindOfClass:[SynSession class]])	{
		return [[(SynSession*)item ops] count];
	}
	
	return 0;
}
- (id) outlineView:(NSOutlineView *)ov child:(NSInteger)index ofItem:(id)item	{
	//NSLog(@"%s ... %d, %@",__func__,index,item);
	if (item == nil)	{
		if (index>=0 && index<[self.sessions count])
			return self.sessions[index];
	}
	
	if ([item isKindOfClass:[SynSession class]])	{
		if (index>=0 && index<[[(SynSession*)item ops] count])
			return [[(SynSession*)item ops] objectAtIndex:index];
	}
	
	return nil;
}

- (BOOL) outlineView:(NSOutlineView *)ov isItemExpandable:(id)item	{
	if (item == nil)
		return YES;
	if ([item isKindOfClass:[SynSession class]])
		return YES;
	return NO;
}

- (NSView *) outlineView:(NSOutlineView *)ov viewForTableColumn:(NSTableColumn *)tc item:(id)item	{
	if (item==nil)
		return nil;
	NSTableCellView			*returnMe = nil;
	if ([item isKindOfClass:[SynOp class]])	{
		returnMe = [ov makeViewWithIdentifier:@"OpRowView" owner:self];
		if (returnMe != nil)
			[(OpRowView*)returnMe refreshWithOp:item];
	}
	else if ([item isKindOfClass:[SynSession class]])	{
		returnMe = [ov makeViewWithIdentifier:@"SessionRowView" owner:self];
		if (returnMe != nil)
			[(SessionRowView*)returnMe refreshWithSession:item];
	}
	return returnMe;
}
/*
- (CGFloat) outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item	{
}
*/
- (void) outlineViewSelectionDidChange:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
}


#pragma mark - backend


- (void) start	{
	@synchronized (self)	{
	
	}
}
- (void) stop	{
	@synchronized (self)	{
	
	}
}
- (BOOL) processing	{
	BOOL			returnMe = NO;
	@synchronized (self)	{
		returnMe = self.running;
	}
	return returnMe;
}


@end
