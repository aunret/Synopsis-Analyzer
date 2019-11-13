//
//	main.m
//	synopsis_cli
//
//	Created by testAdmin on 9/10/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynopsisJobObject.h"




void usage()	{
	fprintf(stdout, "USAGE:\n");
	fprintf(stdout, "\tsynopsis_cli <json string describing the analysis details>\n");
	fprintf(stdout, "\n");
	fprintf(stdout, "RECOGNIZED KEYS:\n");
	fprintf(stdout, "- \"SrcFile\": Mandatory- a string describing the path to the source file.\n");
	fprintf(stdout, "- \"DstFile\": Mandatory- a string describing the path to the output file.\n");
	fprintf(stdout, "- \"TmpDir\": Optional- a string describing the path to the temp directory (in-progress files are written here).  If not provided, no temp directory will be used (file will be written directly to destination).\n");
	fprintf(stdout, "- \"VideoSettings\": Optional- if you want to transcode the video, the associated value is a JSON object containing information describing the video transcode.  Appropriate values are described in the \"Video output settings\" section of \"AVFoundation Constants\" in Apple's AVFoundation documentation.\n");
	fprintf(stdout, "\t- \"StripTrack\": Optional, only used in \"VideoSettings\" or \"AudioSettings\" objects.  Associated value is either a boolean or an integer- if the value is positive (>0 or true), the associated tracks will be stripped during transcode.\n");
	fprintf(stdout, "- \"AudioSettings\": Optional- if you want to transcode the audio, the associated value is a JSON object containing information describing the audio transcode.  Appropriate values are described in the \"Audio output settings\" section of \"AVFoundation Constants\" in Apple's AVFoundation documentation.\n");
	fprintf(stdout, "\t- \"StripTrack\": Optional, only used in \"VideoSettings\" or \"AudioSettings\" objects.  Associated value is either a boolean or an integer- if the value is positive (>0 or true), the associated tracks will be stripped during transcode.\n");
	fprintf(stdout, "- \"SynopsisSettings\": Optional- if you want to perform Synopsis analysis on the file, the associated value is a JSON object containing information describing the analysis.\n");
	fprintf(stdout, "\t- \"AnalysisQuality\": Only used in \"SynopsisSettings\" object.  Associated value is a number corresponding to the SynopsisAnalysisQualityHint enum value.  Optional- if not provided, the job will default to \'SynopsisAnalysisQualityHintOriginal\'.\n");
	//fprintf(stdout, "\t- EnableConcurrency: Associated value is\n");
	fprintf(stdout, "\t- \"EnabledPlugins\": Only used in \"SynopsisSettings\" object.  Mandatory.  Associated value is an array of strings listing the plugins you want the job to use when analyzing the source file.  If no plugins are listed, no analysis will be performed.  If you want to analyze a file, you should include- at minimum- \"StandardAnalyzerPlugin\" in this array.\n");
	fprintf(stdout, "\t- \"ExportMetadata\": Only used in \"SynopsisSettings\" object.  Optional.  Associated value is a number corresponding to the SynopsisMetadataEncoderExportOption enum value.  If not provided, metadata will still be embedded in the output file as a metadata track, but it will not be exported as an additional file.\n");
	fprintf(stdout, "\t- \"DeviceRegistry\": Only used in \"SynopsisSettings\" object.  Optional.  Associated value is a 64-bit unsigned integer describing the \"registryID\" property of the MTLDevice you want Synopsis to use for analysis- if not provided, Synopsis will use the system default Metal device for analysis.\n");
	fprintf(stdout, "\t- \"StrictFrameDecode\": Only used in \"SynopsisSettings\" object.  Optional.  Associated value is a boolean indicating whether frames that could not be decoded will cause the job to error.  If not provided, defaults to \"true\" (the job will fail/error out if AVFoundation is unable to decode any frames from the source movie.)\n");
}

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		//	make sure the # of args is correct
		NSArray				*args = [[NSProcessInfo processInfo] arguments];
		//NSLog(@"args are %@",args);
		if ([args count] != 2)	{
			fprintf(stdout,"ERR: must have exactly one arg\n");
			//NSString			*tmpString = [args description];
			//fprintf(stdout,"args were %s\n",[tmpString UTF8String]);
			usage();
			return 1;
		}
		else if (args.count == 2
		&& ([args[1] caseInsensitiveCompare:@"-h"]==NSOrderedSame
			|| [args[1] caseInsensitiveCompare:@"--help"]==NSOrderedSame))	{
			usage();
			return 0;
		}
		//	make sure the passed arg is a valid JSON object
		NSError				*nsErr = nil;
		NSDictionary		*tmpDict = [NSJSONSerialization JSONObjectWithData:[args[1] dataUsingEncoding:NSUTF8StringEncoding] options:nil error:&nsErr];
		if (tmpDict == nil || nsErr != nil)	{
			fprintf(stdout, "ERR: couldn't parse JSON string");
			if (nsErr != nil)
				fprintf(stdout, ": %s", [[nsErr localizedDescription] UTF8String]);
			fprintf(stdout,"\n");
			return 2;
		}
		//	make sure that the JSON object is of the correct type
		if (![tmpDict isKindOfClass:[NSDictionary class]])	{
			fprintf(stdout, "ERR: JSON string must describe a JSON object\n");
			return 3;
		}
		
		
		fprintf(stdout,"Beginning Synopsis analysis/transcode...\n");
		
		
		//	make a dispatch group that we'll enter before starting, and leave upon completion of the job (prevent the task from exiting prematurely)
		dispatch_group_t		completionGroup = dispatch_group_create();
		dispatch_group_enter(completionGroup);
		
		//	make the job object
		SynopsisJobObject			*job = [SynopsisJobObject
			createWithJobJSONString:args[1]
			completionBlock:^(SynopsisJobObject *theJob)	{
				dispatch_group_leave(completionGroup);
			}];
		//	start the job...
		[job start];
		
		//	wait for the dispatch group to be notified before we return
		dispatch_group_wait(completionGroup, DISPATCH_TIME_FOREVER);
		
		//	if there weren't any errors, just return immediately
		if ([job jobStatus] == JOStatus_Complete)	{
			fprintf(stdout, "JOB COMPLETE, took %0.2f seconds\n",[job jobTimeElapsed]);
			return 0;
		}
		
		//	if i'm here, there was some kind of error- print out some information about it
		NSString		*statusString = [SynopsisJobObject stringForStatus:[job jobStatus]];
		NSString		*errTypeString = [SynopsisJobObject stringForErrorType:[job jobErr]];
		NSString		*errString = [job jobErrString];
		fprintf(stderr, "status is %s\n",[statusString UTF8String]);
		if ([job jobStatus] == JOStatus_Err)	{
			fprintf(stderr, "err type is %s\n",[errTypeString UTF8String]);
			fprintf(stderr, "err detail is %s\n",[errString UTF8String]);
		}
		return 4;
	}
	return 0;
}
