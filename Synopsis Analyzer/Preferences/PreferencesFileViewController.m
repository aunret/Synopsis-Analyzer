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
#import "SessionController.h"




@interface PreferencesFileViewController ()

@property (weak) IBOutlet NSButton* usingMirroredFoldersButton;

@property (strong) SynopsisDirectoryWatcher* directoryWatcher;

@end




@implementation PreferencesFileViewController

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if(self)
	{
	}
	return self;
}

- (void) awakeFromNib
{
	__block PreferencesFileViewController		*bss = self;
	[outputFolderAbs setUserDefaultsKey:kSynopsisAnalyzerOutputFolderURLKey];
	[outputFolderAbs setSelectButtonBlock:^(PrefsPathAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Output Folder";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				//dispatch_async(dispatch_get_main_queue(), ^{
				//	[self updateOutputFolder:outputFolderURL];
				//});
			}
		}];
	}];
	
	[watchFolderAbs setUserDefaultsKey:kSynopsisAnalyzerWatchFolderURLKey];
	[watchFolderAbs setSelectButtonBlock:^(PrefsPathAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Watch Folder";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)
			{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				[bss initDirectoryWatcherIfNeeded];
				//dispatch_async(dispatch_get_main_queue(), ^{
				//	[self updateWatchFolder:outputFolderURL];
				//});
			}
		}];
	}];
	[watchFolderAbs setEnableToggleBlock:^()	{
		[bss initDirectoryWatcherIfNeeded];
	}];
	
	[tempFolderAbs setUserDefaultsKey:kSynopsisAnalyzerTempFolderURLKey];
	[tempFolderAbs setSelectButtonBlock:^(PrefsPathAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Temporary Items Folder";
	
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)
			{
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				//dispatch_async(dispatch_get_main_queue(), ^{
				//	[self updateTempFolder:outputFolderURL];
				//});
			}
		}];
	}];
	
	[self validateMirroredFoldersUI];
	[self initDirectoryWatcherIfNeeded];
}


#pragma mark - Output Folder


- (NSURL*) outputFolderURL
{
	NSString* outputPath = [outputFolderAbs path];
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


#pragma mark - Watch Folder


- (NSURL*) watchFolderURL
{
	NSString* outputPath = [watchFolderAbs path];
	if(outputPath != nil)
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

- (void) initDirectoryWatcherIfNeeded
{
	NSURL* watchURL = [self watchFolderURL];
	//BOOL usingWatchFolder = [self usingWatchFolder];

	//AppDelegate* appDelegate = (AppDelegate*) [[NSApplication sharedApplication] delegate];
	if(/*usingWatchFolder &&*/ watchURL!=nil)
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
			[[SessionController global] newSessionWithFiles:changedURLS];
		}];
	}
	else
	{
		self.directoryWatcher = nil;
	}
}


#pragma mark - Temp Folder


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


#pragma mark - Mirror prefs


- (BOOL) usingMirroredFolders
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:kSynopsisAnalyzerMirrorFolderStructureToOutputKey] boolValue];
}

- (void) validateMirroredFoldersUI
{
	BOOL using = [self usingMirroredFolders];
	
	self.usingMirroredFoldersButton.state = (using) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)useMirroredFolders:(id)sender
{
	BOOL use = ([sender state] == NSControlStateValueOn);
	
	[[NSUserDefaults standardUserDefaults] setValue:@(use) forKey:kSynopsisAnalyzerMirrorFolderStructureToOutputKey];
	
	[self validateMirroredFoldersUI];
}

@end
