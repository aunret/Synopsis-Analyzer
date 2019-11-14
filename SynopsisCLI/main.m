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
	fprintf(stdout,"\n");
	fprintf(stdout, "\tsynopsis-enc--  Analyze (and optionally transcode) a media file using Synopsis to generate global and per-frame metadata describing the media file's contents.\n");
	fprintf(stdout,"\n");
	
	fprintf(stdout, "USAGE:\n");
	//fprintf(stdout, "\tsynopsis_cli <json string describing the analysis details>\n");
	fprintf(stdout, "\tsynopsis-enc [options]\n");
	fprintf(stdout,"\n");
	
	
	fprintf(stdout, "REQUIRED OPTIONS:\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--help\n");
	fprintf(stdout,"\t\tprints information describing how to use this utility\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--src\n");
	fprintf(stdout,"\t\tMandatory- the path to the input source file (file to be analyzed/transcoded)\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--dst\n");
	fprintf(stdout,"\t\tMandatory- the path to the output file\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\n");
	
	
	fprintf(stdout, "SYNOPSIS OPTIONS\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--SynopsisQuality\n");
	fprintf(stdout,"\t\tOptional- the quality at which Synopsis will perform analysis.  Accepted values are \"Low\", \"Medium\", \"High\", and \"Original\".  If no quality is specified, \"Medium\" will be used.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--SynopsisPlugin\n");
	fprintf(stdout,"\t\tOptional- the plugin to be used to analyze the source file.  Multiple plugins may be specified by using this switch multiple times.  The standard analysis plugin is \"StandardAnalyzerPlugin\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--SynopsisMetadataExport\n");
	fprintf(stdout,"\t\tOptional- What kind of additional metadata export will be performed (a metadata track will be created regardless, this switch allows you to export the metadata as an additional file).  Accepted values are \"None\", \"JSONContiguous\", \"JSONGlobal\", \"JSONSequence\", or \"ZSTDTraining\".  The default value is \"None\" (if unspecified, no additional metadata file will be created).\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--SynopsisGPURegistryID\n");
	fprintf(stdout,"\t\tOptional- an unsigned 64-bit integer describing the GPU Synopsis will use to perform analysis.  If not provided, Synopsis will automatically use the system-default Metal device.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--SynopsisStrictFrameDecode\n");
	fprintf(stdout,"\t\tOptional, expects a boolean value indicating whether or not Synopsis will be strict about requiring frame decodes.  If a true value is provided, the inability to decode a frame from the source file will cause an error, cancelling the job.  Default value is true.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\n");
	
	
	fprintf(stdout, "VIDEO OPTIONS- consult <AVFoundation/AVVideoSettings.h> or <AVFoundation/AVAudioSettings.h> for more information about the details of some of these options and how they work with AVFoundation, which is used for transcoding.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--AVVideoCodecKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Specifies the codec that the source file will be transcoded into.  If not provided, the source file will be analyzed, but not transcoded (the output file will have the same codec).  Accepted values are listed in <AVFoundation/AVVideoSettings.h>.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--AVVideoWidthKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Expects an integer value describing the width of the output video.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--AVVideoHeightKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Expects an integer value describing the height of the output video.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--AVVideoPixelAspectRatioHorizontalSpacingKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  If you provide a value for this key, you are also expected to provide a value for AVVideoPixelAspectRatioVerticalSpacingKey.  Expected Value is a number describing the aspect ratio of the pixels in the output movie.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\t--AVVideoPixelAspectRatioVerticalSpacingKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  If you provide a value for this key, you are also expected to provide a value for AVVideoPixelAspectRatioHorizontalSpacingKey.  Expected Value is a number describing the aspect ratio of the pixels in the output movie.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoScalingModeKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Describes how the video will be scaled up/down if it's being resized.  Accepted values are \"Fit\", \"Resize\", \"ResizeAspect\", or \"ResizeAspectFill\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoAllowWideColorKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Expects a boolean value describing whether the utility will process wide color.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoColorPrimariesKey\n");
	fprintf(stdout,"\t\tOptonal- only used if the video is being transcoded.  Accepted values are listed in <AVFoundation/AVVideoSettings.h>.  If you provide a value for this switch, you should also provide values for \"AVVideoTransferFunctionKey\" and \"AVVideoYCbCrMatrixKey\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoTransferFunctionKey\n");
	fprintf(stdout,"\t\tOptonal- only used if the video is being transcoded.  Accepted values are listed in <AVFoundation/AVVideoSettings.h>.  If you provide a value for this switch, you should also provide values for \"AVVideoColorPrimariesKey\" and \"AVVideoYCbCrMatrixKey\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoYCbCrMatrixKey\n");
	fprintf(stdout,"\t\tOptonal- only used if the video is being transcoded.  Accepted values are listed in <AVFoundation/AVVideoSettings.h>.  If you provide a value for this switch, you should also provide values for \"AVVideoTransferFunctionKey\" and \"AVVideoColorPrimariesKey\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoAverageBitRateKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded, and if the H.264 codec is being used.  Expects a number describing the number of bits per second.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoQualityKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded, and if the JPEG or HEIC codec is being used.  Expects a number value ranged 0.-1. describing the subjective quality of the video encoding (1.0 indicates lossless or as close to lossless as possible).\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoMaxKeyFrameIntervalKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded, and if the H.264 codec is being used.  Expects a number- 1 means keyframes only.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoMaxKeyFrameIntervalDurationKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded, and if the H.264 codec is being used.  Expects a number describing the number of seconds- 0.0 means no limit.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoAllowFrameReorderingKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Expects a boolean value indicating whether or not the frames can be reordered during encoding.  The default value is yes, which means the encoder decides whether to implement frame reordering.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoProfileLevelKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded and H.264 or HEVC are being used.  Acceptable values are listed in <AVFoundation/AVVideoSettings.h>.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoH264EntropyModeKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded and H.264 is being used.  The entropy encoding mode for H.264 compression.  Accepted values are \"CAVLC\" or \"CABAC\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoExpectedSourceFrameRateKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  Indicates the expected source framerate, if known, in frames per second.  This should be set if an AutoLevel AVVideoProfileLevelKey is used, or if the source content has a high frame rate (higher than 30 fps). The encoder might have to drop frames to satisfy bit stream requirements if this key is not specified.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVVideoAverageNonDroppableFrameRateKey\n");
	fprintf(stdout,"\t\tOptional- only used if the video is being transcoded.  The desired average number of non-droppable frames to be encoded for each second of video.\n");
	fprintf(stdout,"\n");
	fprintf(stdout,"\n");
	
	
	fprintf(stdout, "AUDIO OPTIONS- consult <AVFoundation/AVVideoSettings.h> or <AVFoundation/AVAudioSettings.h> for more information about the details of some of these options and how they work with AVFoundation, which is used for transcoding.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVFormatIDKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  An integer value describing the audio format to be used- more info can be found in CoreAudioTypes.h\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVSampleRateKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded- expects a floating point value in Hertz.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVNumberOfChannelsKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded- expects an integer describiing the number of channels.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVLinearPCMBitDepthKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded and the output format is Linear PCM.  Expected value is an integer- one of 8, 16, 24, or 32.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVLinearPCMIsBigEndianKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded and the output format is Linear PCM.  Expects a boolean value indicating whether the Linear PCM is big-endian.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVLinearPCMIsFloatKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded and the output format is Linear PCM.  Expects a boolean value indicating whether the Linear PCM is floating-point.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVLinearPCMIsNonInterleaved\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded and the output format is Linear PCM.  Expects a boolean value indicating whether the Linear PCM is interleaved.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVAudioFileTypeKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Expected value is an integer describing the audio file type- acceptable values are listed in AudioFile.h\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderAudioQualityKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Acceptable values are \"min\", \"low\", \"medium\", \"high\", or \"max\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderAudioQualityForVBRKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded and if \"AVEncoderBitRateStrategyKey\" is \"variable\".  Acceptable values are \"min\", \"low\", \"medium\", \"high\", or \"max\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderBitRateKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Expected value is an integer describing the bitrate of the output file.  Only use one of this or AVEncoderBitRatePerChannelKey.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderBitRatePerChannelKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Expected value is an integer describing the per-channel bitrate of the output file.  Only use one of this or AVEncoderBitRateKey.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderBitRateStrategyKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Acceptable values are \"constant\", \"longTermAverage\", \"variableConstrained\", or \"variable\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVEncoderBitDepthHintKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Expected value is an integer between 8 and 32.\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVSampleRateConverterAlgorithmKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Acceptable values are \"normal\", \"mastering\", or \"minimumPhase\".\n");
	fprintf(stdout,"\n");
	fprintf(stdout, "\t--AVSampleRateConverterAudioQualityKey\n");
	fprintf(stdout,"\t\tOptional- only used if the audio is being transcoded.  Acceptable values are \"min\", \"low\", \"medium\", \"high\", or \"max\"\n");
	
	/*
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
	*/
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
			
			if ([argType caseInsensitiveCompare:@"--help"]==NSOrderedSame || [argType caseInsensitiveCompare:@"-h"]==NSOrderedSame)	{
				usage();
				return 0;
			}
			
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
			//	synopsis settings
			else if ([argType caseInsensitiveCompare:@"--SynopsisQuality"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"Low"] == NSOrderedSame)
					tmpNum = @( SynopsisAnalysisQualityHintLow );
				else if ([arg caseInsensitiveCompare:@"Medium"] == NSOrderedSame)
					tmpNum = @( SynopsisAnalysisQualityHintMedium );
				else if ([arg caseInsensitiveCompare:@"High"] == NSOrderedSame)
					tmpNum = @( SynopsisAnalysisQualityHintHigh );
				else if ([arg caseInsensitiveCompare:@"Original"] == NSOrderedSame)
					tmpNum = @( SynopsisAnalysisQualityHintOriginal );
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				synopsisSettings[kSynopsisAnalysisSettingsQualityHintKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisPlugin"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] == nil) synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] = [NSMutableArray arrayWithCapacity:0];
				[synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] addObject:arg];
			}
			else if ([argType caseInsensitiveCompare:@"--SynopsisMetadataExport"]==NSOrderedSame)	{
				if (synopsisSettings == nil) synopsisSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"None"] == NSOrderedSame)
					tmpNum = @( SynopsisMetadataEncoderExportOptionNone );
				else if ([arg caseInsensitiveCompare:@"JSONContiguous"] == NSOrderedSame)
					tmpNum = @( SynopsisMetadataEncoderExportOptionJSONContiguous );
				else if ([arg caseInsensitiveCompare:@"JSONGlobal"] == NSOrderedSame)
					tmpNum = @( SynopsisMetadataEncoderExportOptionJSONGlobalOnly );
				else if ([arg caseInsensitiveCompare:@"JSONSequence"] == NSOrderedSame)
					tmpNum = @( SynopsisMetadataEncoderExportOptionJSONSequence );
				else if ([arg caseInsensitiveCompare:@"ZSTDTraining"] == NSOrderedSame)
					tmpNum = @( SynopsisMetadataEncoderExportOptionZSTDTraining );
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				synopsisSettings[kSynopsisAnalyzedMetadataExportOptionKey] = tmpNum;
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
				if (videoSettings[AVVideoPixelAspectRatioKey] == nil) videoSettings[AVVideoPixelAspectRatioKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				[videoSettings[AVVideoPixelAspectRatioKey] setObject:tmpNum forKey:AVVideoPixelAspectRatioHorizontalSpacingKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoPixelAspectRatioVerticalSpacingKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				if (videoSettings[AVVideoPixelAspectRatioKey] == nil) videoSettings[AVVideoPixelAspectRatioKey] = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber		*tmpNum = nil;
				if ((double)[arg integerValue] == [arg doubleValue])
					tmpNum = [NSNumber numberWithInteger:[arg integerValue]];
				else
					tmpNum = [NSNumber numberWithDouble:[arg doubleValue]];
				[videoSettings[AVVideoPixelAspectRatioKey] setObject:tmpNum forKey:AVVideoPixelAspectRatioVerticalSpacingKey];
			}
			else if ([argType caseInsensitiveCompare:@"--AVVideoScalingModeKey"]==NSOrderedSame)	{
				if (videoSettings == nil) videoSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSString			*tmpVal = nil;
				if ([arg caseInsensitiveCompare:@"Fit"] == NSOrderedSame)
					tmpVal = AVVideoScalingModeFit;
				else if ([arg caseInsensitiveCompare:@"Resize"] == NSOrderedSame)
					tmpVal = AVVideoScalingModeResize;
				else if ([arg caseInsensitiveCompare:@"ResizeAspect"] == NSOrderedSame)
					tmpVal = AVVideoScalingModeResizeAspect;
				else if ([arg caseInsensitiveCompare:@"ResizeAspectFill"] == NSOrderedSame)
					tmpVal = AVVideoScalingModeResizeAspectFill;
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				videoSettings[AVVideoScalingModeKey] = tmpVal;
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
				NSString			*tmpVal = nil;
				if ([arg caseInsensitiveCompare:@"CAVLC"] == NSOrderedSame)
					tmpVal = AVVideoH264EntropyModeCAVLC;
				else if ([arg caseInsensitiveCompare:@"CABAC"] == NSOrderedSame)
					tmpVal = AVVideoH264EntropyModeCABAC;
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				videoSettings[AVVideoH264EntropyModeKey] = tmpVal;
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
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"min"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMin );
				else if ([arg caseInsensitiveCompare:@"low"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityLow );
				else if ([arg caseInsensitiveCompare:@"medium"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMedium );
				else if ([arg caseInsensitiveCompare:@"high"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityHigh );
				else if ([arg caseInsensitiveCompare:@"max"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMax );
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				audioSettings[AVEncoderAudioQualityKey] = tmpNum;
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderAudioQualityForVBRKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"min"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMin );
				else if ([arg caseInsensitiveCompare:@"low"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityLow );
				else if ([arg caseInsensitiveCompare:@"medium"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMedium );
				else if ([arg caseInsensitiveCompare:@"high"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityHigh );
				else if ([arg caseInsensitiveCompare:@"max"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMax );
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				audioSettings[AVEncoderAudioQualityForVBRKey] = tmpNum;
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
				NSString			*tmpVal = nil;
				if ([arg caseInsensitiveCompare:@"constant"] == NSOrderedSame)
					tmpVal = AVAudioBitRateStrategy_Constant;
				else if ([arg caseInsensitiveCompare:@"longTermAverage"] == NSOrderedSame)
					tmpVal = AVAudioBitRateStrategy_LongTermAverage;
				else if ([arg caseInsensitiveCompare:@"variableConstrained"] == NSOrderedSame)
					tmpVal = AVAudioBitRateStrategy_VariableConstrained;
				else if ([arg caseInsensitiveCompare:@"variable"] == NSOrderedSame)
					tmpVal = AVAudioBitRateStrategy_Variable;
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				audioSettings[AVEncoderBitRateStrategyKey] = tmpVal;
			}
			else if ([argType caseInsensitiveCompare:@"--AVEncoderBitDepthHintKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				audioSettings[AVEncoderBitDepthHintKey] = [NSNumber numberWithInteger:[arg integerValue]];
			}
			else if ([argType caseInsensitiveCompare:@"--AVSampleRateConverterAlgorithmKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSString			*tmpVal = nil;
				if ([arg caseInsensitiveCompare:@"normal"] == NSOrderedSame)
					tmpVal = AVSampleRateConverterAlgorithm_Normal;
				else if ([arg caseInsensitiveCompare:@"mastering"] == NSOrderedSame)
					tmpVal = AVSampleRateConverterAlgorithm_Mastering;
				else if ([arg caseInsensitiveCompare:@"minimumPhase"] == NSOrderedSame)
					tmpVal = AVSampleRateConverterAlgorithm_MinimumPhase;
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				audioSettings[AVSampleRateConverterAlgorithmKey] = tmpVal;
			}
			else if ([argType caseInsensitiveCompare:@"--AVSampleRateConverterAudioQualityKey"]==NSOrderedSame)	{
				if (audioSettings == nil) audioSettings = [NSMutableDictionary dictionaryWithCapacity:0];
				NSNumber			*tmpNum = nil;
				if ([arg caseInsensitiveCompare:@"min"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMin );
				else if ([arg caseInsensitiveCompare:@"low"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityLow );
				else if ([arg caseInsensitiveCompare:@"medium"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMedium );
				else if ([arg caseInsensitiveCompare:@"high"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityHigh );
				else if ([arg caseInsensitiveCompare:@"max"] == NSOrderedSame)
					tmpNum = @( AVAudioQualityMax );
				else	{
					fprintf(stdout,"ERR: unrecognized value (%s) for switch %s\n",[arg UTF8String],[argType UTF8String]);
					return 2;
				}
				audioSettings[AVSampleRateConverterAudioQualityKey] = tmpNum;
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
		if (synopsisSettings[kSynopsisAnalysisSettingsQualityHintKey] == nil)
			synopsisSettings[kSynopsisAnalysisSettingsQualityHintKey] = @( SynopsisAnalysisQualityHintMedium );
		if (synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] == nil || [synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] count] < 1)
			synopsisSettings[kSynopsisAnalysisSettingsEnabledPluginsKey] = @[ @"StandardAnalyzerPlugin" ];
		
		
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
