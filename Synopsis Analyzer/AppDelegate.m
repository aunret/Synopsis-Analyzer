//
//	AppDelegate.m
//	MetadataTranscoderTestHarness
//
//	Created by vade on 3/31/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//

#import "AppDelegate.h"
#import <Synopsis/Synopsis.h>
#import <VideoToolbox/VTProfessionalVideoWorkflow.h>
#import <MediaToolbox/MediaToolbox.h>
#import <UserNotifications/UserNotifications.h>

#import "DropFilesView.h"
#import "LogController.h"
#import "PrefsController.h"
#import "Constants.h"

//#import "AnalysisAndTranscodeOperation.h"
//#import "MetadataWriterTranscodeOperation.h"

#import "SessionController.h"
#import "PreferencesViewController.h"
#import "PresetObject.h"
#import "VVLogger.h"
#import "SynSession.h"




@interface AppDelegate () <NSFileManagerDelegate>

- (void) installCLI;

@property (readwrite, strong) NSFileManager* fileManager;
@property (strong,nullable) NSViewAnimation * previewAnimation;

@property (strong,readwrite,nullable) NSTimer * fileOpenTimer;
@property (strong,readwrite) NSMutableArray * URLsToOpen;
//- (NSString *) getSpotlightPKGReceiptVsn;
//- (NSString *) getIncludedSpotlightPKGVsn;

@end




//static NSUInteger kAnalysisOperationIndex = 0;
//static NSUInteger kMetadataOperationIndex = 1;




@implementation AppDelegate

+ (void) initialize	{
#if !DEBUG
	[[VVLogger alloc] initWithFolderName:nil maxNumLogs:20];
	[[VVLogger globalLogger] redirectLogs];
#endif
}
- (id) init
{
	self = [super init];
	if(self)	{
		
		MTRegisterProfessionalVideoWorkflowFormatReaders();
		VTRegisterProfessionalVideoWorkflowVideoDecoders();
		VTRegisterProfessionalVideoWorkflowVideoEncoders();

		NSDictionary* standardDefaults = @{kSynopsisAnalyzerDefaultPresetPreferencesKey : @"DDCEA125-B93D-464B-B369-FB78A5E890B4",
										kSynopsisAnalyzerConcurrentJobAnalysisPreferencesKey : @(YES),
										kSynopsisAnalyzerConcurrentJobCountPreferencesKey : @(-1),
										kSynopsisAnalyzerConcurrentFrameAnalysisPreferencesKey : @(YES),
										kSynopsisAnalyzerUseOutputFolderKey : @(NO),
										kSynopsisAnalyzerUseWatchFolderKey : @(NO),
										kSynopsisAnalyzerUseTempFolderKey : @(NO),
										kSynopsisAnalyzerMirrorFolderStructureToOutputKey : @(NO),
										};
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:standardDefaults];
		
		self.previewAnimation = nil;
		
		self.fileOpenTimer = nil;
		self.URLsToOpen = [NSMutableArray arrayWithCapacity:0];
		
		//	make the various top-level controllers
		[LogController global];
		[PrefsController global];
		[SessionController global];
		
		
		self.fileManager = [[NSFileManager alloc] init];
		[self.fileManager setDelegate:self];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification	{
	
	// Load our plugins
	NSString* pluginsPath = [[NSBundle mainBundle] builtInPlugInsPath];
	
	NSError* error = nil;
	
	NSArray* possiblePlugins = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsPath error:&error];
	
	if(!error)
	{
		for(NSString* possiblePlugin in possiblePlugins)
		{
			NSLog(@"\tpossiblePlugin is %@",possiblePlugin);
			NSBundle* pluginBundle = [NSBundle bundleWithPath:[pluginsPath stringByAppendingPathComponent:possiblePlugin]];
			
			if(pluginBundle)
			{
				NSError* loadError = nil;
				if([pluginBundle preflightAndReturnError:&loadError])
				{
					if([pluginBundle loadAndReturnError:&loadError])
					{
						// Weve sucessfully loaded our bundle, time to cache our class name so we can initialize a plugin per operation
						// See AnalysisAndTranscodeOperation
						Class pluginClass = pluginBundle.principalClass;
						NSString* classString = NSStringFromClass(pluginClass);
						
						if(classString)
						{
							//[self.analyzerPlugins addObject:classString];
							NSLog(@"should be adding plugin name %@ to an array here",classString);
							NSLog(@"\tloaded plugin %@",classString);
							[LogController appendSuccessLog:[NSString stringWithFormat:@"Loaded Plugin: %@", classString, nil]];
							
							//[self.prefsAnalyzerArrayController addObject:[[pluginClass alloc] init]];
							NSLog(@"should be adding plugin instance to an array here");
						}
					}
					else
					{
						[LogController appendErrorLog:[NSString stringWithFormat:@"Error Loading Plugin : %@ : %@ %@", possiblePlugin, pluginsPath, loadError.description, nil]];
					}
				}
				else
				{
					[LogController appendErrorLog:[NSString stringWithFormat:@"Error Preflighting Plugin : %@ : %@ %@ %@", possiblePlugin, pluginsPath,  pluginBundle, loadError.description, nil]];
				}
			}
			else
			{
				[LogController appendErrorLog:[NSString stringWithFormat:@"Error Creating Plugin : %@ : %@ %@", possiblePlugin, pluginsPath,	pluginBundle, nil]];
			}
		}
	}
	
	// REVEAL THYSELF
	//[[self window] makeKeyAndOrderFront:nil];
	[window makeKeyAndOrderFront:nil];
	
	// Touch a ".synopsis" file to trick out embedded spotlight importer that there is a .synopsis file
	// We mirror OpenMeta's approach to allowing generic spotlight support via xattr's
	// But Yea
	[self initSpotlight];
	
	// force Standard Analyzer to be a plugin
	//[self.analyzerPlugins addObject:NSStringFromClass([StandardAnalyzerPlugin class])];

	if (@available(macOS 10.14, *))	{
		//	request permission to post notifications
		UNUserNotificationCenter		*center = [UNUserNotificationCenter currentNotificationCenter];
		[center
			requestAuthorizationWithOptions:UNAuthorizationOptionAlert
			completionHandler:^(BOOL granted, NSError *err)	{
				if (granted)	{
					UNNotificationCategory		*cat = [UNNotificationCategory
						categoryWithIdentifier:@"SessionComplete"
						actions:@[]
						intentIdentifiers:@[]
						options:UNNotificationCategoryOptionNone];
					[[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObjects:cat,nil]];
				}
			}];
	}
	
	//	install the CLI!
	[self installCLI];
}
- (void) installCLI	{
	NSLog(@"%s",__func__);
	
	NSError				*nsErr = nil;
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSString			*cliSymlinkSrcPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"synopsis-enc"];
	NSString			*cliSymlinkDstPath = @"/usr/local/bin/synopsis-enc";
	
	//	if the symlink doesn't exist at all...
	if ([fm attributesOfItemAtPath:cliSymlinkDstPath error:&nsErr] == nil)	{
		//	show an alert asking the user if they'd like to install the command-line tools, bail if they say 'no'
		NSAlert			*installRequest = [[NSAlert alloc] init];
		installRequest.messageText = @"Would you like to install the command-line synopsis encoder?";
		[installRequest addButtonWithTitle:@"Yes"];
		[installRequest addButtonWithTitle:@"No"];
		NSModalResponse		response = [installRequest runModal];
		if (response != NSAlertFirstButtonReturn)
			return;
	}
	//	else the symlink exists...
	else	{
		NSString			*existingSrcPath = [fm destinationOfSymbolicLinkAtPath:cliSymlinkDstPath error:&nsErr];
		//	if the symlink's path is wrong or can't be retrieved...
		if (existingSrcPath==nil || nsErr != nil || ![existingSrcPath isEqualToString:cliSymlinkSrcPath])	{
			//	delete the existing symlink, bail with an alert if we can't
			if (![fm removeItemAtPath:cliSymlinkDstPath error:&nsErr])	{
				NSAlert			*installErr = [[NSAlert alloc] init];
				if (nsErr != nil)
					installErr.messageText = [NSString stringWithFormat:@"There was a problem updating the CLI (couldn't remove old symlink- %@)",nsErr.localizedDescription];
				else
					installErr.messageText = @"There was a problem updating the CLI (couldn't remove old CLI)";
				installErr.alertStyle = NSAlertStyleCritical;
				[installErr addButtonWithTitle:@"Cancel install"];
				[installErr runModal];
				return;
			}
		}
		//	else the symlink exists and its path is okay- bail, we're done here
		else	{
			return;
		}
	}
	
	//	make the symbolic link to the binary, bail with an alert if we can't
	if (![fm createSymbolicLinkAtPath:cliSymlinkDstPath withDestinationPath:cliSymlinkSrcPath error:&nsErr])	{
		NSAlert			*installErr = [[NSAlert alloc] init];
		if (nsErr != nil)
			installErr.messageText = [NSString stringWithFormat:@"There was a problem installing the CLI (couldn't make the new symlink- %@)",nsErr.localizedDescription];
		else
			installErr.messageText = @"There was a problem installing the CLI (couldn't make the new symlink)";
		installErr.alertStyle = NSAlertStyleCritical;
		[installErr addButtonWithTitle:@"Cancel install"];
		[installErr runModal];
		return;
	}
	//	show an alert informing the user that the command-line tool has been installed...
	NSAlert		*successAlert = [[NSAlert alloc] init];
	successAlert.messageText = @"The command-line tool \"synopsis-enc\" has been successfully installed.\n\rsee \"synopsis-enc --help\" for more information.";
	[successAlert addButtonWithTitle:@"OK"];
	[successAlert runModal];
	
}
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender	{
	//NSLog(@"%s",__func__);
	//	if we're currently processing files, pop a modal alert asking if we really want to quit
	if ([[SessionController global] processingFiles])	{
		NSAlert			*quitAlert = [[NSAlert alloc] init];
		quitAlert.messageText = @"You are analyzing files- are you sure you want to quit?";
		[quitAlert addButtonWithTitle:@"Quit"];
		[quitAlert addButtonWithTitle:@"Don't Quit"];
		NSModalResponse		response = [quitAlert runModal];
		if (response == NSAlertFirstButtonReturn)
			return NSTerminateNow;
		else
			return NSTerminateCancel;
	}
	return NSTerminateNow;
}
/*
- (void) applicationWillTerminate:(NSNotification *)notification	{
}
*/

- (void) application:(NSApplication *)sender openURLs:(NSArray<NSURL *> *)urls	{
	//	when dropping multiple files onto the dock, this method gets called twice: first with a single URL, and then again with the remainder, so we have to coalesce these calls...
	@synchronized (self)	{
		if (self.fileOpenTimer != nil)	{
			[self.fileOpenTimer invalidate];
			self.fileOpenTimer = nil;
		}
		[self.URLsToOpen addObjectsFromArray:urls];
		self.fileOpenTimer = [NSTimer
			scheduledTimerWithTimeInterval:0.25
			repeats:NO
			block:^(NSTimer *inTimer)	{
				@synchronized (self)	{
					[self actuallyOpenURLs:self.URLsToOpen];
					[self.URLsToOpen removeAllObjects];
				}
			}];
	}
	
}
- (void) actuallyOpenURLs:(NSArray<NSURL*> *)n	{
	[[SessionController global] createAndAppendSessionsWithFiles:n];
}
/*
- (NSString *) getSpotlightPKGReceiptVsn	{
	//	first of all, big problem: if the user runs the installer, but manually deletes the file,
	//	the system will still have a receipt for the installer- even though the file no longer exists
	//	so to begin, check for the presence of the plugin and return nil if it cannot be found
	NSFileManager		*fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:@"/Library/Spotlight/SynopsisImporter.mdimporter"])	{
		if (![fm fileExistsAtPath:[@"~/Library/Spotlight/SynopsisImporter.mdimporter" stringByExpandingTildeInPath]])	{
			return nil;
		}
	}
	
	//	...if i'm here then the spotlight plugin (some version of it) exists on disk...
	
	NSTask		*taskA = nil;
	NSTask		*taskB = nil;
	NSTask		*taskC = nil;
	NSPipe		*tmpPipe = nil;
	NSPipe		*outPipe = [NSPipe pipe];
	NSError		*nsErr = nil;
	
	taskA = [[NSTask alloc] init];
	taskA.executableURL = [NSURL fileURLWithPath:@"/usr/sbin/pkgutil" isDirectory:NO];
	taskA.arguments = @[
		@"--pkg-info",
		@"info.v002.Synopsis.SpotlightImporter.pkg.Installer"
	];
	
	taskB = [[NSTask alloc] init];
	taskB.executableURL = [NSURL fileURLWithPath:@"/usr/bin/grep" isDirectory:NO];
	taskB.arguments = @[
		@"-Ei",
		@"version:"
	];
	
	taskC = [[NSTask alloc] init];
	taskC.executableURL = [NSURL fileURLWithPath:@"/usr/bin/grep" isDirectory:NO];
	taskC.arguments = @[
		@"-oEi",
		@"[0-9\\.]+"
	];
	
	tmpPipe = [NSPipe pipe];
	taskA.standardOutput = tmpPipe;
	taskB.standardInput = tmpPipe;
	
	tmpPipe = [NSPipe pipe];
	taskB.standardOutput = tmpPipe;
	taskC.standardInput = tmpPipe;
	
	taskC.standardOutput = outPipe;
	
	
	if (![taskA launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step A couldnt complete in %s",__func__);
		return nil;
	}
	[taskA waitUntilExit];
	if (![taskB launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step B couldnt complete in %s",__func__);
		return nil;
	}
	[taskB waitUntilExit];
	if (![taskC launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step C couldnt complete in %s",__func__);
		return nil;
	}
	[taskC waitUntilExit];
	
	NSFileHandle		*tmpFH = [outPipe fileHandleForReading];
	NSData				*tmpData = [tmpFH readDataToEndOfFile];
	NSString			*vsnString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	
	return vsnString;
}
- (NSString *) getIncludedSpotlightPKGVsn	{
	NSString	*pkgPath = [[NSBundle mainBundle] pathForResource:@"Synopsis Spotlight Plugin" ofType:@"pkg"];
	if (pkgPath == nil)	{
		NSLog(@"ERR: couldnt find embedded pkg, %s",__func__);
		return nil;
	}
	
	NSTask		*taskA = nil;
	NSTask		*taskB = nil;
	NSTask		*taskC = nil;
	NSPipe		*tmpPipe = nil;
	NSPipe		*outPipe = [NSPipe pipe];
	NSError		*nsErr = nil;
	
	taskA = [[NSTask alloc] init];
	taskA.executableURL = [NSURL fileURLWithPath:@"/usr/sbin/pkgutil" isDirectory:NO];
	taskA.arguments = @[
		@"--expand",
		pkgPath,
		@"/tmp/pkg"
	];
	if (![taskA launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: couldnt execute pkgutil in %s",__func__);
		return nil;
	}
	[taskA waitUntilExit];
	
	
	
	taskA = [[NSTask alloc] init];
	taskA.executableURL = [NSURL fileURLWithPath:@"/bin/cat" isDirectory:NO];
	taskA.arguments = @[ @"/tmp/pkg/Distribution" ];
	
	taskB = [[NSTask alloc] init];
	taskB.executableURL = [NSURL fileURLWithPath:@"/usr/bin/grep" isDirectory:NO];
	taskB.arguments = @[ @"<pkg-ref id=\"info.v002.Synopsis.SpotlightImporter.pkg.Installer\" " ];
	
	taskC = [[NSTask alloc] init];
	taskC.executableURL = [NSURL fileURLWithPath:@"/usr/bin/sed" isDirectory:NO];
	taskC.arguments = @[ @"s#.* version=\\\"\\([0-9\\.]*\\)\\\".*#\\1#" ];
	
	tmpPipe = [NSPipe pipe];
	taskA.standardOutput = tmpPipe;
	taskB.standardInput = tmpPipe;
	
	tmpPipe = [NSPipe pipe];
	taskB.standardOutput = tmpPipe;
	taskC.standardInput = tmpPipe;
	
	taskC.standardOutput = outPipe;
	
	
	if (![taskA launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step A couldnt complete in %s",__func__);
		return nil;
	}
	[taskA waitUntilExit];
	if (![taskB launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step B couldnt complete in %s",__func__);
		return nil;
	}
	[taskB waitUntilExit];
	if (![taskC launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: step C couldnt complete in %s",__func__);
		return nil;
	}
	[taskC waitUntilExit];
	
	
	
	NSFileHandle		*tmpFH = [outPipe fileHandleForReading];
	NSData				*tmpData = [tmpFH readDataToEndOfFile];
	NSString			*vsnString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	//NSLog(@"vsnString is %@", vsnString);
	
	
	taskA = [[NSTask alloc] init];
	taskA.executableURL = [NSURL fileURLWithPath:@"/bin/rm" isDirectory:NO];
	taskA.arguments = @[
		@"-rf",
		@"/tmp/pkg"
	];
	if (![taskA launchAndReturnError:&nsErr])	{
		NSLog(@"ERR: cleanup couldnt complete in %s",__func__);
		return nil;
	}
	
	return vsnString;
}
*/


#pragma mark - Prefs

- (void) initSpotlight
{
	//	we have to 'touch' the directory containing the spotlight importer to get the OS to recognize that it exists and start using it
	NSBundle	*mb = [NSBundle mainBundle];
	NSURL		*bundleURL = [mb bundleURL];
	bundleURL = [bundleURL URLByAppendingPathComponent:@"Contents"];
	bundleURL = [bundleURL URLByAppendingPathComponent:@"Library"];
	bundleURL = [bundleURL URLByAppendingPathComponent:@"Spotlight"];
	
	NSTask		*touchTask = [[NSTask alloc] init];
	NSError		*nsErr = nil;
	[touchTask setExecutableURL:[NSURL fileURLWithPath:@"/usr/bin/touch" isDirectory:NO]];
	[touchTask setArguments:@[ [NSString stringWithFormat:@"%@",bundleURL.path] ]];
	[touchTask launchAndReturnError:&nsErr];
	
	/*
	NSURL* spotlightFileURL = nil;
	NSURL* resourceURL = [[NSBundle mainBundle] resourceURL];
	
	spotlightFileURL = [resourceURL URLByAppendingPathComponent:@"spotlight.synopsis"];
	
	if([self.fileManager fileExistsAtPath:[spotlightFileURL path]])
	{
		[self.fileManager removeItemAtPath:[spotlightFileURL path] error:nil];
		
//		  // touch the file, just to make sure
//		  NSError* error = nil;
//		  if(![[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:[NSDate date]} ofItemAtPath:[spotlightFileURL path] error:&error])
//		  {
//			  NSLog(@"Error Initting Spotlight : %@", error);
//		  }
	}
	{
		// See OpenMeta for details
		// Our spotlight trickery file will contain a set of keys we use

		// info_v002_synopsis_dominant_colors = rgb
		NSDictionary* exampleValues = @{@"info_synopsis_version" : @(kSynopsisMetadataVersionValue),
										 @"info_synopsis_descriptors" : @"Black",
										};
		
		[exampleValues writeToFile:[spotlightFileURL path] atomically:YES];
	}
	*/
}


#pragma mark - UI

- (IBAction)openMovies:(id)sender	{
	[[SessionController global] openMovies:sender];
}
- (IBAction) openPreferences:(id)sender	{
	[[SessionController global] revealPreferences:sender];
}
- (IBAction) addWatchFolder:(id)sender	{
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setMessage:@"Select a folder to be watched"];
	
	[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result)	{
		if (result == NSModalResponseOK)	{
			//	make a 'watch folder' session
			NSURL				*watchFolderURL = [openPanel URL];
			BOOL				isDir = NO;
			NSFileManager		*fm = [NSFileManager defaultManager];
			if (![fm fileExistsAtPath:[watchFolderURL path] isDirectory:&isDir] || !isDir)
				return;
			
			SynSession			*watchFolderSession = [SynSession createWithDir:watchFolderURL recursively:NO];
			[watchFolderSession setWatchFolder:YES];
			[[SessionController global] appendWatchFolderSessions:@[ watchFolderSession ]];
		}
	}];
}


- (IBAction) helpSlackChannel:(id)sender	{
	NSURL			*tmpURL = [NSURL URLWithString:@"https://synopsis-discuss.slack.com/"];
	[[NSWorkspace sharedWorkspace] openURL:tmpURL];
}
- (IBAction) helpReportABug:(id)sender	{
	NSURL			*tmpURL = [NSURL URLWithString:@"https://github.com/Synopsis/SynopsisCleanRoom/issues/new"];
	[[NSWorkspace sharedWorkspace] openURL:tmpURL];
}
- (IBAction) helpFAQ:(id)sender	{
	NSURL			*tmpURL = [NSURL URLWithString:@"https://synopsis.video/analyzer/FAQ"];
	[[NSWorkspace sharedWorkspace] openURL:tmpURL];
}


#pragma mark - NSFileManager Delegate -

- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
	BOOL duplicateAllMediaToOutputFolder = NO;
//	  BOOL duplicateFolderStructureOnlyToOutputFolder = NO;
	
	if(duplicateAllMediaToOutputFolder)
	{
		return YES;
	}
	
//	  else if(duplicateFolderStructureOnlyToOutputFolder)
//	  {
//		  if(srcURL.hasDirectoryPath)
//		  {
//			  return YES;
//		  }
//		  {
//			  return NO;
//		  }
//	  }
	else
	{
		NSString* fileType;
		NSError* error;
		
		if(![srcURL getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:&error])
		{
			// Cant get NSURLTypeIdentifierKey seems shady, return NO
			return NO;
		}
		
		if([SynopsisSupportedFileTypes() containsObject:fileType])
		{
			return NO;
		}
		
		if([[srcURL lastPathComponent] hasPrefix:@"."])
		{
			return NO;
		}
	}
	
	return YES;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
	NSLog(@"File Manager should proceed after Error : %@, %@, %@", error, srcURL, dstURL);
	return YES;
}


#pragma mark - NSViewAnimationDelegate & related

/*
- (void) animationDidEnd:(NSAnimation *)animation	{
	@synchronized (self)	{
		self.previewAnimation = nil;
	}
}
- (void) showPreview	{
	@synchronized (self)	{
		if (self.previewAnimation != nil)	{
			[self.previewAnimation stopAnimation];
			self.previewAnimation = nil;
		}
		
		NSRect			winBounds = [windowContentView bounds];
		//	start an animation sliding the preview subview back into the window
		NSRect			previewFrame = [previewSubview frame];
		NSRect			targetPreviewFrame = previewFrame;
		targetPreviewFrame.origin.x = NSMaxX(winBounds) - previewFrame.size.width;
		NSDictionary	*previewAnimDict = @{
			NSViewAnimationTargetKey: previewSubview,
			NSViewAnimationEndFrameKey: [NSValue valueWithRect:targetPreviewFrame]
		};
		//	start an animation shrinking the session subview
		NSRect			sessionFrame = [sessionSubview frame];
		NSRect			targetSessionFrame = winBounds;
		targetSessionFrame.size.width = winBounds.size.width - previewFrame.size.width;
		NSDictionary	*sessionAnimDict = @{
			NSViewAnimationTargetKey: sessionSubview,
			NSViewAnimationEndFrameKey: [NSValue valueWithRect:targetSessionFrame]
		};
		
		self.previewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[ previewAnimDict, sessionAnimDict ]];
		[self.previewAnimation setDelegate:self];
		[self.previewAnimation setDuration:0.25];
		[self.previewAnimation startAnimation];
	}
}
- (void) hidePreview	{
	@synchronized (self)	{
		if (self.previewAnimation != nil)	{
			[self.previewAnimation stopAnimation];
			self.previewAnimation = nil;
		}
	
		NSRect			winBounds = [windowContentView bounds];
		//	start an animation sliding the preview subview off the window
		NSRect			previewFrame = [previewSubview frame];
		NSRect			targetPreviewFrame = previewFrame;
		targetPreviewFrame.origin.x = NSMaxX(winBounds);
		NSDictionary	*previewAnimDict = @{
			NSViewAnimationTargetKey: previewSubview,
			NSViewAnimationEndFrameKey: [NSValue valueWithRect:targetPreviewFrame]
		};
		//	start an animation growing the session subview
		NSRect			sessionVisFrame = [sessionSubview visibleRect];
		NSRect			targetSessionVisFrame = winBounds;
		NSDictionary	*sessionAnimDict = @{
			NSViewAnimationTargetKey: sessionSubview,
			NSViewAnimationEndFrameKey: [NSValue valueWithRect:targetSessionVisFrame]
		};
	
		self.previewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:@[ previewAnimDict, sessionAnimDict ]];
		[self.previewAnimation setDelegate:self];
		[self.previewAnimation setDuration:0.25];
		[self.previewAnimation startAnimation];
	}
}
*/

@end
