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
@property (strong) NSMutableArray<SynSession*> * sessions;

@property (strong,nullable) NSTimer * progressRefreshTimer;
@property (strong) NSMutableArray<SynOp*> * opsInProgress;
@property (atomic,readwrite) BOOL running;
@property (strong,readwrite,atomic) NSMutableDictionary * expandStateDict;

@property (atomic,strong,readwrite,nullable) id appNapToken;

@property (atomic,readwrite) BOOL wokeUpOnce;	//	'awakeFromNib' is called every time we pull a view out of the table- we only want to call its contents once...

//- (void) startAnOp;
- (NSArray<SynOp*> *) getOpsToStart:(NSUInteger)numOpsToGet;
- (int) maxOpCount;
- (id) objectForUUID:(NSUUID *)n;
- (void) restoreExpandStates;
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
	self.running = NO;
	self.expandStateDict = [NSMutableDictionary dictionaryWithCapacity:0];
	
	//	make an app nap token right away- we can't nap b/c we're either transcoding/analyzing, or potentially watching a directory for changes to its files!
	self.appNapToken = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated | NSActivityLatencyCritical reason:@"Analyzing"];
	
	self.wokeUpOnce = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	//[self window];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	if (!self.wokeUpOnce)	{
		//[dropView setDragDelegate:self];
		outlineView.outlineTableColumn = theColumn;
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
		NSData				*tmpData = [def objectForKey:@"sessions"];
		if (tmpData != nil && [tmpData isKindOfClass:[NSData class]])	{
			NSArray				*tmpArray = [NSKeyedUnarchiver unarchiveObjectWithData:tmpData];
			if (tmpArray != nil && [tmpArray isKindOfClass:[NSArray class]] && [tmpArray count] > 0)	{
				for (SynSession		*tmpSession in tmpArray)	{
					if ([tmpSession isKindOfClass:[SynSession class]])	{
						[self.sessions addObject:tmpSession];
						if (tmpSession.type == SessionType_List)
							self.expandStateDict[tmpSession.dragUUID.UUIDString] = @YES;
					}
				}
				[self reloadData];
			}
		}
	}
}
- (void) applicationWillTerminate:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		NSData				*encodedSessions = nil;
		NSMutableArray		*sessionsToSave = [NSMutableArray arrayWithCapacity:0];
		for (SynSession *session in self.sessions)	{
			if ([session opsToSave] != nil || session.type == SessionType_Dir)	{
				[sessionsToSave addObject:session];
			}
		}
		if (sessionsToSave != nil && [sessionsToSave count] > 0)	{
			encodedSessions = [NSKeyedArchiver archivedDataWithRootObject:sessionsToSave];
			if (encodedSessions != nil)	{
			}
		}
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
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
		
		//	update the relevant toolbar items
		[runPauseButton setLabel:@"Pause"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_pause_circle_filled"]];
		[stopButton setEnabled:YES];
		[addItem setEnabled:NO];
		[removeItem setEnabled:NO];
		[clearItem setEnabled:NO];
		
		//	hide the preview
		[appDelegate hidePreview];
		
		//	update ivars
		self.running = YES;
		self.paused = NO;
		
		//	do stuff with ops
		NSArray<SynOp*>		*opsToStart = [self getOpsToStart:[self maxOpCount]];
		for (SynOp * op in opsToStart)	{
			[self.opsInProgress addObject:op];
			[op start];
		}
		
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
		if (self.opsInProgress.count < self.maxOpCount)	{
			NSArray<SynOp*>		*opsToStart = [self getOpsToStart:(self.maxOpCount - self.opsInProgress.count)];
			for (SynOp *opToStart in opsToStart)	{
				[opToStart start];
			}
		}
		
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
		
		//	update the relevant toolbar items
		[runPauseButton setLabel:@"Start"];
		[runPauseButton setImage:[NSImage imageNamed:@"ic_play_circle_filled"]];
		[stopButton setEnabled:NO];
		[addItem setEnabled:YES];
		[removeItem setEnabled:YES];
		[clearItem setEnabled:YES];
		
		//	show the preview
		[appDelegate showPreview];
		
		//	update ivars
		self.running = NO;
		self.paused = NO;
		
		//	do stuff with ops
		for (SynOp *op in self.opsInProgress)	{
			[op stop];
		}
		
		//	do stuff with the timer
		if (self.progressRefreshTimer != nil)	{
			[self.progressRefreshTimer invalidate];
			self.progressRefreshTimer = nil;
		}
	}
	
	//	reload the outline view
	[self reloadData];
}
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
		for (SynSession *session in self.sessions)	{
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
	
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result)	{
		if (result == NSModalResponseOK)	{
			[self analysisSessionForFiles:openPanel.URLs sessionCompletionBlock:^{
				 
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
			[self.sessions removeObjectIdenticalTo:tmpSession];
			[self reloadData];
		}
		else if ([selItem isKindOfClass:[SynOp class]])	{
			SynOp			*tmpTop = (SynOp *)selItem;
			SynSession		*tmpSession = tmpTop.session;
			if (tmpSession == nil)
				return;
			[tmpSession.ops removeObjectIdenticalTo:tmpTop];
			[self reloadData];
		}
	}
}
- (IBAction) clearClicked:(id)sender	{
	@synchronized (self)	{
		[self.sessions removeAllObjects];
		[self reloadData];
	}
}


- (IBAction) revealLog:(id)sender	{
	//[self revealHelper:self.logWindow sender:sender];
	NSLog(@"should be opening log window here");
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
	SynSession		*filesSession = nil;
	for (SynSession *newSession in newSessions)	{
		if (filesSession == nil && newSession.type == SessionType_List)
			filesSession = newSession;
		[self.sessions addObject:newSession];
	}
	
	//	reload the table view
	[self reloadData];
	//	expand the item for the session we just created
	if (filesSession != nil)
		[outlineView expandItem:filesSession expandChildren:YES];
}
/*
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
*/


- (void) reloadData	{
	[outlineView reloadData];
	[self restoreExpandStates];
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
				NSArray<SynOp*>		*opsToStart = [self getOpsToStart:1];
				for (SynOp * op in opsToStart)	{
					[self.opsInProgress addObject:op];
					[op start];
				}
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
	NSInteger		selectedRow = [outlineView selectedRow];
	if (selectedRow == -1)
		[[InspectorViewController global] uninspectAll];
	else	{
		id				tmpObj = [outlineView itemAtRow:selectedRow];
		[[InspectorViewController global] inspectItem:tmpObj];
	}
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldExpandItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	
	if (item!=nil && [item isKindOfClass:[SynSession class]])	{
		SynSession		*tmpSession = (SynSession *)item;
		if (tmpSession.dragUUID != nil)
			self.expandStateDict[tmpSession.dragUUID.UUIDString] = @YES;
	}
	
	return YES;
}
- (BOOL)outlineView:(NSOutlineView *)ov shouldCollapseItem:(id)item	{
	//NSLog(@"%s ... %@",__func__,item);
	
	if (item!=nil && [item isKindOfClass:[SynSession class]])	{
		SynSession		*tmpSession = (SynSession *)item;
		if (tmpSession.dragUUID != nil)
			[self.expandStateDict removeObjectForKey:tmpSession.dragUUID.UUIDString];
	}
	
	return YES;
}
- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item	{
	if (self.running)
		return NO;
	return YES;
}


- (BOOL) outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard*)pboard	{
	//NSLog(@"%s ... %@",__func__,items);
	
	if (items==nil || [items count]!=1)
		return NO;
	id				tmpItem = items[0];
	SynOp			*recast = (SynOp*)tmpItem;
	[pboard setString:recast.dragUUID.UUIDString forType:localFileDragType];
	
	return YES;
}
- (NSDragOperation) outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)rawDropItem proposedChildIndex:(int)dropIndex	{
	//NSLog(@"%s ... %@, %d",__func__,rawDropItem,dropIndex);
	NSPasteboard		*pboard = [info draggingPasteboard];
	
	//	if it's a drag from the finder...
	if ([pboard availableTypeFromArray:@[ NSPasteboardTypeFileURL ]])	{
		//	nil item means dropping into an unspecified session...
		if (rawDropItem == nil)	{
			return NSDragOperationGeneric;
		}
		//	if we're dropping on a session at a given index...
		else if ([rawDropItem isKindOfClass:[SynSession class]])	{
			//	if it's a dir-type session then we can't target it!
			SynSession		*tmpSession = (SynSession *)rawDropItem;
			if (tmpSession.type == SessionType_Dir)
				[ov setDropItem:nil dropChildIndex:-1];
			else
				return NSDragOperationGeneric;
		}
		//	else if we're dropping on an op...
		else if ([rawDropItem isKindOfClass:[SynOp class]])	{
			//	change the drop target to the op's parent session, right after the op
			SynSession		*parentSession = [(SynOp *)rawDropItem session];
			if (parentSession == nil)	{
				[ov setDropItem:nil dropChildIndex:-1];
				return NSDragOperationGeneric;
			}
			NSInteger		targetIndexWithinSession = [[parentSession ops] indexOfObjectIdenticalTo:rawDropItem];
			if (targetIndexWithinSession == NSNotFound)
				targetIndexWithinSession = 0;
			else
				++targetIndexWithinSession;
			[ov setDropItem:parentSession dropChildIndex:targetIndexWithinSession];
			return NSDragOperationGeneric;
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
			//SynSession		*dragItem = (SynSession *)rawDragItem;
			//	if 'rawDropItem' is nil we're dropping onto the master list of sessions
			if (rawDropItem == nil)	{
				return NSDragOperationGeneric;
			}
			//	else we're trying to drag into a session...
			else if ([rawDropItem isKindOfClass:[SynSession class]])	{
				SynSession		*dropItem = (SynSession *)rawDropItem;
				//	change the drop target to one index after the parent session's index (we can't drag a session into antoher session)
				NSInteger		dropItemIndex = [self.sessions indexOfObjectIdenticalTo:dropItem];
				if (dropItemIndex == NSNotFound || dropItemIndex < 0)
					dropItemIndex = self.sessions.count;
				[ov setDropItem:nil dropChildIndex:dropItemIndex];
			}
			//	else we're trying to drag into an op...
			else if ([rawDropItem isKindOfClass:[SynOp class]])	{
				SynOp			*dropItem = (SynOp *)rawDropItem;
				//	change the drop target to one index after the parent session's index (we can't drag a session into antoher session)
				SynSession		*dropSession = dropItem.session;
				NSInteger		dropSessionIndex = [self.sessions indexOfObjectIdenticalTo:dropSession];
				if (dropSessionIndex == NSNotFound || dropSessionIndex < 0)
					dropSessionIndex = self.sessions.count;
				[ov setDropItem:nil dropChildIndex:dropSessionIndex];
			}
		}
		else if ([rawDragItem isKindOfClass:[SynOp class]])	{
			//SynOp			*dragItem = (SynOp *)rawDragItem;
			//	if 'rawDropItem is nil we're dropping onto the master list of sessions
			if (rawDropItem == nil)	{
				//	do nothing (this is how you create another session)
				return NSDragOperationGeneric;
				/*
				//	set the drop target to drag item's index in drag item's parent session (no change)
				NSInteger		dragItemIndex = [dragItem.session.ops indexOfObjectIdenticalTo:dragItem];
				if (dragItemIndex == NSNotFound || dragItemIndex < 0)
					dragItemIndex = dragItem.session.ops.count;
				[ov setDropItem:dragItem.session dropChildIndex:dragItemIndex];
				*/
			}
			//	else we're trying to drag an op into a session...
			else if ([rawDropItem isKindOfClass:[SynSession class]])	{
				//	do nothing (we're good)
				return NSDragOperationGeneric;
			}
			//	else we're trying to drag an op into another op...
			else if ([rawDropItem isKindOfClass:[SynOp class]])	{
				SynOp			*dropItem = (SynOp *)rawDropItem;
				SynSession		*dropItemSession = dropItem.session;
				NSInteger		dropItemIndex = [dropItemSession.ops indexOfObjectIdenticalTo:dropItem];
				if (dropItemIndex == NSNotFound || dropItemIndex < 0)
					dropItemIndex = dropItemSession.ops.count;
				[ov setDropItem:dropItemSession dropChildIndex:dropItemIndex];
			}
		}
		return NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}
- (BOOL) outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)rawDropItem childIndex:(int)dropIndex	{
	//NSLog(@"%s",__func__);
	NSPasteboard		*pboard = [info draggingPasteboard];
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
			//	if the dropIndex is -1, this is very simple
			if (dropIndex == -1)	{
				[self createAndAppendSessionsWithFiles:fileURLs];
				return YES;
			}
			//	...if we're here, we're inserting a drop into our list of sessions (not dropping inside a session, but into the list of sessions)
			NSArray<SynSession*>	*newSessions = [self createSessionsWithFiles:fileURLs];
			//	if the dropIndex is -1, we want to append to the end of all sessions
			NSInteger				targetIndex = (dropIndex==-1) ? self.sessions.count : dropIndex;
			SynSession				*filesSession = nil;
			for (SynSession *newSession in newSessions)	{
				if (filesSession == nil && newSession.type == SessionType_List)
					filesSession = newSession;
				[self.sessions insertObject:newSession atIndex:targetIndex];
				++targetIndex;
			}
			//	reload the outline view!
			[self reloadData];
			//	if we added a session with a bunch of loose files, open it
			if (filesSession != nil)
				[outlineView expandItem:filesSession expandChildren:YES];
			//	re-evaluate the selection...
			[self outlineViewSelectionDidChange:nil];
			return YES;
		}
		//	else if we're dropping into an existing session (dropping inside a session)
		else if ([rawDropItem isKindOfClass:[SynSession class]])	{
			SynSession		*targetSession = (SynSession *)rawDropItem;
			//	if the dropIndex is -1, we want to append to the end of the session's ops
			NSInteger		targetIndex = (dropIndex==-1) ? targetSession.ops.count : dropIndex;
			for (NSURL *fileURL in fileURLs)	{
				SynOp			*tmpOp = [[SynOp alloc] initWithSrcURL:fileURL];
				//	only insert the op if it's an AVF file OR its parent session is copying non-media files
				if (tmpOp != nil && (tmpOp.type == OpType_AVFFile || targetSession.copyNonMediaFiles))	{
					[targetSession.ops insertObject:tmpOp atIndex:targetIndex];
					tmpOp.session = targetSession;
					++targetIndex;
				}
				//	else if the op is nil...
				else if (tmpOp == nil)	{
					//	did we try to make an op from a directory (which should be a session)?
					NSArray<SynSession*>	*tmpSessions = [self createSessionsWithFiles:@[fileURL]];
					for (SynSession *tmpSession in tmpSessions)	{
						[self.sessions addObject:tmpSession];
					}
				}
			}
			//	reload the outline view!
			[self reloadData];
			//	re-evaluate the selection...
			[self outlineViewSelectionDidChange:nil];
			return YES;
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
			NSInteger		dragItemOrigIndex = [self.sessions indexOfObjectIdenticalTo:dragItem];
			if (rawDropItem != nil)	{
				//	if the dropIndex == orig index, do nothing and return
				if (dropIndex == dragItemOrigIndex)	{
					//	intentionally blank (technically we could probably skip the reloadData but whatevs)
				}
				//	else if the dropIndex is > the orig index, insert first and then delete
				else if (dropIndex > dragItemOrigIndex)	{
					[self.sessions insertObject:dragItem atIndex:dropIndex];
					[self.sessions removeObjectAtIndex:dragItemOrigIndex];
				}
				//	else the dropIndex is < the orig index, delete first then insert
				else	{
					[self.sessions removeObjectAtIndex:dragItemOrigIndex];
					[self.sessions insertObject:dragItem atIndex:dropIndex];
				}
				//	reload the outline view
				[self reloadData];
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
				//	create a new session, add the op to it, insert the session and the drop index
				SynSession		*newSession = [SynSession createWithFiles:@[]];
				[newSession.ops addObject:dragItem];
				[dragItem setSession:newSession];
				[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
				[self.sessions insertObject:newSession atIndex:(dropIndex==-1) ? self.sessions.count : dropIndex];
				
				//	if the parent session is now empty, remove it
				if (dragItemParent.ops.count < 1)
					[self.sessions removeObjectIdenticalTo:dragItemParent];
				
				//	this will cause the session we just created to be expanded when the outline view is reloaded...
				self.expandStateDict[newSession.dragUUID.UUIDString] = @YES;
				//	reload the outline view...
				[self reloadData];
				//	re-evaluate the selection...
				[self outlineViewSelectionDidChange:nil];
				return YES;
			}
			//	else if we're dropping the op into a session...
			else if ([rawDropItem isKindOfClass:[SynSession class]])	{
				SynSession		*dropItem = (SynSession *)rawDropItem;
				//	if the drop index == orig index...
				if (dropIndex == dragItemOrigIndex)	{
					//	if it's the same session, do nothing
					if (dragItemParent == dropItem)	{
						//	intentionally blank
					}
					//	else insert first, then delete
					else	{
						[dropItem.ops insertObject:dragItem atIndex:(dropIndex==-1) ? dropItem.ops.count : dropIndex];
						[dragItem setSession:dropItem];
						[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
					}
				}
				//	else if the drop index is > the orig index, insert first and then delete
				else if (dropIndex > dragItemOrigIndex)	{
					[dropItem.ops insertObject:dragItem atIndex:(dropIndex==-1) ? dropItem.ops.count : dropIndex];
					[dragItem setSession:dropItem];
					[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
				}
				//	else the drop index is < the orig index, delete first then insert
				else	{
					[dragItemParent.ops removeObjectAtIndex:dragItemOrigIndex];
					[dropItem.ops insertObject:dragItem atIndex:(dropIndex==-1) ? dropItem.ops.count : dropIndex];
					[dragItem setSession:dropItem];
				}
				
				//	if the parent session is now empty, remove it
				if (dragItemParent.ops.count < 1)
					[self.sessions removeObjectIdenticalTo:dragItemParent];
				
				//	reload the outline view
				[self reloadData];
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
	
	return NO;
}


@end











