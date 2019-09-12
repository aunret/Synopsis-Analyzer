//
//  AppDelegate.m
//  SynopsisCleanRoom
//
//  Created by testAdmin on 8/26/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "AppDelegate.h"

#import <Synopsis/Synopsis.h>
#import "SynopsisJobObject.h"




@interface AppDelegate ()	{
	SynopsisJobObject		*job;
}
@property (weak) IBOutlet NSWindow *window;
@end




@implementation AppDelegate


- (id) init	{
	self = [super init];
	if (self != nil)	{
		job = nil;
	}
	return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//	sample audio encoding settings dict
	NSDictionary		*audioSettings = @{
		AVEncoderBitRateStrategyKey: @"AVAudioBitRateStrategy_Variable",
		AVFormatIDKey: [NSNumber numberWithInteger:1633772320]
	};
	//	sample video encoding settings dict
	NSDictionary		*videoSettings = @{
		AVVideoCodecKey: @"avc1",
		AVVideoCompressionPropertiesKey: @{
			@"ProfileLevel": @"H264_High_AutoLevel"
		},
		//VVAVVideoMultiPassEncodeKey: @YES,
		//AVVideoCodecKey: @"jpeg",
		//AVVideoCompressionPropertiesKey: @{
		//	@"Quality": [NSNumber numberWithDouble:0.0]
		//}
	};
	//	sample synopsis settings dict
	NSDictionary		*synopsisSettings = @{
		kSynopsisAnalysisSettingsQualityHintKey : @( SynopsisAnalysisQualityHintMedium ),
		kSynopsisAnalysisSettingsEnabledPluginsKey : @[ @"StandardAnalyzerPlugin" ],
		kSynopsisAnalysisSettingsEnableConcurrencyKey : @TRUE,
	};
	
	
	//	various "source file" URLs- replace with something local to your machine
	//NSURL			*srcURL = [NSURL fileURLWithPath:@"/Volumes/scratch/hap testing/720/jpeg/Blue-720-jpeg.mov" isDirectory:NO];
	//NSURL			*srcURL = [NSURL fileURLWithPath:@"/Volumes/scratch/whoa.mov" isDirectory:NO];
	//NSURL			*srcURL = [NSURL fileURLWithPath:@"/Volumes/scratch/sample movies/PRIMER(2004)- A Movie Youll Have To Watch Twice!!-720p.mp4" isDirectory:NO];
	NSURL			*srcURL = [NSURL fileURLWithPath:@"/Volumes/scratch/sample movies/Primer_FirstTwoMinutes_NonRef.mov" isDirectory:NO];
	//NSURL			*srcURL = [NSURL fileURLWithPath:@"/Volumes/scratch/sample movies/Primer_FirstTenMinutes_NonRef.mov" isDirectory:NO];
	
	
	//	"dest file" URL- replace with something local to your machine
	NSURL			*dstURL = [NSURL fileURLWithPath:@"/Volumes/scratch/hap testing/720/h264/Blue-720-h264.mov" isDirectory:NO];
	
	
	//	tmp dir URL- you don't have to use this, but if you want to test it...this is how
	NSURL			*dstDir = [NSURL fileURLWithPath:@"/Volumes/scratch/hap testing/720/h264" isDirectory:YES];
	
	
	//	if you're writing code, it makes more sense to create the job object this way
	/*
	job = [[SynopsisJobObject alloc]
		initWithSrcFile:srcURL
		dstFile:dstURL
		tmpDir:nil
		videoTransOpts:nil
		audioTransOpts:nil
		synopsisOpts:synopsisSettings];
	*/
	
	
	/*		if you're using (or testing) a CLI, you're going to pass values via a JSON string.  this 
	bit here makes a dict that fully describes the job, turns it into a string, prints the string 
	(so you can copy and use it for testing a CLI), and then runs the job in the cocoa app		*/
	NSDictionary		*jobDict = @{
		kSynopsisSrcFileKey: [srcURL path],
		kSynopsisDstFileKey: [dstURL path],
		kSynopsisTranscodeVideoSettingsKey: videoSettings,
		kSynopsisTranscodeAudioSettingsKey: audioSettings,
		kSynopsisAnalysisSettingsKey: synopsisSettings
	};
	NSError				*nsErr = nil;
	NSData				*tmpData = [NSJSONSerialization dataWithJSONObject:jobDict options:0 error:&nsErr];
	NSString			*reconstituted = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
	//NSLog(@"reconstituted job string is \"%@\"",reconstituted);
	NSLog(@"in the CLI, this jobString would be \"%@\"",[reconstituted stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]);
	job = (reconstituted == nil) ? nil : [SynopsisJobObject createWithJobJSONString:reconstituted completionBlock:^(SynopsisJobObject *theJob) {
		NSLog(@"JOB COMPLETE, took %0.2f second",[theJob jobTimeElapsed]);
	}];
	
	
	
	[job start];
	
	if (job == nil)
		NSLog(@"ERR: NO JOB");
	else
		NSLog(@"job status is %@",[SynopsisJobObject stringForStatus:[job jobStatus]]);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


@end
