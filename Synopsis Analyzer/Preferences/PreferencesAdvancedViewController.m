//
//	PreferencesAdvancedViewController.m
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PreferencesAdvancedViewController.h"
#import "Constants.h"
//#import <Synopsis/Synopsis.h>

@interface PreferencesAdvancedViewController ()
@property (readwrite, strong) IBOutlet NSPopUpButton* concurrencyCount;
@end

@implementation PreferencesAdvancedViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do view setup here.
	
	NSNumber* currentConcurrencyCount =	 [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerConcurrentJobCountPreferencesKey];

	NSUInteger maxProcCount = [[NSProcessInfo processInfo] processorCount];
	
	[self.concurrencyCount removeAllItems];

	NSMenuItem* autoConcurrency = [[NSMenuItem alloc] init];
	autoConcurrency.title = @"Auto";
	autoConcurrency.representedObject = @(-1);
	autoConcurrency.target = self;
	autoConcurrency.action = @selector(setConcurrency:);
	
	[[self.concurrencyCount menu] addItem:autoConcurrency];
	
	[[self.concurrencyCount menu] addItem: [NSMenuItem separatorItem]];
	
	for(int i = 0; i < maxProcCount; i++)
	{
		NSMenuItem* item = [[NSMenuItem alloc] init];
		if(i == 0)
			item.title = [NSString stringWithFormat:@"%i Movie at a time", i + 1];
		else
			item.title = [NSString stringWithFormat:@"%i Movies Simultaneously", i + 1];

		item.representedObject = @(i + 1);
		item.target = self;
		item.action = @selector(setConcurrency:);
		[[self.concurrencyCount menu] addItem:item];
		
		if([item.representedObject isEqual:currentConcurrencyCount])
		{
			[self.concurrencyCount selectItem:item];
		}
	}
										 
										 
}
	 
- (IBAction) setConcurrency:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setValue:[sender representedObject] forKey:kSynopsisAnalyzerConcurrentJobCountPreferencesKey];

	[[NSNotificationCenter defaultCenter] postNotificationName:kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification object:self];
}

- (IBAction)enableSimultaneousJobs:(NSButton*)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:@((BOOL)sender.state) forKey:kSynopsisAnalyzerConcurrentJobAnalysisPreferencesKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification object:self];
//	  kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification
}


- (IBAction)enableSimultaneousFrames:(NSButton*)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:@((BOOL)sender.state) forKey:kSynopsisAnalyzerConcurrentFrameAnalysisPreferencesKey];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[[NSNotificationCenter defaultCenter] postNotificationName:kSynopsisAnalyzerConcurrentFrameAnalysisDidChangeNotification object:self];

}

@end
