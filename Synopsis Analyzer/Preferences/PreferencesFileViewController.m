//
//	PreferencesFileViewController.m
//	Synopsis Analyzer
//
//	Created by vade on 10/3/17.
//	Copyright © 2017 metavisual. All rights reserved.
//

#import "PreferencesFileViewController.h"
#import <Synopsis/Synopsis.h>
#import "AppDelegate.h"
#import "Constants.h"

@interface PreferencesFileViewController ()

@property (weak) IBOutlet NSButton* usingOutputFolderButton;
@property (weak) IBOutlet NSButton* selectOutputFolder;
@property (weak) IBOutlet NSTextField* outputFolderDescription;
@property (weak) IBOutlet NSButton* outputFolderStatus;

@property (weak) IBOutlet NSButton* usingWatchFolderButton;
@property (weak) IBOutlet NSButton* selectWatchFolder;
@property (weak) IBOutlet NSTextField* watchFolderDescription;
@property (weak) IBOutlet NSButton* watchFolderStatus;

@property (weak) IBOutlet NSButton* usingTempFolderButton;
@property (weak) IBOutlet NSButton* selectTempFolder;
@property (weak) IBOutlet NSTextField* tempFolderDescription;
@property (weak) IBOutlet NSButton* tempFolderStatus;

@property (weak) IBOutlet NSButton* usingMirroredFoldersButton;

@property (strong) SynopsisDirectoryWatcher* directoryWatcher;

@end

@implementation PreferencesFileViewController

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self)
	{
		[self initDirectoryWatcherIfNeeded];
	}
	return self;
}

- (void) awakeFromNib
{
	[self validateOutputFolderUI];
	[self validateWatchFolderUI];
	[self validateTempFolderUI];
	[self validateMirroredFoldersUI];
}

#pragma mark - Output Folder

- (IBAction)selectOutFolder:(id)sender
{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canCreateDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.message = @"Select Output Folder";
	
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
		if(result == NSModalResponseOK)
		{
			NSURL* outputFolderURL = [openPanel URL];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateOutputFolder:outputFolderURL];
			});
		}
	}];
}

- (IBAction)useOutputFolder:(id)sender
{
	BOOL useFolder = ([sender state] == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setValue:@(useFolder) forKey:kSynopsisAnalyzerUseOutputFolderKey];
	
	[self validateOutputFolderUI];
}

- (void) updateOutputFolder:(NSURL*)outputURL
{
	[[NSUserDefaults standardUserDefaults] setValue:[outputURL path] forKey:kSynopsisAnalyzerOutputFolderURLKey];
	[self validateOutputFolderUI];
}

- (BOOL) usingOutputFolder
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerUseOutputFolderKey] boolValue];
}

- (NSURL*) outputFolderURL
{
	NSString* outputPath = [[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerOutputFolderURLKey];
	if(outputPath)
	{
		NSURL* outputURL = [NSURL fileURLWithPath:outputPath];
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:outputPath isDirectory:&isDirectory])
		{
			if(isDirectory)
				return outputURL;
		}
	}
	return nil;
}

- (void) validateOutputFolderUI
{
	NSURL* url = [self outputFolderURL];
	BOOL usingOutputFolder = [self usingOutputFolder];
	
	self.usingOutputFolderButton.state = (usingOutputFolder) ? NSOnState : NSOffState;
	
	if(usingOutputFolder && url)
		self.outputFolderStatus.image = [NSImage imageNamed:NSImageNameStatusAvailable];
	else if (usingOutputFolder && !url)
		self.outputFolderStatus.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
	else
		self.outputFolderStatus.image = [NSImage imageNamed:NSImageNameStatusNone];
	
	if(url)
		self.outputFolderDescription.stringValue = [[[url absoluteURL] path] stringByRemovingPercentEncoding];
	else
		self.outputFolderDescription.stringValue = @"Output Folder";
}

- (IBAction)revealOutputFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[ [self outputFolderURL]] ];
}

#pragma mark - Watch Folder

- (IBAction)selectWatchFolder:(id)sender
{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canCreateDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.message = @"Select Watch Folder";
	
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
		if(result == NSModalResponseOK)
		{
			NSURL* outputFolderURL = [openPanel URL];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateWatchFolder:outputFolderURL];
			});
		}
	}];
}

- (IBAction)useWatchFolder:(id)sender
{
	BOOL useFolder = ([sender state] == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setValue:@(useFolder) forKey:kSynopsisAnalyzerUseWatchFolderKey];
	
	[self validateWatchFolderUI];
}

- (void) updateWatchFolder:(NSURL*)outputURL
{
	[[NSUserDefaults standardUserDefaults] setValue:[outputURL path] forKey:kSynopsisAnalyzerWatchFolderURLKey];
	
	[self validateWatchFolderUI];
}

- (BOOL) usingWatchFolder
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerUseWatchFolderKey] boolValue];
}

- (NSURL*) watchFolderURL
{
	NSString* outputPath = [[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerWatchFolderURLKey];
	if(outputPath)
	{
		NSURL* outputURL = [NSURL fileURLWithPath:outputPath];
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:outputPath isDirectory:&isDirectory])
		{
			if(isDirectory)
				return outputURL;
		}
	}
	
	return nil;
}

- (void) validateWatchFolderUI
{
	NSURL* watchURL = [self watchFolderURL];
	BOOL usingWatchFolder = [self usingWatchFolder];
	
	self.usingWatchFolderButton.state = (usingWatchFolder) ? NSOnState : NSOffState;
	
	if(usingWatchFolder && watchURL)
		self.watchFolderStatus.image = [NSImage imageNamed:NSImageNameStatusAvailable];
	else if (usingWatchFolder && !watchURL)
		self.watchFolderStatus.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
	else
		self.watchFolderStatus.image = [NSImage imageNamed:NSImageNameStatusNone];
	
	if(watchURL)
		self.watchFolderDescription.stringValue = [[[watchURL absoluteURL] path] stringByRemovingPercentEncoding];
	else
		self.watchFolderDescription.stringValue = @"Watch Folder";
	
	[self initDirectoryWatcherIfNeeded];
}

- (void) initDirectoryWatcherIfNeeded
{
	NSURL* watchURL = [self watchFolderURL];
	BOOL usingWatchFolder = [self usingWatchFolder];

	//AppDelegate* appDelegate = (AppDelegate*) [[NSApplication sharedApplication] delegate];
	if(usingWatchFolder && watchURL)
	{
		self.directoryWatcher = [[SynopsisDirectoryWatcher alloc] initWithDirectoryAtURL:watchURL mode:SynopsisDirectoryWatcherModeDefault notificationBlock:^(NSArray<NSURL *> *changedURLS) {
			// Kick off Analysis Session
			/*
			[appDelegate analysisSessionForFiles:changedURLS sessionCompletionBlock:^{
				dispatch_async(dispatch_get_main_queue(), ^{
					NSLog(@"SESSION COMPLETE ALL SESSION MEDIA AND SUB FOLDERS TO OUTPUT FOLDER FROM TEMP WORKING FOLDER");
				});
			}];
			*/
			NSLog(@"should be creating a session to analyze a bunch of files here");
		}];
	}
	else
	{
		self.directoryWatcher = nil;
	}
}

- (IBAction) revealWatchFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[ [self watchFolderURL]] ];
}

#pragma mark - Temp Folder

- (IBAction)selectTempFolder:(id)sender
{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canCreateDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.message = @"Select Temporary Items Folder";
	
	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
		if(result == NSModalResponseOK)
		{
			NSURL* outputFolderURL = [openPanel URL];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateTempFolder:outputFolderURL];
			});
		}
	}];
}

- (IBAction)useTempFolder:(id)sender
{
	BOOL useFolder = ([sender state] == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setValue:@(useFolder) forKey:kSynopsisAnalyzerUseTempFolderKey];
	
	[self validateTempFolderUI];
}

- (void) updateTempFolder:(NSURL*)outputURL
{
	[[NSUserDefaults standardUserDefaults] setValue:[outputURL path] forKey:kSynopsisAnalyzerTempFolderURLKey];
	
	[self validateTempFolderUI];
}

- (BOOL) usingTempFolder
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerUseTempFolderKey] boolValue];
}

- (NSURL*) tempFolderURL
{
	NSString* outputPath = [[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerTempFolderURLKey];
	if(outputPath)
	{
		NSURL* outputURL = [NSURL fileURLWithPath:outputPath];
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:outputPath isDirectory:&isDirectory])
		{
			if(isDirectory)
				return outputURL;
		}
	}
	
	return nil;
}

- (void) validateTempFolderUI
{
	NSURL* watchURL = [self tempFolderURL];
	BOOL usingWatchFolder = [self usingTempFolder];
	
	self.usingTempFolderButton.state = (usingWatchFolder) ? NSOnState : NSOffState;
	
	if(usingWatchFolder && watchURL)
		self.tempFolderStatus.image = [NSImage imageNamed:NSImageNameStatusAvailable];
	else if (usingWatchFolder && !watchURL)
		self.tempFolderStatus.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
	else
		self.tempFolderStatus.image = [NSImage imageNamed:NSImageNameStatusNone];
	
	if(watchURL)
		self.tempFolderDescription.stringValue = [[[watchURL absoluteURL] path] stringByRemovingPercentEncoding];
	else
		self.tempFolderDescription.stringValue = @"Temporary Items Folder";
}

- (IBAction) revealTempFolder:(id)sender
{
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[ [self tempFolderURL]] ];
}

#pragma mark - Mirror prefs

- (BOOL) usingMirroredFolders
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerMirrorFolderStructureToOutputKey] boolValue];
}

- (void) validateMirroredFoldersUI
{
	BOOL using = [self usingMirroredFolders];
	
	self.usingMirroredFoldersButton.state = (using) ? NSOnState : NSOffState;
}

- (IBAction)useMirroredFolders:(id)sender
{
	BOOL use = ([sender state] == NSOnState);
	
	[[NSUserDefaults standardUserDefaults] setValue:@(use) forKey:kSynopsisAnalyzerMirrorFolderStructureToOutputKey];
	
	[self validateMirroredFoldersUI];
}

@end
