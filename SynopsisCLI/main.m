//
//	main.m
//	synopsis_cli
//
//	Created by testAdmin on 9/10/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynopsisJobObject.h"
#import <Synopsis/Synopsis.h>




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
		//	
		//	these are the vals that we're going to populate from the args
		NSString			*srcPath = nil;
		NSString			*dstPath = nil;
		//NSString			*tmpDir = nil;
		NSMutableDictionary		*videoSettings = nil;
		NSMutableDictionary		*audioSettings = nil;
		NSMutableDictionary		*synopsisSettings = nil;
		//	run through the args passed in, parsing them and populating the vars we need
		NSArray				*args = [[NSProcessInfo processInfo] arguments];
		NSEnumerator		*argIt = [args objectEnumerator];
		id					arg = [argIt nextObject];
		arg = [argIt nextObject];	//	we have to skip the first arg (path to binary)
		while (arg != nil)	{
			NSString			*argType = arg;
			arg = [argIt nextObject];
			if (arg == nil)	{
				fprintf(stdout, "ERR: missing value for %s argument\n",[argType UTF8String]);
				return 1;
			}
			
			//	if the user passed a json string describing the job
			if ([argType caseInsensitiveCompare:@"--json"]==NSOrderedSame || [argType caseInsensitiveCompare:@"-j"]==NSOrderedSame)	{
				NSError				*nsErr = nil;
				NSDictionary		*tmpDict = [NSJSONSerialization JSONObjectWithData:[arg dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&nsErr];
				//	if the JSON string couldn't be parsed- bail, something's wrong
				if (tmpDict == nil || nsErr != nil)	{
					fprintf(stdout, "ERR: couldn't parse JSON string");
					if (nsErr != nil)
						fprintf(stdout, ": %s", [[nsErr localizedDescription] UTF8String]);
					fprintf(stdout,"\n");
					return 2;
				}
				//	else the JSON string was parsed- populate the vars from above and then break out of the loop
				else	{
					srcPath = tmpDict[kSynopsisSrcFileKey];
					dstPath = tmpDict[kSynopsisDstFileKey];
					//tmpDir = tmpDict[kSynopsisTmpDirKey];
					videoSettings = tmpDict[kSynopsisTranscodeVideoSettingsKey];
					audioSettings = tmpDict[kSynopsisTranscodeAudioSettingsKey];
					synopsisSettings = tmpDict[kSynopsisAnalysisSettingsKey];
					break;
				}
			}
			//	path settings
			else if ([argType caseInsensitiveCompare:@"--src"]==NSOrderedSame || [argType caseInsensitiveCompare:@"-s"]==NSOrderedSame)	{
				srcPath = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--dst"]==NSOrderedSame || [argType caseInsensitiveCompare:@"-d"]==NSOrderedSame)	{
				dstPath = arg;
			}
			//else if ([argType caseInsensitiveCompare:@"--tmp"]==NSOrderedSame || [argType caseInsensitiveCompare:@"-t"]==NSOrderedSame)	{
			//	tmpDir = arg;
			//}
			//	synopsis settings
			else if ([argType caseInsensitiveCompare:@"--SynopsisQuality"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				synopsisSettings[kSynopsisAnalysisSettingsQualityHintKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisPlugin"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] == nil) synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] = [NSMutableArray arrayWithCapacity:0];
				[synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] addObject:arg];
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisMetadataExport"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				synopsisSettings[kSynopsisAnalyzedMetadataExportOptionKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisGPURegistryID"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				synopsisSettings[kSynopsisDeviceRegistryIDKey] = [NSNumber numberWithLongLong:[arg longLongValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisStrictFrameDecode"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithBool:NO];
				synopsisSettings[kSynopsisStrictFrameDecodeKey] = tmpNum;
			}
			//	video encoder settings
			else if ([argType caseInsensitiveCompare:@"--AVVideoCodecKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoCodecKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoWidthKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoWidthKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoHeightKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoHeightKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoPixelAspectRatioHorizontalSpacingKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				videoSettings[AVVideoPixelAspectRatioHorizontalSpacingKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoPixelAspectRatioVerticalSpacingKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				videoSettings[AVVideoPixelAspectRatioVerticalSpacingKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoScalingModeKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoScalingModeKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoAllowWideColorKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				videoSettings[AVVideoAllowWideColorKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoColorPrimariesKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoColorPropertiesKey] == nil) videoSettings[AVVideoColorPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				[videoSettings[AVVideoColorPropertiesKey] setObject:arg forKey:AVVideoColorPrimariesKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoTransferFunctionKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoColorPropertiesKey] == nil) videoSettings[AVVideoColorPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				[videoSettings[AVVideoColorPropertiesKey] setObject:arg forKey:AVVideoTransferFunctionKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoYCbCrMatrixKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoColorPropertiesKey] == nil) videoSettings[AVVideoColorPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				[videoSettings[AVVideoColorPropertiesKey] setObject:arg forKey:AVVideoYCbCrMatrixKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoAverageBitRateKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoCompressionPropertiesKey] == nil) videoSettings[AVVideoCompressionPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				[videoSettings[AVVideoCompressionPropertiesKey] setObject:arg forKey:AVVideoAverageBitRateKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoQualityKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoCompressionPropertiesKey] == nil) videoSettings[AVVideoCompressionPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				[videoSettings[AVVideoCompressionPropertiesKey] setObject:tmpNum forKey:AVVideoQualityKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoMaxKeyFrameIntervalKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoCompressionPropertiesKey] == nil) videoSettings[AVVideoCompressionPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				[videoSettings[AVVideoCompressionPropertiesKey] setObject:tmpNum forKey:AVVideoMaxKeyFrameIntervalKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoMaxKeyFrameIntervalDurationKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoCompressionPropertiesKey] == nil) videoSettings[AVVideoCompressionPropertiesKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				[videoSettings[AVVideoCompressionPropertiesKey] setObject:tmpNum forKey:AVVideoMaxKeyFrameIntervalDurationKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoAllowFrameReorderingKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				videoSettings[AVVideoAllowFrameReorderingKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoProfileLevelKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoProfileLevelKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoH264EntropyModeKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				videoSettings[AVVideoH264EntropyModeKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoExpectedSourceFrameRateKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				videoSettings[AVVideoExpectedSourceFrameRateKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoAverageNonDroppableFrameRateKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				videoSettings[AVVideoAverageNonDroppableFrameRateKey] = tmpNum;
			}
			//	audio encoder settings
			else if ([argType caseInsensitiveCompare:@"--AVFormatIDKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVFormatIDKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVSampleRateKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVSampleRateKey] = [NSNumber numberWithDouble:[arg doubleValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVNumberOfChannelsKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVNumberOfChannelsKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVLinearPCMBitDepthKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVLinearPCMBitDepthKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVLinearPCMIsBigEndianKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithBool:NO];
				audioSettings[AVLinearPCMIsBigEndianKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVLinearPCMIsFloatKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithBool:NO];
				audioSettings[AVLinearPCMIsFloatKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVLinearPCMIsNonInterleaved"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"true"]==NSOrderedSame || [arg caseInsensitiveCompare:@"yes"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:YES];
				else if ([arg caseInsensitiveCompare:@"false"]==NSOrderedSame || [arg caseInsensitiveCompare:@"no"]==NSOrderedSame)
					tmpNum = [NSNumber numberWithBool:NO];
				else
					tmpNum = [NSNumber numberWithBool:NO];
				audioSettings[AVLinearPCMIsNonInterleaved] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVAudioFileTypeKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVAudioFileTypeKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderAudioQualityKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderAudioQualityKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderAudioQualityForVBRKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderAudioQualityForVBRKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderBitRateKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderBitRateKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderBitRatePerChannelKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderBitRatePerChannelKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderBitRateStrategyKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderBitRateStrategyKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderBitDepthHintKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderBitDepthHintKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVSampleRateConverterAlgorithmKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVSampleRateConverterAlgorithmKey] = arg;
			}
			else if ([argType caseInsensitiveCompare:@"--AVSampleRateConverterAudioQualityKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVSampleRateConverterAudioQualityKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else	{
				fprintf(stdout,"ERR: unrecognized argument, \'%s\'\n",[argType UTF8String]);
				return 3;
			}
			
			//	get the next arg...
			arg = [argIt nextObject];
		}
		
		//NSLog(@"videoSettings: %@",videoSettings);
		//NSLog(@"audioSettings: %@",audioSettings);
		
		//	if we're missing any vital pieces of information, bail with an informative error message
		if (srcPath == nil)	{
			fprintf(stdout,"ERR: no input file specified\n");
			return 4;
		}
		else if (dstPath == nil)	{
			fprintf(stdout,"ERR: no output file specified\n");
			return 5;
		}
		
		//	if there isn't a synopsis settings dict, make one
		if (synopsisSettings == nil)	{
			synopsisSettings = [@{
				kSynopsisAnalysisSettingsQualityHintKey : @( SynopsisAnalysisQualityHintMedium ),
				kSynopsisAnalysisSettingsEnabledPluginsKey : @[ @"StandardAnalyzerPlugin" ],
			} mutableCopy];
		}
		
		
		fprintf(stdout,"Beginning Synopsis analysis/transcode...\n");
		
		
		//	make a dispatch group that we'll enter before starting, and leave upon completion of the job (prevent the task from exiting prematurely)
		dispatch_group_t		completionGroup = dispatch_group_create();
		dispatch_group_enter(completionGroup);
		
		//	make the job object
		SynopsisJobObject			*job = [[SynopsisJobObject alloc]
			initWithSrcFile:[NSURL fileURLWithPath:srcPath isDirectory:NO]
			dstFile:[NSURL fileURLWithPath:dstPath isDirectory:NO]
			videoTransOpts:videoSettings
			audioTransOpts:audioSettings
			synopsisOpts:synopsisSettings
			device:nil
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
		return 6;
		
	}
	return 0;
}
