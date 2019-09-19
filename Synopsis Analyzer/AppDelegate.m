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

#import "DropFilesView.h"
#import "LogController.h"
#import "PrefsController.h"
#import "Constants.h"

//#import "AnalysisAndTranscodeOperation.h"
//#import "MetadataWriterTranscodeOperation.h"

#import "SessionController.h"
#import "PreferencesViewController.h"
#import "PresetObject.h"




@interface AppDelegate () <NSFileManagerDelegate>


@property (readwrite, strong) NSFileManager* fileManager;

@end




//static NSUInteger kAnalysisOperationIndex = 0;
//static NSUInteger kMetadataOperationIndex = 1;




@implementation AppDelegate

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
		
		
		//	make the various top-level controllers
		[LogController global];
		[PrefsController global];
		[SessionController global];
		
		
		self.fileManager = [[NSFileManager alloc] init];
		[self.fileManager setDelegate:self];
	}
	return self;
}

- (void) awakeFromNib
{
	
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
							[[LogController global] appendSuccessLog:[NSString stringWithFormat:@"Loaded Plugin: %@", classString, nil]];
							
							//[self.prefsAnalyzerArrayController addObject:[[pluginClass alloc] init]];
							NSLog(@"should be adding plugin instance to an array here");
						}
					}
					else
					{
						[[LogController global] appendErrorLog:[NSString stringWithFormat:@"Error Loading Plugin : %@ : %@ %@", possiblePlugin, pluginsPath, loadError.description, nil]];
					}
				}
				else
				{
					[[LogController global] appendErrorLog:[NSString stringWithFormat:@"Error Preflighting Plugin : %@ : %@ %@ %@", possiblePlugin, pluginsPath,  pluginBundle, loadError.description, nil]];
				}
			}
			else
			{
				[[LogController global] appendErrorLog:[NSString stringWithFormat:@"Error Creating Plugin : %@ : %@ %@", possiblePlugin, pluginsPath,	pluginBundle, nil]];
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

	
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
	
}

#pragma mark - Prefs

- (void) initSpotlight
{
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
}


#pragma mark - UI

- (IBAction)openMovies:(id)sender	{
	[[SessionController global] openMovies:sender];
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


#pragma mark - NSSplitViewDelegate


- (BOOL)splitView:(NSSplitView *)sv shouldAdjustSizeOfSubview:(NSView *)view	{
	if (view == sessionSubview)
		return YES;
	else
		return NO;
}
- (BOOL)splitView:(NSSplitView *)sv canCollapseSubview:(NSView *)subview	{
	if (subview == sessionSubview)
		return NO;
	else
		return YES;
}
- (BOOL)splitView:(NSSplitView *)sv shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)divIndex	{
	if (subview == sessionSubview)
		return NO;
	else
		return YES;
}
- (CGFloat)splitView:(NSSplitView *)sv constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)divIndex	{
	//NSLog(@"%s ... %0.2f, %d",__func__,proposedMax,divIndex);
	//return proposedMax;
	return [splitView frame].size.width - [previewSubview frame].size.width - [splitView dividerThickness];
}
- (CGFloat)splitView:(NSSplitView *)sv constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)divIndex	{
	//NSLog(@"%s ... %0.2f, %d",__func__,proposedMin,divIndex);
	//return proposedMin;
	return [splitView frame].size.width - [previewSubview frame].size.width - [splitView dividerThickness];
}



@end
