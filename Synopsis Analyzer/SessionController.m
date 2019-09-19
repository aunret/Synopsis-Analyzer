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




static SessionController			*globalSessionController = nil;




@interface SessionController ()
- (void) generalInit;
@property (strong) NSMutableArray<SynSession*> * sessions;
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	//[self window];
}
- (void) awakeFromNib	{
	[dropView setDragDelegate:self];
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
	SynSession			*newSession = [SynSession createWithFiles:n];
	if (newSession == nil)
		return;
	@synchronized (self)	{
		[self.sessions addObject:newSession];
	}
	[self reloadData];
}
- (void) newSessionWithDir:(NSURL *)n	{
	if (n == nil)
		return;
	SynSession			*newSession = [SynSession createWithDir:n];
	if (newSession == nil)
		return;
	@synchronized (self)	{
		[self.sessions addObject:newSession];
	}
	[self reloadData];
}


- (void) reloadData	{
	[outlineView reloadData];
}


#pragma mark - DropFileHelper


- (void) analysisSessionForFiles:(NSArray *)fileURLArray sessionCompletionBlock:(void (^)(void))completionBlock {
	NSLog(@"%s ... %@",__func__,fileURLArray);
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
	//NSLog(@"%s ... %@",__func__,item);
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
		return self.sessions[index];
	}
	
	if ([item isKindOfClass:[SynSession class]])	{
		return [[(SynSession*)item ops] objectAtIndex:index];
	}
	
	return nil;
}

- (BOOL) outlineView:(NSOutlineView *)ov isItemExpandable:(id)item	{
	if (item == nil)
		return YES;
	if ([item isKindOfClass:[SynOp class]])
		return YES;
	return NO;
}

- (NSView *) outlineView:(NSOutlineView *)ov viewForTableColumn:(NSTableColumn *)tc item:(id)item	{
	if (item==nil)
		return nil;
	return nil;
	/*
	VVAjaFrameStoreCellView		*returnMe = nil;
	if ([item isKindOfClass:[VVAjaDevice class]])	{
		returnMe = [ov makeViewWithIdentifier:@"DefaultView" owner:self];
		if (returnMe != nil)
			[[returnMe textField] setStringValue:[item deviceName]];
	}
	else if ([item isKindOfClass:[VVAjaFrameStore class]])	{
		returnMe = [ov makeViewWithIdentifier:@"FrameStoreView" owner:self];
		if (returnMe != nil)
			[returnMe refreshWithFrameStore:(VVAjaFrameStore *)item inOutlineView:ov];
	}
	return returnMe;
	*/
}
/*
- (CGFloat) outlineView:(NSOutlineView *)ov heightOfRowByItem:(id)item	{
}
*/
- (void) outlineViewSelectionDidChange:(NSNotification *)note	{
	//NSLog(@"%s",__func__);
}


@end
