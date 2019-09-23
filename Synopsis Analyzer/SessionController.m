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

#include <sys/types.h>
#include <sys/sysctl.h>




static SessionController			*globalSessionController = nil;




@interface SessionController ()
- (void) generalInit;
@property (strong) NSMutableArray<SynSession*> * sessions;

@property (strong,nullable) NSTimer * progressRefreshTimer;
@property (strong) NSMutableArray<SynOp*> * opsInProgress;
@property (atomic,readwrite) BOOL running;
- (void) startAnOp;
- (int) maxOpCount;
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
	//self.sessionsInProgress = [[NSMutableArray alloc] init];
	self.opsInProgress = [[NSMutableArray alloc] init];
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
- (IBAction) runPauseButtonClicked:(id)sender {
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		if (self.running)	{
			[self stop];
		}
		else	{
			[self start];
		}
	}
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
	//newSession.delegate = self;
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
	//newSession.delegate = self;
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
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we're already running, something went wrong- bail
		if (self.running)
			return;
		
		//	update the toolbar item's label/image
		[runPauseButton setLabel:@"Stop"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_stop"]];
	
		self.running = YES;
		for (int i=0; i<[self maxOpCount]; ++i)	{
			[self startAnOp];
		}
		
		//	if we weren't able to start any jobs, we're effectively stopped, so....stop it officially.
		if (self.opsInProgress.count < 1)
			[self stop];
	}
}
- (void) stop	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we're already stopped, something went wrong- bail
		if (!self.running)
			return;
		
		//	update the toolbar item's label/image
		[runPauseButton setLabel:@"Start"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_play_circle_filled"]];
	
		self.running = NO;
		@synchronized (self)	{
	
		}
	}
}
- (void) startAnOp	{
	NSLog(@"%s",__func__);
	//	if we're not running, something went wrong- bail, we don't want to do this
	if (!self.running)
		return;
	@synchronized (self.sessions)	{
		SynOp		*startedOp = nil;
		for (SynSession * session in self.sessions)	{
			startedOp = [session startAnOp];
			if (startedOp != nil)	{
				[self.opsInProgress addObject:startedOp];
				break;
			}
		}
	}
}
- (int) maxOpCount	{
	int				returnMe = 1;
	NSNumber		*tmpNum = [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerConcurrentJobCountPreferencesKey];
	//	 a val of -1 indicates that the user selected "auto" in the prefs
	if (tmpNum==nil || [tmpNum intValue] <= 0)	{
		/*
		//	try to get the actual number of physical cores
		size_t				len;
		unsigned int		ncpu;
		len = sizeof(ncpu);
		sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
		if (ncpu > 0)	{
			returnMe = ncpu;
		}
		//	if something went wrong, use NSProcessInfo to return the number of logical cores
		else	{
			returnMe = [[NSProcessInfo processInfo] processorCount];
		}
		*/
		returnMe = [[NSProcessInfo processInfo] processorCount];
		
		//	"too many" jobs just f-es things up
		if (returnMe > 6)
			returnMe = returnMe / 3;
	}
	//	else the user entered a specific number of jobs
	else	{
		returnMe = [tmpNum intValue];
	}
	
	return returnMe;
}


#pragma mark - SynOpDelegate protocol


- (void) synOpStatusChanged:(SynOp *_Nonnull)n	{
	NSLog(@"%s ... %@",__func__,n);
	BOOL			opFinished = NO;
	BOOL			startAnotherOp = NO;
 	@synchronized (self)	{
		
		switch (n.status)	{
		case OpStatus_Pending:
		case OpStatus_PreflightErr:
		case OpStatus_Cleanup:
			//	do nothing...
			break;
		//	if the op finished, we may want to start another
		case OpStatus_Complete:
		case OpStatus_Err:
			opFinished = YES;
			[self.opsInProgress removeObjectIdenticalTo:n];
			break;
		//	if the op started, add it to the array of ops being tracked for progress
		case OpStatus_Analyze:
			[self.opsInProgress addObject:n];
			break;
		}
		
		//	if we just finished an op, we may want to start another?
		if (opFinished)	{
			if (self.running && self.opsInProgress.count < [self maxOpCount])	{
				startAnotherOp = YES;
			}
		}
	}
	
	//	if we want to start another op...
	if (startAnotherOp)	{
		[self startAnOp];
	}
}


@end
