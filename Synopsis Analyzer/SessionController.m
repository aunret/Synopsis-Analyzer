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
//- (void) startAnOp;
- (NSArray<SynOp*> *) getOpsToStart:(NSUInteger)numOpsToGet;
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
	NSFileManager				*fm = [NSFileManager defaultManager];
	BOOL						isDir = NO;
	//	run through the array of URLs- we want to put all the dirs in one array, and all the loose files in another
	NSMutableArray<NSURL*>		*dirs = [NSMutableArray arrayWithCapacity:0];
	NSMutableArray<NSURL*>		*files = [NSMutableArray arrayWithCapacity:0];
	for (NSURL *tmpURL in n)	{
		if ([fm fileExistsAtPath:tmpURL.path isDirectory:&isDir])	{
			if (isDir)
				[dirs addObject:tmpURL];
			else
				[files addObject:tmpURL];
		}
	}
	SynSession			*filesSession = nil;
	@synchronized (self)	{
		//	run through the array of dirs- make a session for each dir
		for (NSURL *tmpURL in dirs)	{
			SynSession		*newSession = [SynSession createWithDir:tmpURL recursively:YES];
			if (newSession == nil)
				continue;
			[self.sessions addObject:newSession];
		}
		//	make a single session with all the loose files
		if (files != nil && files.count > 0)	{
			filesSession = [SynSession createWithFiles:files];
			if (filesSession != nil)
				[self.sessions addObject:filesSession];
		}
	}
	
	//	reload the table view
	[self reloadData];
	//	expand the item for the session we just created
	[outlineView expandItem:filesSession expandChildren:YES];
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
	if ([item isKindOfClass:[SynSession class]])	{
		SynSession		*recast = (SynSession *)item;
		if (recast.type == SessionType_Dir)
			return NO;
		else
			return YES;
	}
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
		NSArray<SynOp*>		*opsToStart = [self getOpsToStart:[self maxOpCount]];
		for (SynOp * op in opsToStart)	{
			[self.opsInProgress addObject:op];
			[op start];
		}
		
		NSLog(@"\tafter starting ops, we have %d total ops in progress",self.opsInProgress.count);
		//	if we weren't able to start any jobs, we're effectively stopped, so....stop it officially.
		if (self.opsInProgress.count < 1)
			[self stop];
		//	else we have ops- make a timer to refresh the display
		else	{
			self.progressRefreshTimer = [NSTimer
				scheduledTimerWithTimeInterval:1.0
				target:self
				selector:@selector(refreshUITimer:)
				userInfo:nil
				repeats:YES];
			//	"force" the timer to proc immediately for a quick redisplay...
			[self refreshUITimer:nil];
		}
	}
}
- (void) stop	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we're already stopped, something went wrong- bail
		if (!self.running)
			return;
		
		//	kill the timer!
		if (self.progressRefreshTimer != nil)	{
			[self.progressRefreshTimer invalidate];
			self.progressRefreshTimer = nil;
		}
		
		//	update the toolbar item's label/image
		[runPauseButton setLabel:@"Start"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_play_circle_filled"]];
	
		self.running = NO;
		@synchronized (self)	{
	
		}
	}
	
	//	reload the outline view
	[self reloadData];
}
/*
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
*/
- (NSArray<SynOp*> *) getOpsToStart:(NSUInteger)numOpsToGet	{
	@synchronized (self)	{
		NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
		if ([returnMe count] == numOpsToGet)
			return returnMe;
		for (SynSession * session in self.sessions)	{
			for (SynOp * op in session.ops)	{
				switch (op.status)	{
				case OpStatus_Pending:
					[returnMe addObject:op];
					break;
				case OpStatus_PreflightErr:
				case OpStatus_Analyze:
				case OpStatus_Cleanup:
				case OpStatus_Complete:
				case OpStatus_Err:
					break;
				}
				if ([returnMe count] == numOpsToGet)
					return returnMe;
			}
		}
		return returnMe;
	}
}
- (int) maxOpCount	{
	return 3;
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
- (void) refreshUITimer:(NSTimer *)t	{
	//NSLog(@"%s",__func__);
	NSMutableArray		*sessionsInProgress = [NSMutableArray arrayWithCapacity:0];
	//	run through the array of ops in progress
	for (SynOp * op in self.opsInProgress)	{
		//	collect the sessions that are in progress (they need updating too!)
		if ([sessionsInProgress indexOfObjectIdenticalTo:op.session] == NSNotFound)
			[sessionsInProgress addObject:op.session];
		
		//	find the row that corresponds to this op, tell it to refresh its UI
		NSInteger			rowIndex = [outlineView rowForItem:op];
		if (rowIndex >= 0)	{
			OpRowView			*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			//NSLog(@"\top row view is %@",tmpView);
			if (tmpView != nil)
				[tmpView refreshUI];
		}
	}
	
	for (SynSession *session in sessionsInProgress)	{
		//	find the row that corresponds to this op, tell it to refresh its UI
		NSInteger			rowIndex = [outlineView rowForItem:session];
		if (rowIndex >= 0)	{
			SessionRowView		*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			//NSLog(@"\tsession row view is %@",tmpView);
			if (tmpView != nil)
				[tmpView refreshUI];
		}
	}
}


#pragma mark - SynOpDelegate protocol


- (void) synOpStatusFinished:(SynOp *_Nonnull)n	{
	NSLog(@"%s ... %@: %@",__func__,n,[SynopsisJobObject stringForStatus:n.job.jobStatus]);
	BOOL			opFinished = NO;
	BOOL			startAnotherOp = NO;
 	@synchronized (self)	{
		
		[self.opsInProgress removeObjectIdenticalTo:n];
		
		//	if we just finished an op, we may want to start another?
		if (self.running && self.opsInProgress.count < [self maxOpCount])	{
			startAnotherOp = YES;
		}
		
		//	if we want to start another op...
		if (startAnotherOp)	{
			NSArray<SynOp*>		*opsToStart = [self getOpsToStart:1];
			for (SynOp * op in opsToStart)	{
				[self.opsInProgress addObject:op];
				[op start];
			}
		}
	}
	
	//	if we have no more ops, stop!
	if (self.opsInProgress.count < 1)
		[self stop];
	//	else just refresh the UI for the op that completed
	else	{
		NSInteger			rowIndex = [outlineView rowForItem:n];
		if (rowIndex >= 0)	{
			OpRowView			*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			//NSLog(@"\top row view is %@",tmpView);
			if (tmpView != nil)
				[tmpView refreshUI];
		}
	}
}


@end
