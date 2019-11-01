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

#import "InspectorViewController.h"
#import "AppDelegate.h"

#include <sys/types.h>
#include <sys/sysctl.h>




static SessionController			*globalSessionController = nil;

static NSString						*localFileDragType = @"localFileDragType";




@interface SessionController ()
- (void) generalInit;
@property (assign,readwrite,atomic) BOOL paused;
@property (strong) NSMutableArray<SynSession*> * watchFolderSessions;
@property (strong) NSMutableArray<SynSession*> * sessions;

@property (strong,nullable) NSTimer * progressRefreshTimer;
@property (strong) NSMutableArray<SynOp*> * opsInProgress;
@property (atomic,readwrite) BOOL running;
@property (strong,readwrite,atomic) NSMutableDictionary * expandStateDict;
@property (atomic,readwrite) BOOL dragInProgress;	//	when the drag's in progress, we don't modify changes to 'expandStateDict'

@property (atomic,strong,readwrite,nullable) id appNapToken;

@property (atomic,readwrite) BOOL wokeUpOnce;	//	'awakeFromNib' is called every time we pull a view out of the table- we only want to call its contents once...

//- (void) startAnOp;
- (NSArray<SynOp*> *) getOpsToStart:(NSUInteger)numOpsToGet;
- (int) maxOpCount;
- (id) objectForUUID:(NSUUID *)n;
- (void) restoreExpandStates;
@end




//	these macros make it slightly easier to work with two arrays that, combined, populate the single outline view
#define WATCH_SESSIONS_COUNT (self.watchFolderSessions.count)
#define SESSIONS_COUNT (self.sessions.count)
#define TOTAL_SESSIONS_COUNT (WATCH_SESSIONS_COUNT + SESSIONS_COUNT)




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
	self.watchFolderSessions = [[NSMutableArray alloc] init];
	self.sessions = [[NSMutableArray alloc] init];
	self.sessionQueue = dispatch_queue_create("sessionQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
	//self.sessionsInProgress = [[NSMutableArray alloc] init];
	self.opsInProgress = [[NSMutableArray alloc] init];
	self.running = NO;
	self.expandStateDict = [NSMutableDictionary dictionaryWithCapacity:0];
	self.dragInProgress = NO;
	
	//	make an app nap token right away- we can't nap b/c we're either transcoding/analyzing, or potentially watching a directory for changes to its files!
	self.appNapToken = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated | NSActivityLatencyCritical reason:@"Analyzing"];
	
	self.wokeUpOnce = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	//[self window];
	
	//	register to receive notifications that the concurrency settings have changed...
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(concurrencyChanged:) name:kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification object:nil];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	if (!self.wokeUpOnce)	{
		//[dropView setDragDelegate:self];
		outlineView.outlineTableColumn = theColumn;
		
		[outlineView registerNib:[[NSNib alloc] initWithNibNamed:@"SessionRowView" bundle:[NSBundle mainBundle]] forIdentifier:@"SessionRowView"];
		[outlineView registerNib:[[NSNib alloc] initWithNibNamed:@"OpRowView" bundle:[NSBundle mainBundle]] forIdentifier:@"OpRowView"];
		[outlineView setRowHeight:64.0];
		
		[stopButton setEnabled:NO];
	
		[outlineView registerForDraggedTypes:@[ NSPasteboardTypeFileURL, localFileDragType ]];
		//[outlineView setDraggingSourceOperationMask:NSDragOperationLink forLocal:NO];
		[outlineView setDraggingSourceOperationMask:NSDragOperationGeneric forLocal:YES];
		
		self.wokeUpOnce = YES;
	}
}


- (void) applicationDidFinishLaunching:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		NSData				*tmpData = nil;
		
		tmpData = [def objectForKey:@"watchFolderSessions"];
		if (tmpData != nil && [tmpData isKindOfClass:[NSData class]])	{
			NSArray				*tmpArray = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
			if (tmpArray != nil && [tmpArray isKindOfClass:[NSArray class]] && [tmpArray count] > 0)	{
				for (SynSession *tmpSession in tmpArray)	{
					if ([tmpSession isKindOfClass:[SynSession class]] && tmpSession.type == SessionType_Dir && tmpSession.watchFolder)	{
						[self.watchFolderSessions addObject:tmpSession];
						//self.expandStateDict[tmpSession.dragUUID.UUIDString] = @YES;
					}
				}
				[self reloadData];
			}
		}
		
		tmpData = [def objectForKey:@"sessions"];
		if (tmpData != nil && [tmpData isKindOfClass:[NSData class]])	{
			NSArray				*tmpArray = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
			if (tmpArray != nil && [tmpArray isKindOfClass:[NSArray class]] && [tmpArray count] > 0)	{
				for (SynSession		*tmpSession in tmpArray)	{
					if ([tmpSession isKindOfClass:[SynSession class]])	{
						[self.sessions addObject:tmpSession];
						//if (tmpSession.type == SessionType_List)
						//	self.expandStateDict[tmpSession.dragUUID.UUIDString] = @YES;
					}
				}
				[self reloadData];
			}
		}
		
		//	enable/disable the run-pause button based on the number of active ops
		[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
	}
}
- (void) applicationWillTerminate:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		NSData				*encodedSessions = nil;
		
		NSMutableArray		*watchFolderSessionsToSave = [NSMutableArray arrayWithCapacity:0];
		for (SynSession *session in self.watchFolderSessions)	{
			[watchFolderSessionsToSave addObject:session];
		}
		
		if (watchFolderSessionsToSave != nil && [watchFolderSessionsToSave count] > 0)	{
			encodedSessions = [NSKeyedArchiver archivedDataWithRootObject:watchFolderSessionsToSave];
		}
		else
			encodedSessions = nil;
		
		if (encodedSessions != nil)
			[def setObject:encodedSessions forKey:@"watchFolderSessions"];
		else
			[def removeObjectForKey:@"watchFolderSessions"];
		
		
		NSMutableArray		*sessionsToSave = [NSMutableArray arrayWithCapacity:0];
		for (SynSession *session in self.sessions)	{
			if ([session opsToSave] != nil || session.type == SessionType_Dir)	{
				[sessionsToSave addObject:session];
			}
		}
		
		if (sessionsToSave != nil && [sessionsToSave count] > 0)	{
			encodedSessions = [NSKeyedArchiver archivedDataWithRootObject:sessionsToSave];
		}
		else
			encodedSessions = nil;
		
		if (encodedSessions != nil)
			[def setObject:encodedSessions forKey:@"sessions"];
		else
			[def removeObjectForKey:@"sessions"];
		
		
		[def synchronize];
	}
}


#pragma mark - backend


- (void) start	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we're already running, something went wrong- bail
		if (self.running)
			return;
		
		[LogController appendVerboseLog:@"Starting analysis globally..."];
		
		//	update the relevant toolbar items
		[runPauseButton setEnabled:YES];
		[runPauseButton setLabel:@"Pause"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_pause_circle_filled"]];
		[stopButton setEnabled:YES];
		[addItem setEnabled:NO];
		[removeItem setEnabled:NO];
		[clearItem setEnabled:NO];
		
		//	deselect everything in the outline view
		//[outlineView deselectAll:nil];
		//[self outlineViewSelectionDidChange:nil];
		
		//	hide the preview
		//[appDelegate hidePreview];
		
		//	update ivars
		self.running = YES;
		self.paused = NO;
		
		//	run through my sessions, change their states to 'active'
		for (SynSession *session in self.sessions)	{
			session.state = SessionState_Active;
			//	we don't want to reloadData right now (would change scroll pos) so just update the relevant rows...
			[self reloadRowForItem:session];
		}
		
		//	do stuff with ops
		[self makeSureRunningMaxPossibleOps];
		
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
- (void) startButDontChangeSessionStates	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we're already running, something went wrong- bail
		if (self.running)
			return;
		
		[LogController appendVerboseLog:@"Starting analysis globally..."];
		
		//	update the relevant toolbar items
		[runPauseButton setEnabled:YES];
		[runPauseButton setLabel:@"Pause"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_pause_circle_filled"]];
		[stopButton setEnabled:YES];
		[addItem setEnabled:NO];
		[removeItem setEnabled:NO];
		[clearItem setEnabled:NO];
		
		//	deselect everything in the outline view
		//[outlineView deselectAll:nil];
		//[self outlineViewSelectionDidChange:nil];
		
		//	hide the preview
		//[appDelegate hidePreview];
		
		//	update ivars
		self.running = YES;
		self.paused = NO;
		
		//	do stuff with ops
		[self makeSureRunningMaxPossibleOps];
		
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
- (void) pause	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		if (self.paused)
			return;
		
		[LogController appendVerboseLog:@"Pausing analysis globally..."];
		
		//	update the relevant toolbar items
		[runPauseButton setLabel:@"Resume"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_play_circle_filled"]];
		
		//	update ivars
		self.running = YES;
		self.paused = YES;
		
		//	do stuff with ops
		for (SynOp *op in self.opsInProgress)	{
			[op pause];
		}
		
		//	do stuff with the timer
		if (self.progressRefreshTimer != nil)	{
			[self.progressRefreshTimer invalidate];
			self.progressRefreshTimer = nil;
		}
	}
}
- (void) resume	{
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		if (!self.paused)
			return;
		
		[LogController appendVerboseLog:@"Resuming analysis globally..."];
		
		//	update the relevant toolbar items
		[runPauseButton setLabel:@"Pause"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_pause_circle_filled"]];
		
		//	update ivars
		self.running = YES;
		self.paused = NO;
		
		//	do stuff with ops
		for (SynOp *op in self.opsInProgress)	{
			[op resume];
		}
		//	it's possible that an op state change occurred juuust as pausing, and as such we may have fewer jobs than we should...
		[self makeSureRunningMaxPossibleOps];
		
		//	it's also possible that the user paused juuuust as jobs were finishing, and there are now no more jobs to process...
		if (self.opsInProgress.count < 1)
			[self stop];
		//	else we have ops- we need to start the timer!
		else	{
			//	do stuff with the timer
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
		
		[LogController appendVerboseLog:@"Stopping analysis globally..."];
		
		//	update the relevant toolbar items
		[runPauseButton setLabel:@"Start"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_play_circle_filled"]];
		[stopButton setEnabled:NO];
		[addItem setEnabled:YES];
		[removeItem setEnabled:YES];
		[clearItem setEnabled:YES];
		
		//	show the preview
		//[appDelegate showPreview];
		
		//	update ivars
		self.running = NO;
		self.paused = NO;
		
		//	run through my sessions, change their states to 'inactive'
		for (SynSession *session in self.sessions)	{
			session.state = SessionState_Inactive;
			//	we don't want to reloadData right now (would change scroll pos) so just update the relevant rows...
			//[self reloadRowForItem:session];
		}
		
		//	do stuff with ops
		for (SynOp *op in self.opsInProgress)	{
			[op stop];
		}
		
		if ([self numberOfFilesToProcess] < 1)
			[runPauseButton setEnabled:NO];
		
		//	do stuff with the timer
		if (self.progressRefreshTimer != nil)	{
			[self.progressRefreshTimer invalidate];
			self.progressRefreshTimer = nil;
		}
	}
	
	//	reload the outline view
	[self reloadData];
}
- (BOOL) processingFiles	{
	BOOL		returnMe = NO;
	@synchronized (self)	{
		returnMe = (self.opsInProgress.count > 0) ? YES : NO;
	}
	return returnMe;
}
- (BOOL) processingFilesFromSession:(SynSession *)n	{
	if (n == nil)
		return NO;
	BOOL			returnMe = NO;
	@synchronized (self)	{
		for (SynOp *op in self.opsInProgress)	{
			if ([n.ops indexOfObjectIdenticalTo:op] != NSNotFound)	{
				returnMe = YES;
				break;
			}
		}
	}
	return returnMe;
}
- (void) makeSureRunningMaxPossibleOps	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		NSArray<SynOp*>		*opsToStart = [self getOpsToStart:(self.maxOpCount - self.opsInProgress.count)];
		NSMutableArray		*sessionsToReInspect = [NSMutableArray arrayWithCapacity:0];
		for (SynOp *opToStart in opsToStart)	{
			if (opToStart.session != nil && [sessionsToReInspect indexOfObjectIdenticalTo:opToStart.session] == NSNotFound)
				[sessionsToReInspect addObject:opToStart.session];
			[self.opsInProgress addObject:opToStart];
			[LogController appendVerboseLog:[NSString stringWithFormat:@"Starting analysis on %@",opToStart.src.lastPathComponent]];
			[opToStart start];
		}
		//	run through the sessions of the ops we just started, update the inspector if any of them are inspected
		for (SynSession *session in sessionsToReInspect)	{
			[[InspectorViewController global] reloadInspectorIfInspected:session];
		}
	}
}
- (NSUInteger) numberOfFilesToProcess	{
	NSUInteger		returnMe = 0;
	@synchronized (self)	{
		for (SynSession *session in self.sessions)	{
			for (SynOp *op in session.ops)	{
				switch (op.status)	{
				case OpStatus_Pending:
					++returnMe;
					break;
				case OpStatus_PreflightErr:
				case OpStatus_Analyze:
				case OpStatus_Cleanup:
				case OpStatus_Complete:
				case OpStatus_Err:
					break;
				}
			}
		}
	}
	return returnMe;
}


- (NSArray<SynOp*> *) getOpsToStart:(NSUInteger)numOpsToGet	{
	if (numOpsToGet <= 0)
		return @[];
	
	@synchronized (self)	{
		NSMutableArray		*returnMe = [NSMutableArray arrayWithCapacity:0];
		if ([returnMe count] == numOpsToGet)
			return returnMe;
		
		NSArray				*allSessionArrays = @[ self.watchFolderSessions, self.sessions ];
		for (NSArray * sessionArray in allSessionArrays)	{
			for (SynSession *session in sessionArray)	{
				//	only pull an op from a session if the session is a watch folder, or if it's explicitly active
				if (session.watchFolder || session.state == SessionState_Active)	{
					for (SynOp * op in session.ops)	{
						switch (op.status)	{
						case OpStatus_Pending:
							[returnMe addObject:op];
							break;
						case OpStatus_Preflight:
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
			}
		}
		return returnMe;
	}
}
- (int) maxOpCount	{
	//NSLog(@"%s",__func__);
	int				returnMe = 1;
	
	NSNumber		*tmpConcurrentJobs = [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerConcurrentJobAnalysisPreferencesKey];
	if (tmpConcurrentJobs == nil || ![tmpConcurrentJobs boolValue])	{
		returnMe = 1;
	}
	else	{
		NSNumber		*tmpJobCount = [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerConcurrentJobCountPreferencesKey];
		//NSLog(@"\tval from defaults is %@",tmpJobCount);
		//	 a val of -1 indicates that the user selected "auto" in the prefs
		if (tmpJobCount==nil || [tmpJobCount intValue] <= 0)	{
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
			returnMe = (int)[[NSProcessInfo processInfo] processorCount];
		
			//	"too many" jobs just f-es things up
			if (returnMe > 6)
				returnMe = returnMe / 2;
		}
		//	else the user entered a specific number of jobs
		else	{
			returnMe = [tmpJobCount intValue];
		}
	}
	
	return returnMe;
}
- (id) objectForUUID:(NSUUID *)n	{
	if (n == nil)
		return nil;
	id				returnMe = nil;
	@synchronized (self)	{
		NSArray			*allSessionArrays = @[ self.watchFolderSessions, self.sessions ];
		for (NSArray *sessionArray in allSessionArrays)	{
			for (SynSession *session in sessionArray)	{
				if ([session.dragUUID isEqual:n])	{
					returnMe = session;
					break;
				}
				for (SynOp *op in session.ops)	{
					if ([op.dragUUID isEqual:n])	{
						returnMe = op;
						break;
					}
				}
			}
		}
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
		
		//	tell the op in progress to check for hangs!
		[op checkForHang];
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
- (void) concurrencyChanged:(NSNotification *)note	{
	[self makeSureRunningMaxPossibleOps];
}


#pragma mark - UI


//static BOOL isRunning = NO;
- (IBAction) runPauseButtonClicked:(id)sender {
	NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	if we aren't running yet, just start
		if (!self.running)	{
			[self start];
		}
		//	else we're running...
		else	{
			//	if we're paused, resume!
			if (self.paused)	{
				[self resume];
			}
			//	else we're not paused- we should pause!
			else	{
				[self pause];
			}
		}
		/*
		if (self.running)	{
			[self stop];
		}
		else	{
			[self start];
		}
		*/
	}
}
- (IBAction) cancelButtonClicked:(id)sender	{
	NSLog(@"%s",__func__);
	[self stop];
}


- (IBAction)openMovies:(id)sender	{
	// Open a movie or two
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowedFileTypes:SynopsisSupportedFileTypes()];
	[openPanel setMessage:@"Select one or more movie files (.mov, .mp4, .m4v, .3gp, .mxf) to import"];
	
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result)	{
		if (result == NSModalResponseOK)	{
			[self analysisSessionForFiles:openPanel.URLs sessionCompletionBlock:^{
				//	enable/disable the run-pause button based on the number of active ops
				[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
			}];
		}
	}];
}
- (IBAction) removeSelectedItems:(id)sender	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		NSInteger		selRow = [outlineView selectedRow];
		if (selRow < 0)
			return;
		id				selItem = [outlineView itemAtRow:selRow];
		if (selItem == nil)
			return;
		//NSLog(@"\t\tshould be removing %@",selItem);
		if ([selItem isKindOfClass:[SynSession class]])	{
			SynSession		*tmpSession = (SynSession *)selItem;
			NSInteger		tmpIndex;
			tmpIndex = [self.watchFolderSessions indexOfObjectIdenticalTo:tmpSession];
			if (tmpIndex != NSNotFound && tmpIndex >= 0)	{
				[self.watchFolderSessions removeObjectIdenticalTo:tmpSession];
				[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:tmpIndex] inParent:nil withAnimation:NSTableViewAnimationSlideUp];
			}
			tmpIndex = [self.sessions indexOfObjectIdenticalTo:tmpSession];
			if (tmpIndex != NSNotFound && tmpIndex >= 0)	{
				[self.sessions removeObjectIdenticalTo:tmpSession];
				[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:WATCH_SESSIONS_COUNT + tmpIndex] inParent:nil withAnimation:NSTableViewAnimationSlideUp];
			}
			
			//[self reloadData];
			[self outlineViewSelectionDidChange:nil];
		}
		else if ([selItem isKindOfClass:[SynOp class]])	{
			SynOp			*tmpTop = (SynOp *)selItem;
			SynSession		*tmpSession = tmpTop.session;
			if (tmpSession == nil)
				return;
			
			[outlineView beginUpdates];
			
			NSInteger		tmpIndex = [tmpSession.ops indexOfObjectIdenticalTo:tmpTop];
			if (tmpIndex != NSNotFound && tmpIndex >= 0)	{
				[tmpSession.ops removeObjectIdenticalTo:tmpTop];
				[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:tmpIndex] inParent:tmpSession withAnimation:NSTableViewAnimationSlideUp];
			}
			
			//	if the session doesn't have any ops remaining, remove it as well
			if (tmpSession.ops.count < 1)	{
				tmpIndex = [self.sessions indexOfObjectIdenticalTo:tmpSession];
				[self.sessions removeObjectIdenticalTo:tmpSession];
				if (tmpIndex != NSNotFound && tmpIndex >= 0)
					[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:tmpIndex] inParent:nil withAnimation:NSTableViewAnimationSlideUp];
			}
			
			[outlineView endUpdates];
			
			//[self reloadData];
			[self outlineViewSelectionDidChange:nil];
		}
		
		//	enable/disable the run-pause button based on the number of active ops
		[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
	}
}
- (IBAction) clearClicked:(id)sender	{
	@synchronized (self)	{
		[self.sessions removeAllObjects];
		[self reloadData];
		//	enable/disable the run-pause button based on the number of active ops
		[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
	}
}


- (IBAction) revealLog:(id)sender	{
	//[self revealHelper:self.logWindow sender:sender];
	[[[LogController global] window] makeKeyAndOrderFront:nil];
}

- (IBAction) revealPreferences:(id)sender	{
	//[self revealHelper:self.prefsWindow sender:sender];
	[[[PrefsController global] window] makeKeyAndOrderFront:nil];
}


- (NSArray<SynSession*> *) createSessionsWithFiles:(NSArray<NSURL*> *)n	{
	if (n == nil || [n count] < 1)
		return nil;
	NSMutableArray				*returnMe = [NSMutableArray arrayWithCapacity:0];
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
			[returnMe addObject:newSession];
		}
		//	make a single session with all the loose files
		if (files != nil && files.count > 0)	{
			filesSession = [SynSession createWithFiles:files];
			if (filesSession != nil && filesSession.ops.count > 0)
				[returnMe addObject:filesSession];
		}
	}
	
	if ([returnMe count]<1)
		returnMe = nil;
	return returnMe;
}
- (void) createAndAppendSessionsWithFiles:(NSArray<NSURL*> *)n	{
	NSArray			*newSessions = [self createSessionsWithFiles:n];
	if (newSessions==nil || [newSessions count]<1)
		return;
	//SynSession		*filesSession = nil;
	[outlineView beginUpdates];
	for (SynSession *newSession in newSessions)	{
		[outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:self.sessions.count + WATCH_SESSIONS_COUNT] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
		[self.sessions addObject:newSession];
	}
	[outlineView endUpdates];
	
	for (SynSession *newSession in newSessions)	{
		if (newSession.type == SessionType_List)	{
			self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
			[outlineView expandItem:newSession expandChildren:NO];
		}
	}
	
	//	reload the table view
	//[self reloadData];
	
	//	enable/disable the run-pause button based on the number of active ops
	[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
}
- (void) appendWatchFolderSessions:(NSArray<SynSession*> *)n	{
	if (n == nil || [n count]<1)
		return;
	[self.watchFolderSessions addObjectsFromArray:n];
	
	//	reload the table view
	[self reloadData];
}


- (void) reloadData	{
	NSInteger		selectedRow = [outlineView selectedRow];
	id				tmpObj = (selectedRow==NSNotFound || selectedRow<0) ? nil : [outlineView itemAtRow:selectedRow];
	
	[outlineView reloadData];
	[self restoreExpandStates];
	
	if (tmpObj != nil)	{
		NSInteger		newSelectedRow = [outlineView rowForItem:tmpObj];
		if (newSelectedRow != NSNotFound && newSelectedRow >= 0)
			[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow] byExtendingSelection:NO];
	}
	
	[self outlineViewSelectionDidChange:nil];
}
- (void) reloadRowForItem:(id)n	{
	if (n == nil)
		return;
	if ([n isKindOfClass:[SynOp class]])	{
		NSInteger			rowIndex = [outlineView rowForItem:n];
		if (rowIndex >= 0)	{
			OpRowView			*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			if (tmpView != nil)
				[tmpView refreshUI];
		}
	}
	else if ([n isKindOfClass:[SynSession class]])	{
		NSInteger			rowIndex = [outlineView rowForItem:n];
		if (rowIndex >= 0)	{
			SessionRowView		*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			if (tmpView != nil)
				[tmpView refreshUI];
		}
	}
}
- (void) restoreExpandStates	{
	NSInteger		tmpRow = 0;
	while (1)	{
		id				tmpObj = [outlineView itemAtRow:tmpRow];
		if (tmpObj == nil)
			break;
		if ([tmpObj isKindOfClass:[SynSession class]])	{
			SynSession		*tmpSession = (SynSession *)tmpObj;
			if (tmpSession.dragUUID != nil)	{
				NSNumber		*tmpNum = self.expandStateDict[tmpSession.dragUUID.UUIDString];
				if (tmpNum != nil && [tmpNum boolValue])	{
					[outlineView expandItem:tmpObj expandChildren:NO];
				}
			}
		}
		++tmpRow;
	}
}


#pragma mark - SynOpDelegate protocol


- (void) synOpStatusFinished:(SynOp *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	//BOOL			opFinished = NO;
	BOOL			startAnotherOp = NO;
 	@synchronized (self)	{
		
		switch (n.status)	{
		case OpStatus_Pending:
		case OpStatus_Analyze:
		case OpStatus_Cleanup:
		case OpStatus_Preflight:
			//	intentionally blank, should probably never occur
			break;
		case OpStatus_PreflightErr:
			[LogController appendErrorLog:[NSString stringWithFormat:@"Pre-flight error on file %@: %@",n.src.lastPathComponent,n.errString]];
			break;
		case OpStatus_Complete:
			[LogController appendSuccessLog:[NSString stringWithFormat:@"Finished processing file %@",n.src.lastPathComponent]];
			break;
		case OpStatus_Err:
			[LogController appendErrorLog:[NSString stringWithFormat:@"Error processing file %@: %@",n.src.lastPathComponent,n.errString]];
			break;
		}
		//NSLog(@"\tbefore, opsInProgress was %@",self.opsInProgress);
		[self.opsInProgress removeObjectIdenticalTo:n];
		//NSLog(@"\tafter, opsInProgress was %@",self.opsInProgress);
		
		//	if we just finished an op, we may want to start another?
		if (self.running && self.opsInProgress.count < [self maxOpCount])	{
			startAnotherOp = YES;
		}
		
		//	if we want to start another op...
		if (startAnotherOp)	{
			//	only start another op if we're not paused!
			if (!self.paused)	{
				//NSArray<SynOp*>		*opsToStart = [self getOpsToStart:1];
				[self makeSureRunningMaxPossibleOps];
			}
		}
	}
	
	//	tell the session to post a notification if appropriate
	[n.session fireNotificationIfAppropriate];
	
	//	if we have no more ops, stop!
	if (self.opsInProgress.count < 1)
		[self stop];
	//	else we have more ops in progress...
	else	{
		//	refresh the UI for the op that completed
		NSInteger			rowIndex;
		rowIndex = [outlineView rowForItem:n];
		if (rowIndex >= 0)	{
			OpRowView			*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			//NSLog(@"\top row view is %@",tmpView);
			if (tmpView != nil)
				[tmpView refreshUI];
		}
		//	refresh the UI for the session that owns the op that completed
		rowIndex = (n.session==nil) ? -1 : [outlineView rowForItem:n.session];
		if (rowIndex >= 0)	{
			SessionRowView		*tmpView = [outlineView viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
			if (tmpView != nil)
				[tmpView refreshUI];
		}
		
	}
	
	//	if the session that owns this op is inspected, we may need to reload the inspector now...
	[[InspectorViewController global] reloadInspectorIfInspected:n.session];
}


#pragma mark - DropFileHelper


- (void) analysisSessionForFiles:(NSArray *)fileURLArray sessionCompletionBlock:(void (^)(void))completionBlock {
	//NSLog(@"%s ... %@",__func__,fileURLArray);
	[self createAndAppendSessionsWithFiles:fileURLArray];
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
		return TOTAL_SESSIONS_COUNT;
	}
	
	if ([item isKindOfClass:[SynSession class]])	{
		return [[(SynSession*)item ops] count];
	}
	
	return 0;
}
- (id) outlineView:(NSOutlineView *)ov child:(NSInteger)index ofItem:(id)item	{
	//NSLog(@"%s ... %d, %@",__func__,index,item);
	if (item == nil)	{
		if (index>=0 && index<TOTAL_SESSIONS_COUNT)	{
			if (index < WATCH_SESSIONS_COUNT)
				return self.watchFolderSessions[index];
			else
				return self.sessions[index - WATCH_SESSIONS_COUNT];
		}
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
		//if (recast.type == SessionType_Dir)
		//	return NO;
		//else
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
	NSInteger		selectedRow = [outlineView selectedRow];
	if (selectedRow == -1)
		[[InspectorViewController global] uninspectAll];
	else	{
		id				tmpObj = [outlineView itemAtRow:selectedRow];
		[[InspectorViewController global] inspectItem:tmpObj];
	}
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item	{
	if (!self.dragInProgress)	{
		if (item!=nil && [item isKindOfClass:[SynSession class]])	{
			SynSession		*tmpSession = (SynSession *)item;
			if (tmpSession.dragUUID != nil)
				self.expandStateDict[tmpSession.dragUUID.UUIDString] = @YES;
		}
	}
	
	return YES;
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item	{
	if (!self.dragInProgress)	{
		if (item!=nil && [item isKindOfClass:[SynSession class]])	{
			SynSession		*tmpSession = (SynSession *)item;
			if (tmpSession.dragUUID != nil)
				[self.expandStateDict removeObjectForKey:tmpSession.dragUUID.UUIDString];
		}
	}
	
	return YES;
}
- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	
	//if (self.running)
	//	return NO;
	
	/*
	if ([item isKindOfClass:[SynOp class]])
		return YES;
	
	//	don't allow the user to inspect any sessions that are currently running any jobs
	if ([item isKindOfClass:[SynSession class]])	{
		SynSession		*recast = (SynSession *)item;
		if ([self processingFilesFromSession:recast])
			return NO;
		return YES;
	}
	*/
	
	return YES;
}


- (BOOL) outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard*)pboard	{
	//NSLog(@"%s ... %@",__func__,items);
	
	if (items==nil || [items count]!=1)
		return NO;
	id				tmpItem = items[0];
	if ([tmpItem isKindOfClass:[SynSession class]])	{
		SynSession		*recast = (SynSession*)tmpItem;
		[pboard setString:recast.dragUUID.UUIDString forType:localFileDragType];
	}
	else if ([tmpItem isKindOfClass:[SynOp class]])	{
		SynOp			*recast = (SynOp*)tmpItem;
		//	prevent the drag if the op's parent is a dir-type session...
		if (recast.session.type == SessionType_Dir)
			return NO;
		
		[pboard setString:recast.dragUUID.UUIDString forType:localFileDragType];
	}
	
	return YES;
}
- (NSDragOperation) outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)rawDropItem proposedChildIndex:(int)dropIndex	{
	NSPasteboard		*pboard = [info draggingPasteboard];
	
	@synchronized (self)	{
	
		self.dragInProgress = YES;
	
		//	if it's a drag from the finder...
		if ([pboard availableTypeFromArray:@[ NSPasteboardTypeFileURL ]])	{
			//	nil item means dropping into an unspecified session...
			if (rawDropItem == nil)	{
				if (dropIndex < WATCH_SESSIONS_COUNT)
					[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
				return NSDragOperationGeneric;
			}
			//	if we're dropping on a session at a given index...
			else if ([rawDropItem isKindOfClass:[SynSession class]])	{
				SynSession		*tmpSession = (SynSession *)rawDropItem;
				//	if we're dropping on a watch folder...
				if (tmpSession.watchFolder)	{
					[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
					return NSDragOperationGeneric;
				}
				//	else if we're dropping on a dir-typ session, or a session with ops that are currently being processed...
				else if (tmpSession.type == SessionType_Dir || [self processingFilesFromSession:tmpSession])	{
					//	retarget to one after the index of this session
					NSInteger			dropItemIndex = [self.sessions indexOfObjectIdenticalTo:tmpSession];
					if (dropItemIndex == NSNotFound || dropItemIndex < 0)
						dropItemIndex = -1;
					else
						dropItemIndex = dropItemIndex + 1 + WATCH_SESSIONS_COUNT;
					[ov setDropItem:nil dropChildIndex:dropItemIndex];
					return NSDragOperationGeneric;
				}
				else	{
					return NSDragOperationGeneric;
				}
			}
			//	else if we're dropping on an op...
			else if ([rawDropItem isKindOfClass:[SynOp class]])	{
				SynSession		*parentSession = [(SynOp *)rawDropItem session];
				//	if the parent session is a watch folder, retarget
				if (parentSession.watchFolder)	{
					[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
					return NSDragOperationGeneric;
				}
				//	else if the parent session is a dir-typ session or has ops that are currently being processed, retarget
				else if (parentSession.type == SessionType_Dir || [self processingFilesFromSession:parentSession])	{
					NSInteger			dropItemIndex = [self.sessions indexOfObjectIdenticalTo:parentSession];
					if (dropItemIndex == NSNotFound || dropItemIndex < 0)
						dropItemIndex = -1;
					else
						dropItemIndex = dropItemIndex + 1 + WATCH_SESSIONS_COUNT;
					[ov setDropItem:nil dropChildIndex:dropItemIndex];
					return NSDragOperationGeneric;
				}
				//	else we're dropping on an op in a session we can add to
				else	{
					NSInteger			dropItemIndex = [[parentSession ops] indexOfObjectIdenticalTo:rawDropItem];
					if (dropItemIndex == NSNotFound || dropItemIndex < 0)
						dropItemIndex = -1;
					else
						dropItemIndex = dropItemIndex + 1;
					[ov setDropItem:parentSession dropChildIndex:dropItemIndex];
					return NSDragOperationGeneric;
				}
			}
		}
		//	else if it's a drag from within the outline view (re-ordering)...
		else if ([pboard availableTypeFromArray:@[ localFileDragType ]])	{
			//	get the item we're dragging from the pboard- sessions and ops have different drop requirements
			NSString		*tmpString = [pboard stringForType:localFileDragType];
			NSUUID			*tmpUUID = (tmpString==nil) ? nil : [[NSUUID alloc] initWithUUIDString:tmpString];
			id				rawDragItem = [self objectForUUID:tmpUUID];
			if (rawDragItem == nil)
				return NSDragOperationNone;
			else if ([rawDragItem isKindOfClass:[SynSession class]])	{
				SynSession		*dragItem = (SynSession *)rawDragItem;
				//	if the drag item is a watch folder session, we need to restrict its drop to within the list of watch folders
				if (dragItem.watchFolder)	{
					//	if 'rawDropItem' is nil we're dropping onto the master list of sessions
					if (rawDropItem == nil)	{
						//	make sure we aren't dragging past the last want index...
						if (dropIndex > WATCH_SESSIONS_COUNT)
							[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
						return NSDragOperationGeneric;
					}
					//	else if we're trying to drag into a session...
					else if ([rawDropItem isKindOfClass:[SynSession class]])	{
						SynSession			*dropItem = (SynSession *)rawDropItem;
						//	change the drop target to one index after the drop item's index (we can't drag a session into another session)
						//	...note that we're only checking for the drop item in the array of watch folders (watch folders are pinned to the top of the list)
						NSInteger			dropItemIndex = [self.watchFolderSessions indexOfObjectIdenticalTo:dropItem];
						if (dropItemIndex == NSNotFound || dropItemIndex < 0)
							dropItemIndex = WATCH_SESSIONS_COUNT;
						else
							++dropItemIndex;
						[ov setDropItem:nil dropChildIndex:dropItemIndex];
						return NSDragOperationGeneric;
					}
					//	else if we're trying to drag into an op...
					else if ([rawDropItem isKindOfClass:[SynOp class]])	{
						SynOp				*dropItem = (SynOp*)rawDropItem;
						//	if the op belongs to a watch folder session, change the drop target to one after that session
						if (dropItem.session != nil && dropItem.session.watchFolder)	{
							NSInteger			parentSessionIndex = [self.watchFolderSessions indexOfObjectIdenticalTo:dropItem.session];
							if (parentSessionIndex == NSNotFound || parentSessionIndex < 0)
								parentSessionIndex = WATCH_SESSIONS_COUNT;
							else
								++parentSessionIndex;
							[ov setDropItem:nil dropChildIndex:parentSessionIndex];
							return NSDragOperationGeneric;
						}
						//	else the op doesn't belong to a watch folder session- change the drop target to the last watch folder session
						else	{
							[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
							return NSDragOperationGeneric;
						}
					}
				}
				//	else the drag item is *not* a watch folder- we need to restrict its drop to within the list of non-watch folders
				else	{
					//	if 'rawDropItem' is nil we're dropping onto the master list of sessions
					if (rawDropItem == nil)	{
						//	if we're trying to drop somewhere in the list of watch folders, make sure we're dropping after the last watch folder
						if (dropIndex < WATCH_SESSIONS_COUNT)	{
							[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
							return NSDragOperationGeneric;
						}
						else
							return NSDragOperationGeneric;
					}
					//	else we're trying to drag into a session...
					else if ([rawDropItem isKindOfClass:[SynSession class]])	{
						SynSession		*dropItem = (SynSession *)rawDropItem;
						//	if we're trying to drag into a watch-folder session
						if (dropItem.watchFolder)	{
							//	retarget to after the last watch folder session
							[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
							return NSDragOperationGeneric;
						}
						//	else...we're trying to drag into a dir-type or list-type session (basically, not a watch folder)
						else	{
							//	retarget to one after the session we're trying to drop onto
							SynSession		*dropItem = (SynSession *)rawDropItem;
							//	change the drop target to one index after the parent session's index (we can't drag a session into antoher session)
							NSInteger		dropItemIndex = [self.sessions indexOfObjectIdenticalTo:dropItem];
							if (dropItemIndex == NSNotFound || dropItemIndex < 0)
								dropItemIndex = self.sessions.count;
							else
								++dropItemIndex;
							[ov setDropItem:nil dropChildIndex:dropItemIndex + WATCH_SESSIONS_COUNT];
							return NSDragOperationGeneric;
						}
					}
					//	else we're trying to drag into an op...
					else if ([rawDropItem isKindOfClass:[SynOp class]])	{
						SynOp			*dropItem = (SynOp *)rawDropItem;
						//	if the op's session is a watch folder...
						if (dropItem.session != nil && dropItem.session.watchFolder)	{
							//	retarget so the drop is right after the list of watch folders (between sessions)
							[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
							return NSDragOperationGeneric;
						}
						//	else if the op's session is any other kind of session (basically, not a watch folder)
						else if (dropItem.session != nil)	{
							//	retarget so the drop is right after the current drop target's parent session (between sessions)
							NSInteger			dropItemParentSessionIndex = [self.sessions indexOfObjectIdenticalTo:dropItem.session];
							if (dropItemParentSessionIndex == NSNotFound || dropItemParentSessionIndex < 0)
								dropItemParentSessionIndex = -1;
							else
								dropItemParentSessionIndex = dropItemParentSessionIndex + 1 + WATCH_SESSIONS_COUNT;
							[ov setDropItem:nil dropChildIndex:dropItemParentSessionIndex];
							return NSDragOperationGeneric;
						}
						//	else...indeterminate
						else	{
						}
					}
				}
			}
			else if ([rawDragItem isKindOfClass:[SynOp class]])	{
				//SynOp			*dragItem = (SynOp *)rawDragItem;
				//	if 'rawDropItem is nil we're dropping onto the master list of sessions
				if (rawDropItem == nil)	{
					//	if the drop index is somewhere upin the list of watch folders, change the drop target
					if (dropIndex < WATCH_SESSIONS_COUNT)	{
						[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
						return NSDragOperationGeneric;
					}
					else	{
						//	do nothing (this is how you create another session)
						return NSDragOperationGeneric;
					}
				}
				//	else we're trying to drag an op into a session...
				else if ([rawDropItem isKindOfClass:[SynSession class]])	{
					SynSession			*dropItem = (SynSession *)rawDropItem;
					//	if we're trying to drop it onto a watch folder
					if (dropItem.watchFolder)	{
						//	retarget so the drop is right after the list of watch folders (between sessions)
						[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
						return NSDragOperationGeneric;
					}
					//	else if we're trying to drop it onto a dir-type session or a session with ops that are currently being processed
					else if (dropItem.type == SessionType_Dir || [self processingFilesFromSession:dropItem])	{
						//	retarget so the drop is right after the current drop target (between sessions)
						NSInteger		dropSessionIndex = [self.sessions indexOfObjectIdenticalTo:dropItem];
						if (dropSessionIndex == NSNotFound || dropSessionIndex < 0)
							dropSessionIndex = -1;
						else
							dropSessionIndex = dropSessionIndex + 1 + WATCH_SESSIONS_COUNT;
						[ov setDropItem:nil dropChildIndex:dropSessionIndex];
						return NSDragOperationGeneric;
					}
					//	else...we're trying to drop it onto a file-type session
					else	{
						//	do nothing (we're good)
						return NSDragOperationGeneric;
					}
				
				}
				//	else we're trying to drag an op into another op...
				else if ([rawDropItem isKindOfClass:[SynOp class]])	{
					SynOp				*dropItem = (SynOp*)rawDropItem;
					//	if the op's session is a watch folder...
					if (dropItem.session != nil && dropItem.session.watchFolder)	{
						//	retarget so the drop is right after the list of watch folders (between sessions)
						[ov setDropItem:nil dropChildIndex:WATCH_SESSIONS_COUNT];
						return NSDragOperationGeneric;
					}
					//	else if the op's session is a dir-type folder, or a session with ops that are currently being processed...
					else if (dropItem.session != nil && (dropItem.session.type == SessionType_Dir || [self processingFilesFromSession:dropItem.session]))	{
						//	retarget so the drop is right after the current drop target's parent session (between sessions)
						NSInteger			dropItemParentSessionIndex = [self.sessions indexOfObjectIdenticalTo:dropItem.session];
						if (dropItemParentSessionIndex == NSNotFound || dropItemParentSessionIndex < 0)
							dropItemParentSessionIndex = -1;
						else
							dropItemParentSessionIndex = dropItemParentSessionIndex + 1 + WATCH_SESSIONS_COUNT;
						[ov setDropItem:nil dropChildIndex:dropItemParentSessionIndex];
						return NSDragOperationGeneric;
					}
					//	else if the op's session is a file-type folder
					else if (dropItem.session != nil && dropItem.session.type == SessionType_List)	{
						SynOp			*dropItem = (SynOp *)rawDropItem;
						SynSession		*dropItemSession = dropItem.session;
						NSInteger		dropItemIndex = [dropItemSession.ops indexOfObjectIdenticalTo:dropItem];
						if (dropItemIndex == NSNotFound || dropItemIndex < 0)
							dropItemIndex = dropItemSession.ops.count;
						[ov setDropItem:dropItemSession dropChildIndex:dropItemIndex];
						return NSDragOperationGeneric;
					}
					//	else...indeterminate
					else	{
					}
				}
			}
			return NSDragOperationNone;
		}
	
	}
	
	return NSDragOperationNone;
}
- (BOOL) outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)rawDropItem childIndex:(int)rawDropIndex	{
	//NSLog(@"%s ... %@, %d",__func__,rawDropItem,rawDropIndex);
	NSPasteboard		*pboard = [info draggingPasteboard];
	
	//	lock while we're doing all this, we don't want to get the rug pulled out from under us...
	@synchronized (self)	{
		self.dragInProgress = NO;
	
		if ([pboard availableTypeFromArray:@[ NSPasteboardTypeFileURL ]])	{
			//	assemble a list of URLs from the pasteboard
			NSMutableArray		*fileURLs = [NSMutableArray arrayWithCapacity:0];
			for (NSPasteboardItem * item in [pboard pasteboardItems])	{
				if ([item availableTypeFromArray:@[ NSPasteboardTypeFileURL ]])	{
					NSURL				*tmpURL = [[NSURL URLWithString:[item propertyListForType:NSPasteboardTypeFileURL]] filePathURL];
					NSString			*tmpPath = (tmpURL==nil) ? nil : [tmpURL path];
					if (tmpPath != nil)
						[fileURLs addObject:[NSURL fileURLWithPath:tmpPath]];
				}
			}
		
			//	if the drop target's nil, we're making a new session for these URLs
			if (rawDropItem == nil)	{
				//	if the rawDropIndex is -1, this is very simple
				if (rawDropIndex == -1)	{
					//[self createAndAppendSessionsWithFiles:fileURLs];
					NSArray			*newSessions = [self createSessionsWithFiles:fileURLs];
					NSMutableIndexSet		*newIndexes = [[NSMutableIndexSet alloc] init];
					for (SynSession *newSession in newSessions)	{
						if (newSession.type == SessionType_List)
							self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
						[newIndexes addIndex:WATCH_SESSIONS_COUNT + self.sessions.count];
						[self.sessions addObject:newSession];
					}
					[outlineView beginUpdates];
					[outlineView insertItemsAtIndexes:newIndexes inParent:nil withAnimation:NSTableViewAnimationSlideDown];
					[outlineView endUpdates];
					
					for (SynSession *newSession in newSessions)	{
						if (newSession.type == SessionType_List)
							[outlineView expandItem:newSession expandChildren:NO];
					}
					
					//	enable/disable the run-pause button based on the number of active ops
					[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
					
					return YES;
				}
				//	...if we're here, we're inserting a drop into our list of sessions (not dropping inside a session, but into the list of sessions)
				NSArray<SynSession*>	*newSessions = [self createSessionsWithFiles:fileURLs];
				NSMutableIndexSet		*newIndexes = [[NSMutableIndexSet alloc] init];
				//	if the rawDropIndex is -1, we want to append to the end of all sessions
				NSInteger				targetIndex = (rawDropIndex==-1) ? self.sessions.count : rawDropIndex - WATCH_SESSIONS_COUNT;
				for (SynSession *newSession in newSessions)	{
					if (newSession.type == SessionType_List)
						self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
					[self.sessions insertObject:newSession atIndex:targetIndex];
					[newIndexes addIndex:WATCH_SESSIONS_COUNT + targetIndex];
					++targetIndex;
				}
				[outlineView beginUpdates];
				[outlineView insertItemsAtIndexes:newIndexes inParent:nil withAnimation:NSTableViewAnimationSlideDown];
				[outlineView endUpdates];
				
				for (SynSession *newSession in newSessions)	{
					if (newSession.type == SessionType_List)
						[outlineView expandItem:newSession expandChildren:NO];
				}
				
				//	reload the outline view!
				//[self reloadData];
				//	re-evaluate the selection...
				[self outlineViewSelectionDidChange:nil];
				
				//	enable/disable the run-pause button based on the number of active ops
				[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
				return YES;
			}
			//	else if we're dropping into an existing session (dropping inside a session)
			else if ([rawDropItem isKindOfClass:[SynSession class]])	{
				SynSession		*targetSession = (SynSession *)rawDropItem;
				//	if the session we're dropping into has ops that are currently being processed...
				if ([self processingFilesFromSession:targetSession])	{
					//	make a new session with the target session's settings and insert it immediately after the target session
					NSInteger		targetSessionIndex = [self.sessions indexOfObjectIdenticalTo:targetSession];
					if (targetSessionIndex == NSNotFound || targetSessionIndex < 0)
						targetSessionIndex = SESSIONS_COUNT;
					else
						++targetSessionIndex;
					NSArray			*newSessions = [self createSessionsWithFiles:fileURLs];
					NSMutableIndexSet		*newIndexes = [[NSMutableIndexSet alloc] init];
					for (SynSession *newSession in newSessions)	{
						newSession.srcDir = targetSession.srcDir;
						newSession.outputDir = targetSession.outputDir;
						newSession.tempDir = targetSession.tempDir;
						newSession.opScript = targetSession.opScript;
						newSession.sessionScript = targetSession.sessionScript;
						newSession.preset = targetSession.preset;
						newSession.copyNonMediaFiles = targetSession.copyNonMediaFiles;
						newSession.type = targetSession.type;
						newSession.state = targetSession.state;
						[self.sessions insertObject:newSession atIndex:targetSessionIndex];
						[newIndexes addIndex:WATCH_SESSIONS_COUNT + targetSessionIndex];
						++targetSessionIndex;
						
						if (newSession.type == SessionType_List)
							self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
					}
					[outlineView beginUpdates];
					[outlineView insertItemsAtIndexes:newIndexes inParent:nil withAnimation:NSTableViewAnimationSlideDown];
					[outlineView endUpdates];
					
					for (SynSession *newSession in newSessions)	{
						if (newSession.type == SessionType_List)
							[outlineView expandItem:newSession expandChildren:NO];
					}
					
					//	reload the outline view!
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					
					//	enable/disable the run-pause button based on the number of active ops
					[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
					return YES;
				}
				//	else the session we're dropping into isn't processing any ops- we're clear to add to it
				else	{
					//	if the rawDropIndex is -1, we want to append to the end of the session's ops
					NSMutableIndexSet		*newOpIndexes = [[NSMutableIndexSet alloc] init];
					NSMutableIndexSet		*newSessionIndexes = [[NSMutableIndexSet alloc] init];
					NSInteger		targetIndex = (rawDropIndex==-1) ? targetSession.ops.count : rawDropIndex;
					for (NSURL *fileURL in fileURLs)	{
						SynOp			*tmpOp = [[SynOp alloc] initWithSrcURL:fileURL];
						//	only insert the op if it's an AVF file OR its parent session is copying non-media files
						if (tmpOp != nil && (tmpOp.type == OpType_AVFFile || targetSession.copyNonMediaFiles))	{
							self.expandStateDict[targetSession.dragUUID.UUIDString] = @YES;
							[targetSession.ops insertObject:tmpOp atIndex:targetIndex];
							[newOpIndexes addIndex:targetIndex];
							tmpOp.session = targetSession;
							++targetIndex;
						}
						//	else if the op is nil...
						else if (tmpOp == nil)	{
							//	did we try to make an op from a directory (which should be a session)?
							NSArray<SynSession*>	*tmpSessions = [self createSessionsWithFiles:@[fileURL]];
							for (SynSession *tmpSession in tmpSessions)	{
								[newSessionIndexes addIndex:WATCH_SESSIONS_COUNT + self.sessions.count];
								[self.sessions addObject:tmpSession];
							}
						}
					}
					[outlineView beginUpdates];
					if (newOpIndexes.count > 0)
						[outlineView insertItemsAtIndexes:newOpIndexes inParent:targetSession withAnimation:NSTableViewAnimationSlideDown];
					if (newSessionIndexes.count > 0)
						[outlineView insertItemsAtIndexes:newSessionIndexes inParent:nil withAnimation:NSTableViewAnimationSlideDown];
					[outlineView endUpdates];
					
					[outlineView expandItem:targetSession expandChildren:NO];
					
					//	reload the row of the item we just dropped stuff into
					[self reloadRowForItem:targetSession];
					
					//	reload the outline view!
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					
					//	enable/disable the run-pause button based on the number of active ops
					[runPauseButton setEnabled:([self numberOfFilesToProcess]<1) ? NO : YES];
					return YES;
				}
			}
		}
		else if ([pboard availableTypeFromArray:@[ localFileDragType ]])	{
			//	get the item we're dragging from the pboard- sessions and ops have different drop requirements
			NSString		*tmpString = [pboard stringForType:localFileDragType];
			NSUUID			*tmpUUID = (tmpString==nil) ? nil : [[NSUUID alloc] initWithUUIDString:tmpString];
			id				rawDragItem = [self objectForUUID:tmpUUID];
			if (rawDragItem == nil)
				return NO;
			else if ([rawDragItem isKindOfClass:[SynSession class]])	{
				SynSession		*dragItem = (SynSession *)rawDragItem;
				if (dragItem.watchFolder)	{
					NSInteger		dragItemOrigIndex = [self.watchFolderSessions indexOfObjectIdenticalTo:dragItem];
					NSInteger		dropIndex = rawDropIndex;
					NSInteger		viewDropIndex = dropIndex;
					//	if the drop index hasn't changed, do nothing and return
					if (dragItemOrigIndex == dropIndex)	{
						//	intentionally blank (technically we could probably skip the reloadData but whatevs)
					}
					//	else if the drop index is > the orig index, insert first and then delete
					else if (dropIndex > dragItemOrigIndex)	{
						--viewDropIndex;
						[self.watchFolderSessions insertObject:dragItem atIndex:dropIndex];
						[self.watchFolderSessions removeObjectAtIndex:dragItemOrigIndex];
					}
					//	else the drop index is < the orig index, delete first then insert
					else	{
						[self.watchFolderSessions removeObjectAtIndex:dragItemOrigIndex];
						[self.watchFolderSessions insertObject:dragItem atIndex:dropIndex];
					}
					[outlineView beginUpdates];
					[outlineView moveItemAtIndex:dragItemOrigIndex inParent:nil toIndex:viewDropIndex inParent:nil];
					[outlineView endUpdates];
					//	reload the outline view
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					return YES;
				}
				else	{
					NSInteger		dragItemOrigIndex = [self.sessions indexOfObjectIdenticalTo:dragItem];
					NSInteger		dropIndex = (rawDropIndex == -1) ? SESSIONS_COUNT : rawDropIndex - WATCH_SESSIONS_COUNT;
					NSInteger		viewDropIndex = dropIndex;
					//	if the dropIndex == orig index, do nothing and return
					if (dropIndex == dragItemOrigIndex)	{
						//	intentionally blank (technically we could probably skip the reloadData but whatevs)
					}
					//	else if the dropIndex is > the orig index, insert first and then delete
					else if (dropIndex > dragItemOrigIndex)	{
						--viewDropIndex;
						[self.sessions insertObject:dragItem atIndex:dropIndex];
						[self.sessions removeObjectAtIndex:dragItemOrigIndex];
					}
					//	else the dropIndex is < the orig index, delete first then insert
					else	{
						[self.sessions removeObjectAtIndex:dragItemOrigIndex];
						[self.sessions insertObject:dragItem atIndex:dropIndex];
					}
					[outlineView beginUpdates];
					[outlineView moveItemAtIndex:WATCH_SESSIONS_COUNT + dragItemOrigIndex inParent:nil toIndex:WATCH_SESSIONS_COUNT + viewDropIndex inParent:nil];
					[outlineView endUpdates];
					//	reload the outline view
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					return YES;
				}
				//	...the drop item should always be 'nil' (we set it to such during the validate call above)
				return NO;
			}
			else if ([rawDragItem isKindOfClass:[SynOp class]])	{
				SynOp			*dragItem = (SynOp *)rawDragItem;
				SynSession		*dragItemParent = dragItem.session;
				NSInteger		dragItemOrigIndex = [dragItemParent.ops indexOfObjectIdenticalTo:dragItem];
				//	if we're dropping the op into a nil item...
				if (rawDropItem == nil)	{
					[outlineView beginUpdates];
					
					//	create a new session, add the op to it, insert the session and the drop index
					SynSession		*newSession = [SynSession createWithFiles:@[]];
					NSInteger		dropIndex = (rawDropIndex==-1) ? SESSIONS_COUNT : rawDropIndex - WATCH_SESSIONS_COUNT;
					[newSession.ops addObject:dragItem];
					[dragItem setSession:newSession];
					[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
					[self.sessions insertObject:newSession atIndex:dropIndex];
					//	tell the outline view to insert a row for the new session...
					[outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:WATCH_SESSIONS_COUNT + dropIndex] inParent:nil withAnimation:NSTableViewAnimationSlideDown];
				
					//	if the parent session is now empty, remove it
					if (dragItemParent.ops.count < 1)	{
						NSInteger			origParentIndex = [self.sessions indexOfObjectIdenticalTo:dragItemParent];
						[self.sessions removeObjectIdenticalTo:dragItemParent];
						if (origParentIndex != NSNotFound && origParentIndex >= 0)	{
							//	move the item out of the old session into the new session
							[outlineView moveItemAtIndex:dragItemOrigIndex inParent:dragItemParent toIndex:0 inParent:newSession];
							//	remove the row for the old session
							[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:WATCH_SESSIONS_COUNT + origParentIndex] inParent:nil withAnimation:NSTableViewAnimationSlideUp];
						}
					}
					//	else we're moving the item from one parent to another
					else	{
						[outlineView moveItemAtIndex:dragItemOrigIndex inParent:dragItemParent toIndex:0 inParent:newSession];
					}
				
					//	this will cause the session we just created to be expanded when the outline view is reloaded...
					self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
					
					[outlineView endUpdates];
					
					[outlineView expandItem:newSession expandChildren:NO];
					
					//	reload the op we dragged stuff from
					[self reloadRowForItem:dragItemParent];
					
					//	reload the outline view...
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					return YES;
				}
				//	else if we're dropping the op into a session...
				else if ([rawDropItem isKindOfClass:[SynSession class]])	{
					SynSession		*dropItem = (SynSession *)rawDropItem;
					//	if the drop item currently has ops that are being processed, cancel the drag!
					if ([self processingFilesFromSession:dropItem])	{
						return NO;
					}
					
					NSInteger		actualDropIndex = (rawDropIndex==-1) ? dropItem.ops.count : rawDropIndex;
					NSInteger		viewDropIndex = actualDropIndex;
					//	if the drop index == orig index...
					if (rawDropIndex == dragItemOrigIndex)	{
						//	if it's the same session, do nothing
						if (dragItemParent == dropItem)	{
							//	intentionally blank
						}
						//	else insert first, then delete
						else	{
							[dropItem.ops insertObject:dragItem atIndex:actualDropIndex];
							[dragItem setSession:dropItem];
							[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
						}
					}
					//	else if the drop index is > the orig index, insert first and then delete
					else if (rawDropIndex > dragItemOrigIndex)	{
						if (dragItemParent == dropItem)
							--viewDropIndex;
						[dropItem.ops insertObject:dragItem atIndex:actualDropIndex];
						[dragItem setSession:dropItem];
						[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
					}
					//	else the drop index is < the orig index, delete first then insert
					else	{
						[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
						[dropItem.ops insertObject:dragItem atIndex:actualDropIndex];
						[dragItem setSession:dropItem];
					}
				
					[outlineView beginUpdates];
					
					[outlineView moveItemAtIndex:dragItemOrigIndex inParent:dragItemParent toIndex:viewDropIndex inParent:dropItem];
					
					//	if the parent session is now empty, remove it
					if (dragItemParent.ops.count < 1)	{
						NSInteger		viewRemoveIndex = [self.sessions indexOfObjectIdenticalTo:dragItemParent] + WATCH_SESSIONS_COUNT;
						if (viewRemoveIndex != NSNotFound && viewRemoveIndex >= 0)
							[outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:viewRemoveIndex] inParent:nil withAnimation:NSTableViewAnimationSlideUp];
						[self.sessions removeObjectIdenticalTo:dragItemParent];
					}
					
					[outlineView endUpdates];
					
					//	reload the op we dragged stuff from and the row we drpoped stuff into
					[self reloadRowForItem:dragItemParent];
					[self reloadRowForItem:dropItem];
					
					//	reload the outline view
					//[self reloadData];
					//	re-evaluate the selection...
					[self outlineViewSelectionDidChange:nil];
					return YES;
				}
				else if ([rawDropItem isKindOfClass:[SynOp class]])	{
					//	this should never happen (validate should prevent it
					return NO;
				}
			}
		}
	
	}
	
	return NO;
	
}
- (void) draggingExited:(id<NSDraggingInfo>)info	{
	//NSLog(@"%s",__func__);
	self.dragInProgress = NO;
}


@end











