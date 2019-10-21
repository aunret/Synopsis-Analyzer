//
//  SynopsisJobObject.m
//  SynopsisCleanRoom
//
//  Created by testAdmin on 8/26/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SynopsisJobObject.h"
#import <Synopsis/Synopsis.h>
#import <Metal/Metal.h>
#import <HapInAVFoundation/HapInAVFoundation.h>
#import <pthread.h>
#include <sys/xattr.h>
#include <VideoToolbox/VideoToolbox.h>



#pragma mark - keys used in JSON object init methods




NSString * const kSynopsisSrcFileKey = @"kSynopsisSrcFileKey";
NSString * const kSynopsisDstFileKey = @"kSynopsisDstFileKey";
NSString * const kSynopsisTmpDirKey = @"kSynopsisTmpDirKey";
NSString * const kSynopsisTranscodeVideoSettingsKey = @"kSynopsisTranscodeVideoSettingsKey";
NSString * const kSynopsisTranscodeAudioSettingsKey = @"kSynopsisTranscodeAudioSettingsKey";


NSString * const kSynopsisAnalysisSettingsKey = @"kSynopsisAnalysisSettingsKey";
NSString * const kSynopsisAnalysisSettingsQualityHintKey = @"kSynopsisAnalysisSettingsQualityHintKey";
NSString * const kSynopsisAnalysisSettingsEnableConcurrencyKey = @"kSynopsisAnalysisSettingsEnableConcurrencyKey";
NSString * const kSynopsisAnalysisSettingsEnabledPluginsKey = @"kSynopsisAnalysisSettingsEnabledPluginsKey";
NSString * const kSynopsisAnalysisSettingsEnabledPluginModulesKey = @"kSynopsisAnalysisSettingsEnabledPluginModulesKey";
NSString * const kSynopsisAnalyzedMetadataExportOptionKey = @"kSynopsisAnalyzedMetadataExportOptionKey";


NSString * const VVAVVideoMultiPassEncodeKey = @"VVAVVideoMultiPassEncodeKey";
NSString * const kSynopsisStripTrackKey = @"kSynopsisStripTrackKey";




static const CGRect lowQuality = (CGRect) { 0, 0, 160, 120 };
static const CGRect mediumQuality = (CGRect) { 0, 0, 320, 240 };
static const CGRect highQuality = (CGRect) { 0, 0, 640, 480 };
static inline CGRect RectForQualityHint(CGRect inRect, SynopsisAnalysisQualityHint inQuality)
{
    switch (inQuality)
    {
        case SynopsisAnalysisQualityHintLow:
        {
            return CGRectStandardize(AVMakeRectWithAspectRatioInsideRect(inRect.size, lowQuality));
            break;
        }
        case SynopsisAnalysisQualityHintMedium:
        {
            return CGRectStandardize(AVMakeRectWithAspectRatioInsideRect(inRect.size, mediumQuality));
            break;
        }
        case SynopsisAnalysisQualityHintHigh:
        {
            return CGRectStandardize(AVMakeRectWithAspectRatioInsideRect(inRect.size, highQuality));
            break;
        }
        case SynopsisAnalysisQualityHintOriginal:
            return CGRectStandardize(inRect);
            break;
    }

}




#pragma mark - SynopsisJobObject private impl




@interface SynopsisJobObject ()	{
	AVAsset						*asset;
	AVAssetReader				*reader;
	AVAssetWriter				*writer;
	SynopsisMetadataEncoder		*synopsisEncoder;
	dispatch_queue_t			videoWriterQueue;
	dispatch_queue_t			audioWriterQueue;
	dispatch_queue_t			miscWriterQueue;
	dispatch_queue_t			analysisQueue;
	dispatch_group_t			analysisGroup;
	BOOL						paused;
	pthread_mutex_t				theLock;
	/*	the following input/output arrays all have the same number of items (same as the # of tracks).  
	each track corresponds to a "reader output" and a "writer input"- the other arrays have an NSNull 
	as a placeholder.  it's configured like this so we can iterate across all the arrays at the same 
	time, and at each iteration there will always/only be one or two "reader outputs" and one or two
	"writer inputs" that we know are associated with one another.		*/
	NSMutableArray				*readerVideoPassthruOutputs;	//	outputs for tracks that are NOT being transcoded!
	NSMutableArray				*readerVideoAnalysisOutputs;	//	provides video that will be used for analysis (and transcoding)
	NSMutableArray				*readerAudioPassthruOutputs;	//	outputs for tracks that are NOT being transcoded!
	NSMutableArray				*readerAudioAnalysisOutputs;	//	provides audio that will be used for analysis (and transcoding)
	NSMutableArray				*readerMiscPassthruOutputs;	//	used to ensure that tracks which are neither video nor audio are preserved
	NSMutableArray				*writerVideoInputs;	//	will rx from either a reader video passthru output (already encoded) or a reader video analysis output (needs to be trancoded)
	NSMutableArray				*writerAudioInputs;	//	will rx from either a reader audio passthru output (already encoded) or a reader audio trans output (needs to be transcoded)
	NSMutableArray				*writerMiscInputs;	//	will rx from a reader misc passthru output
	NSMutableArray				*writerMetadataInputs;	//	will rx from analysis, which gets data from a reader video analysis output
	NSMutableArray				*writerMetadataInputAdapters;
}
@property (atomic, strong) NSURL * srcFile;
@property (atomic, strong) NSURL * dstFile;

@property (atomic, strong) id<MTLDevice> device;

//@property (atomic, strong) NSURL * tmpDirectory;
//@property (atomic, strong) NSURL * tmpFile;
@property (atomic, copy) void (^completionBlock)(SynopsisJobObject *theJob);

@property (atomic, strong) NSMutableDictionary * videoTransOpts;
@property (atomic, strong) NSMutableDictionary * audioTransOpts;
@property (atomic, strong) NSMutableDictionary * synopsisOpts;

@property (atomic, strong) NSMutableArray * availableAnalyzers;
@property (atomic, strong) NSMutableDictionary * globalMetadata;

//	sometimes, under some specific circumstances, calling -[AVAssetReaderTrackOutput copyNextSampleBuffer] will hang, 
//	and just...not return.  we store the date of the last successfully-retrieved normalized video buffer here, and if 
//	it's ever non-nil AND longer than 10 seconds from now, we assume the job has hung and needs to be errored out.
@property (atomic,strong,readwrite,nullable) NSDate * dateOfLastCopiedNormalizedVideoBuffer;

//- (void) _checkIfActuallyFinished:(int)inCheckCount;
- (void) _finishWritingAndCleanUp;
- (void) _cancelAndCleanUp;
- (void) _cleanUp;

- (BOOL) file:(NSURL *)fileURL xattrSetPlist:(id)plist forKey:(NSString *)key;

@end




#pragma mark -




@implementation SynopsisJobObject


+ (NSString *) stringForStatus:(JOStatus)inStatus	{
	NSString		*returnMe = nil;
	switch (inStatus)	{
	case JOStatus_Unknown:		returnMe = @"Unknown";		break;
	case JOStatus_NotStarted:	returnMe = @"Not Started";	break;
	case JOStatus_InProgress:	returnMe = @"In Progress";	break;
	case JOStatus_Err:			returnMe = @"Error";		break;
	case JOStatus_Complete:		returnMe = @"Complete";		break;
	case JOStatus_Cancel:		returnMe = @"Cancelled";	break;
	case JOStatus_Paused:		returnMe = @"Paused";		break;
	}
	return returnMe;
}
+ (NSString *) stringForErrorType:(JOErr)inErr	{
	NSString		*returnMe = nil;
	switch (inErr)	{
	case JOErr_NoErr:			returnMe = @"No Error";			break;
	case JOErr_NoSrcFile:		returnMe = @"No Src File";		break;
	case JOErr_CantWriteDest:	returnMe = @"Cant write dst";	break;
	case JOErr_AVFErr:			returnMe = @"AVF Err";			break;
	case JOErr_Transcode:		returnMe = @"Transcode Err";	break;
	case JOErr_Analysis:		returnMe = @"Analysis Err";		break;
	case JOErr_File:			returnMe = @"File Err";			break;
	}
	return returnMe;
}


+ (instancetype) createWithJobJSONString:(NSString *)inJSONStr device:(id<MTLDevice>)device completionBlock:(void (^)(SynopsisJobObject *theJob))inCompletionBlock	{
	//NSLog(@"%s",__func__);
	//	if we were passed a nil JSON object, bail and return nil
	if (inJSONStr == nil)	{
		NSLog(@"ERR: bailing, inJSONStr nil");
		return nil;
	}
	
	NSData			*tmpData = [inJSONStr dataUsingEncoding:NSUTF8StringEncoding];
	NSError			*nsErr = nil;
	NSDictionary	*tmpJSONObj = [NSJSONSerialization JSONObjectWithData:tmpData options:0 error:&nsErr];
	//NSLog(@"\t\ttmpJSONObj = %@",tmpJSONObj);
	NSString		*tmpSrc = tmpJSONObj[kSynopsisSrcFileKey];
	NSString		*tmpDst = tmpJSONObj[kSynopsisDstFileKey];
	//NSString		*tmpDir = tmpJSONObj[kSynopsisTmpDirKey];
	NSDictionary	*tmpVideoDict = tmpJSONObj[kSynopsisTranscodeVideoSettingsKey];
	NSDictionary	*tmpAudioDict = tmpJSONObj[kSynopsisTranscodeAudioSettingsKey];
	NSDictionary	*tmpSynopsisDict = tmpJSONObj[kSynopsisAnalysisSettingsKey];
	
	//	if the src file, dst file, or synopsis settings dict were nil, bail and return nil
	if (tmpSrc==nil || tmpDst==nil)	{
		NSLog(@"ERR: bailing, src or dst nil");
		//NSLog(@"src is %@",tmpSrc);
		//NSLog(@"dst is %@",tmpDst);
		//NSLog(@"syn is %@",tmpSynopsisDict);
		//NSLog(@"tmpJSONObj is %@",tmpJSONObj);
		return nil;
	}
	
	return [[SynopsisJobObject alloc]
		initWithSrcFile:(tmpSrc==nil) ? nil : [NSURL fileURLWithPath:tmpSrc]
		dstFile:(tmpDst==nil) ? nil : [NSURL fileURLWithPath:tmpDst]
		//tmpDir:(tmpDir==nil) ? nil : [NSURL fileURLWithPath:tmpDir]
		videoTransOpts:tmpVideoDict
		audioTransOpts:tmpAudioDict
		synopsisOpts:tmpSynopsisDict
        device:device
		completionBlock:inCompletionBlock];
}
- (instancetype) initWithSrcFile:(NSURL *)inSrcFile dstFile:(NSURL *)inDstFile videoTransOpts:(NSDictionary *)inVidTransOpts audioTransOpts:(NSDictionary *)inAudioTransOpts synopsisOpts:(NSDictionary *)inSynopsisOpts device:(id<MTLDevice>)device completionBlock:(void (^)(SynopsisJobObject *theJob))inCompletionBlock	{
	//NSLog(@"%s",__func__);
	if (inSrcFile==nil || inDstFile==nil)	{
		NSLog(@"ERR: bailing, missing prereq, %s",__func__);
		self = nil;
		return self;
	}
	
	self = [super init];
	if (self != nil)	{
		self.jobStatus = JOStatus_NotStarted;
		self.jobErr = JOErr_NoErr;
		self.jobErrString = @"";
        
        self.device = device;
		
		self.jobProgress = 0.0;
		self.jobStartDate = [NSDate date];
		
		asset = nil;
		reader = nil;
		writer = nil;
		videoWriterQueue = dispatch_queue_create("videoWriterQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		audioWriterQueue = dispatch_queue_create("audioWriterQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		miscWriterQueue = dispatch_queue_create("miscWriterQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		analysisQueue = dispatch_queue_create("analysisQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		analysisGroup = dispatch_group_create();
		
		paused = NO;
		
		pthread_mutexattr_t		attr;
		pthread_mutexattr_init(&attr);
		pthread_mutexattr_settype(&attr,PTHREAD_MUTEX_RECURSIVE);
		pthread_mutex_init(&theLock,&attr);
		pthread_mutexattr_destroy(&attr);
		
		readerVideoPassthruOutputs = [[NSMutableArray alloc] init];
		readerVideoAnalysisOutputs = [[NSMutableArray alloc] init];
		readerAudioPassthruOutputs = [[NSMutableArray alloc] init];
		readerAudioAnalysisOutputs = [[NSMutableArray alloc] init];
		readerMiscPassthruOutputs = [[NSMutableArray alloc] init];
		
		writerVideoInputs = [[NSMutableArray alloc] init];
		writerAudioInputs = [[NSMutableArray alloc] init];
		writerMiscInputs = [[NSMutableArray alloc] init];
		writerMetadataInputs = [[NSMutableArray alloc] init];
		writerMetadataInputAdapters = [[NSMutableArray alloc] init];
		
		self.srcFile = inSrcFile;
		self.dstFile = inDstFile;
		//self.tmpDirectory = inTmpDir;
		//self.tmpFile = (self.tmpDirectory != nil) ? [[self.tmpDirectory URLByAppendingPathComponent:[[NSUUID UUID] UUIDString]] URLByAppendingPathExtension:@"mov"] : nil;
		self.completionBlock = inCompletionBlock;
		self.videoTransOpts = (inVidTransOpts==nil || inVidTransOpts.count<1) ? nil : [inVidTransOpts mutableCopy];
		self.audioTransOpts = (inAudioTransOpts==nil || inAudioTransOpts.count<1) ? nil : [inAudioTransOpts mutableCopy];
		self.synopsisOpts = (inSynopsisOpts==nil) ? nil : [inSynopsisOpts mutableCopy];
		self.availableAnalyzers = [[NSMutableArray alloc] init];
		self.globalMetadata = (inSynopsisOpts==nil) ? nil : [[NSMutableDictionary alloc] init];
		self.dateOfLastCopiedNormalizedVideoBuffer = nil;
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
	pthread_mutex_destroy(&theLock);
}


- (NSString *) description	{
	return [NSString stringWithFormat:@"<SynopsisJobObject: %@>",self.srcFile.lastPathComponent];
}

- (NSTimeInterval) jobTimeElapsed	{
	if (self.jobStartDate == nil)
		return 0.0;
	return [self.jobStartDate timeIntervalSinceNow] * -1.0;
}
- (NSTimeInterval) jobTimeRemaining	{
	return [self.jobStartDate timeIntervalSinceNow] * -1.0 / self.jobProgress * (1.0 - self.jobProgress);
}
- (BOOL) exportingToJSON	{
	SynopsisMetadataEncoderExportOption		exportOption = SynopsisMetadataEncoderExportOptionNone;
	if (self.synopsisOpts != nil && self.synopsisOpts[kSynopsisAnalyzedMetadataExportOptionKey] != nil)
		exportOption = [self.synopsisOpts[kSynopsisAnalyzedMetadataExportOptionKey] unsignedIntegerValue];
	return (exportOption > SynopsisMetadataEncoderExportOptionNone);
}
- (void) checkForHang	{
	//	assume we're not hung if we're not processing...
	switch (self.jobStatus)	{
	case JOStatus_Unknown:
	case JOStatus_NotStarted:
	case JOStatus_Err:
	case JOStatus_Complete:
	case JOStatus_Cancel:
	case JOStatus_Paused:
		return;
	case JOStatus_InProgress:
		break;
	}
	
	//	assume we're not hung if we're paused...
	if (self.paused)
		return;
	
	//	assume we're not hung if we aren't writing video...
	BOOL			foundAVideoWriter = NO;
	@synchronized (self)	{
		for (NSObject *tmpObj in writerVideoInputs)	{
			if (tmpObj != [NSNull null])	{
				foundAVideoWriter = YES;
				break;
			}
		}
	}
	if (!foundAVideoWriter)
		return;
	
	//	assume we're not hung if we've processed a normalized video buffer in the last 10 seconds
	NSDate		*tmpDate = self.dateOfLastCopiedNormalizedVideoBuffer;
	if (tmpDate == nil)
		return;
	
	//	if we hung, cancel and clean up...
	if ([tmpDate timeIntervalSinceNow] < -10.0)	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_AVFErr;
		self.jobErrString = @"Error: AVF hung processing the file";
		[self _cancelAndCleanUp];
	}
}


- (void) start	{
	//NSLog(@"%s",__func__);
	
	self.jobStartDate = [NSDate date];
	
	self.dateOfLastCopiedNormalizedVideoBuffer = [NSDate date];
	
	self.globalMetadata = [NSMutableDictionary new];
	
	//	make sure we know where to read from and where to write to, bail if we don't
	if (self.srcFile == nil || (self.dstFile==nil /*&& self.tmpFile==nil*/))	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_NoSrcFile;
		self.jobErrString = @"No src or dst file specified";
		[self _cleanUp];
		return;
	}
	//	create the asset, bail if we can't
	//asset = [AVAsset assetWithURL:self.srcFile];
	asset = [AVURLAsset URLAssetWithURL:self.srcFile options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @TRUE }];
	if (asset == nil)	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_NoSrcFile;
		self.jobErrString = @"Asset couldn't be created from src file";
		[self _cleanUp];
		return;
	}
	//	create the asset reader, bail if we can't
	NSError			*nsErr = nil;
	reader = [AVAssetReader assetReaderWithAsset:asset error:&nsErr];
	if (reader == nil || nsErr != nil)	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_NoSrcFile;
		self.jobErrString = @"Asset reader couldn't be created from src file";
		[self _cleanUp];
		return;
	}
	//	if the dst file (either in the tmp dir or the actual dst file) already exists, move it to the trash
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSURL				*actualDstURL = /*(self.tmpFile!=nil) ? self.tmpFile :*/ self.dstFile;
	if ([fm fileExistsAtPath:[actualDstURL path]])	{
		if (![fm removeItemAtURL:actualDstURL error:&nsErr] || nsErr != nil)
		//if (![fm trashItemAtURL:actualDstURL resultingItemURL:nil error:&nsErr] || nsErr != nil)
		{
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_CantWriteDest;
			self.jobErrString = @"Destination file already exists but cannot be deleted";
			[self _cleanUp];
			return;
		}
	}
	//	make an asset writer, bail if i can't
	writer = [AVAssetWriter
		assetWriterWithURL:actualDstURL
		fileType:AVFileTypeQuickTimeMovie
		error:&nsErr];
	if (writer == nil || nsErr != nil)	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_AVFErr;
		self.jobErrString = @"Can't create asset writer";
		[self _cleanUp];
		return;
	}
	//	make the synopsis metadata encoder, bail if i can't
	//NSLog(@"synopsisOpts are %@",self.synopsisOpts);
	SynopsisMetadataEncoderExportOption		exportOption = SynopsisMetadataEncoderExportOptionNone;
	if (self.synopsisOpts != nil && self.synopsisOpts[kSynopsisAnalyzedMetadataExportOptionKey] != nil)
		exportOption = [self.synopsisOpts[kSynopsisAnalyzedMetadataExportOptionKey] unsignedIntegerValue];
	//NSLog(@"exportOption is %d",exportOption);
	synopsisEncoder = (self.synopsisOpts==nil) ? nil : [[SynopsisMetadataEncoder alloc] initWithVersion:kSynopsisMetadataVersionValue exportOption:exportOption];
	if (synopsisEncoder == nil && self.synopsisOpts != nil)	{
		self.jobStatus = JOStatus_Err;
		self.jobErr = JOErr_Analysis;
		self.jobErrString = @"Can't create metadata encoder";
		[self _cleanUp];
		return;
	}
	
	
	//	check some basic flags- we need to know if we're stripping audio/video, if we're doing synopsis analysis, etc
	BOOL			stripVideoTracks = NO;
	BOOL			stripAudioTracks = NO;
	BOOL			performSynopsisAnalysis = YES;
	NSNumber		*tmpNum = nil;
	tmpNum = self.videoTransOpts[kSynopsisStripTrackKey];
	stripVideoTracks = (tmpNum != nil && [tmpNum boolValue]);
	if (tmpNum != nil)	{
		[self.videoTransOpts removeObjectForKey:kSynopsisStripTrackKey];
		if (self.videoTransOpts.count < 1)
			self.videoTransOpts = nil;
	}
	tmpNum = self.audioTransOpts[kSynopsisStripTrackKey];
	stripAudioTracks = (tmpNum != nil && [tmpNum boolValue]);
	if (tmpNum != nil)	{
		[self.audioTransOpts removeObjectForKey:kSynopsisStripTrackKey];
		if (self.audioTransOpts.count < 1)
			self.audioTransOpts = nil;
	}
	performSynopsisAnalysis = (self.synopsisOpts != nil);
	//NSLog(@"stripVideoTracks is %d, sripAudioTracks is %d, performSynopsisAnalysis is %d",stripVideoTracks,stripAudioTracks,performSynopsisAnalysis);
	
	
	//	prep some stuff- we need the duration, we need to know if this is a multi-pass export, etc.
	double			durationInSeconds = CMTimeGetSeconds([asset duration]);
	BOOL			multiPassExport = NO;
	tmpNum = (self.videoTransOpts==nil) ? nil : self.videoTransOpts[VVAVVideoMultiPassEncodeKey];
	if (tmpNum!=nil)	{
		if ([tmpNum boolValue])
			multiPassExport = YES;
		[self.videoTransOpts removeObjectForKey:VVAVVideoMultiPassEncodeKey];
		if (self.videoTransOpts.count < 1)
			self.videoTransOpts = nil;
	}
	
    
    
	SynopsisAnalysisQualityHint		analysisQualityHint = (self.synopsisOpts == nil) ? SynopsisAnalysisQualityHintOriginal : [self.synopsisOpts[kSynopsisAnalysisSettingsQualityHintKey] unsignedIntegerValue];
	NSArray							*requestedAnalyzers = (self.synopsisOpts == nil) ? nil : self.synopsisOpts[kSynopsisAnalysisSettingsEnabledPluginsKey];
	self.availableAnalyzers = [[NSMutableArray alloc] init];
	for (NSString *requestedAnalyzerName in requestedAnalyzers)	{
		Class							pluginClass = NSClassFromString(requestedAnalyzerName);
		id<AnalyzerPluginProtocol>		pluginInstance = [[pluginClass alloc] init];
		
		if ([[pluginInstance pluginMediaType] isEqualToString:AVMediaTypeVideo])	{
			//pluginInstance.successLog = ^void(NSString* log){[[LogController global] appendSuccessLog:log];};
			//pluginInstance.warningLog = ^void(NSString* log){[[LogController global] appendWarningLog:log];};
			//pluginInstance.verboseLog = ^void(NSString* log){[[LogController global] appendVerboseLog:log];};
			//pluginInstance.errorLog = ^void(NSString* log){[[LogController global] appendErrorLog:log];};
			[self.availableAnalyzers addObject:pluginInstance];
		}
		else	{
			NSLog(@"ERR: incompatible with analysis type- not using %@",requestedAnalyzerName);
			pluginInstance = nil;
		}
	}
	//	now that we have the analyzers, run through them and determine which video formats they'll require
	NSMutableArray			*requiredSpecifiers = [[NSMutableArray alloc] init];
	for (id<AnalyzerPluginProtocol> analyzer in self.availableAnalyzers)	{
		NSArray					*tmpSpecifiers = [analyzer pluginFormatSpecfiers];
		if (tmpSpecifiers != nil)
			[requiredSpecifiers addObjectsFromArray:tmpSpecifiers];
	}
	//	create the video frame conform session from the required specifiers
	SynopsisVideoFrameConformSession		*videoConformSession = ([requiredSpecifiers count] < 1) ? nil : [[SynopsisVideoFrameConformSession alloc]
		initWithRequiredFormatSpecifiers:requiredSpecifiers
		device:self.device
		inFlightBuffers:3
		frameSkipStride:0];
	//	finally, tell the analyzers to begin an analysis session (preps necessary resources in backend)
	for (id<AnalyzerPluginProtocol> analyzer in self.availableAnalyzers)	{
		[analyzer beginMetadataAnalysisSessionWithQuality:analysisQualityHint device:self.device];
	}
	
	
	//	let's get things started!
	self.jobStatus = JOStatus_InProgress;
	
	
	//	lock, and make all the reader outputs/writer inputs
	pthread_mutex_lock(&theLock);
	
	
	//	first, some basic vars: tracks, dicts that describe normalized audio/video output settings, synopsis-related vars
	NSArray<AVAssetTrack*>		*tracks = [asset tracks];
	//	these dicts describe the standard reader output format if i need to transcode (or analyze!) video or audio
    NSMutableDictionary			*videoReadNormalizedOutputSettings = nil;
    
    if ( @available(macOS 10.15, *) ) {
        videoReadNormalizedOutputSettings = [@{
                  (NSString *)kCVPixelBufferPixelFormatTypeKey: @( kCVPixelFormatType_32BGRA ),    //    BGRA/RGBA stops working sometime at or before 8k resolution!
                  //(NSString *)kCVPixelBufferPixelFormatTypeKey: @( kCVPixelFormatType_32ARGB ),
                  (NSString *)kCVPixelBufferMetalCompatibilityKey: @YES,
                  (NSString *)kCVPixelBufferOpenGLCompatibilityKey: @YES,
                  (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{},
                  AVVideoDecompressionPropertiesKey: @{
                          
                          (NSString *)kVTVideoDecoderSpecification_PreferredDecoderGPURegistryID: @(self.device.registryID),
                  },
                  
              } mutableCopy];
    }
    else {
        videoReadNormalizedOutputSettings =  [@{
                  (NSString *)kCVPixelBufferPixelFormatTypeKey: @( kCVPixelFormatType_32BGRA ),    //    BGRA/RGBA stops working sometime at or before 8k resolution!
                  //(NSString *)kCVPixelBufferPixelFormatTypeKey: @( kCVPixelFormatType_32ARGB ),
                  (NSString *)kCVPixelBufferMetalCompatibilityKey: @YES,
                  (NSString *)kCVPixelBufferOpenGLCompatibilityKey: @YES,
                  (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
              } mutableCopy];
    }
  
    
    
	NSMutableDictionary			*audioReadNormalizedOutputSettings = [@{
		AVFormatIDKey: [NSNumber numberWithInteger:kAudioFormatLinearPCM],
		AVLinearPCMBitDepthKey: @32,
		AVLinearPCMIsBigEndianKey: @NO,
		AVLinearPCMIsFloatKey: @YES,
		AVLinearPCMIsNonInterleaved: @YES
	} mutableCopy];
	
	
	//	now we're going to run through the asset's tracks, and create all of the reader outputs/writer 
	//	inputs we're going to need to perform transcoding and/or analysis.  every array of outputs/inputs 
	//	is going to have the same number of items- NSNull is used as a placeholder in arrays.  this 
	//	is done so we know that all of the items at index X are related to one another, and we can 
	//	iterate across the arrays at the same time to configure processing.
	for (AVAssetTrack *track in tracks)	{
		//AVAssetReaderOutput		*newOutput = nil;
		//	if the track isn't playable and it isn't hap, we can neither transcode nor analyze it
		if (![track isDecodable] && ![track isHapTrack])	{
			[readerVideoPassthruOutputs addObject:[NSNull null]];
			[readerVideoAnalysisOutputs addObject:[NSNull null]];
			[readerAudioPassthruOutputs addObject:[NSNull null]];
			[readerAudioAnalysisOutputs addObject:[NSNull null]];
			AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
			[tmpOutput setAlwaysCopiesSampleData:NO];
			[readerMiscPassthruOutputs addObject:tmpOutput];
			
			[writerVideoInputs addObject:[NSNull null]];
			[writerAudioInputs addObject:[NSNull null]];
			AVAssetWriterInput		*tmpInput = [[AVAssetWriterInput alloc] initWithMediaType:[track mediaType] outputSettings:nil];
			[tmpInput setExpectsMediaDataInRealTime:NO];
			[writerMiscInputs addObject:tmpInput];
			[writerMetadataInputs addObject:[NSNull null]];
			[writerMetadataInputAdapters addObject:[NSNull null]];
		}
		//	else the track is either playable or hap, so we can work with it (transcode and/or analyze)
		else	{
			NSArray			*formatDescriptions = [track formatDescriptions];
			NSUInteger		formatDescriptionsCount = (formatDescriptions==nil) ? 0 : [formatDescriptions count];
			//	if there are no format descriptions then i don't know what to do, so i'll skip the transcode/analysis
			if (formatDescriptionsCount == 0)	{
				AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
				[tmpOutput setAlwaysCopiesSampleData:NO];
				[readerVideoPassthruOutputs addObject:tmpOutput];
				[readerVideoAnalysisOutputs addObject:[NSNull null]];
				[readerAudioPassthruOutputs addObject:[NSNull null]];
				[readerAudioAnalysisOutputs addObject:[NSNull null]];
				[readerMiscPassthruOutputs addObject:[NSNull null]];
				
				AVAssetWriterInput		*tmpInput = [[AVAssetWriterInput alloc] initWithMediaType:[track mediaType] outputSettings:nil];
				[tmpInput setExpectsMediaDataInRealTime:NO];
				[writerVideoInputs addObject:tmpInput];
				[writerAudioInputs addObject:[NSNull null]];
				[writerMiscInputs addObject:[NSNull null]];
				[writerMetadataInputs addObject:[NSNull null]];
				[writerMetadataInputAdapters addObject:[NSNull null]];
			}
			//	else the format descriptions look okay, and i can proceed...
			else	{
				//	if i'm here, there's one format description for the track- use it to determine if i'm transcoding this track or not
				NSString		*trackMediaType = [track mediaType];
				//	if it's a video track
				if (trackMediaType!=nil && [trackMediaType isEqualToString:AVMediaTypeVideo])	{
					CMFormatDescriptionRef		trackFmt = (__bridge CMFormatDescriptionRef)formatDescriptions[0];
					NSMutableDictionary			*localTransOpts = (self.videoTransOpts==nil) ? nil : [self.videoTransOpts mutableCopy];
					
					//	we need to make sure the video track has the appropriate transform (not sure why, original code did this)
					CGAffineTransform		transform = [track preferredTransform];
					
					//	check the export codec to see if it matches the track codec
					BOOL				exportCodecMatches = NO;
					NSString			*exportCodecString = (localTransOpts==nil) ? nil : localTransOpts[AVVideoCodecKey];
					OSType				exportCodecType = (exportCodecString==nil) ? 0x0 : UTGetOSTypeFromString((__bridge CFStringRef)exportCodecString);
					OSType				trackCodecType = CMFormatDescriptionGetMediaSubType(trackFmt);
					if (exportCodecType == trackCodecType)
						exportCodecMatches = YES;
					
					//	check the export resolution to see if it matches the track resolution
					BOOL				exportResolutionMatches = NO;
					CMVideoDimensions	vidDims = CMVideoFormatDescriptionGetDimensions(trackFmt);
					NSSize				trackSize = NSMakeSize(vidDims.width, vidDims.height);
					NSSize				exportSize = NSMakeSize(-1,-1);
					NSNumber			*tmpNum = nil;
					tmpNum = (localTransOpts==nil) ? nil : localTransOpts[AVVideoWidthKey];	//	update 'exportSize' from user-provided transcode opts
					if (tmpNum != nil)
						exportSize.width = [tmpNum doubleValue];
					tmpNum = (localTransOpts==nil) ? nil : localTransOpts[AVVideoHeightKey];
					if (tmpNum != nil)
						exportSize.height = [tmpNum doubleValue];
					if (exportSize.width<0 || exportSize.height<0)	//	if user didn't provide width/height in transcode opts, use track size
						exportSize = trackSize;
					if (NSEqualSizes(exportSize, trackSize))
						exportResolutionMatches = YES;
					
					//	make sure that the transcode opts contain the appropriate width/height keys
					if (localTransOpts != nil)	{
						localTransOpts[AVVideoWidthKey] = [NSNumber numberWithInteger:exportSize.width];
						localTransOpts[AVVideoHeightKey] = [NSNumber numberWithInteger:exportSize.height];
					}
                    
                    if (@available(macOS 10.15, *)) {
                        localTransOpts[AVVideoEncoderSpecificationKey] = @{ (NSString *) kVTVideoEncoderSpecification_PreferredEncoderGPURegistryID : @(self.device.registryID) };
                    }
					
					//	wrap the input-/output-creation stuff in an exception handler so we can recover gracefully with an error message
					@try	{
						//	if we're stripping video tracks...
						if (stripVideoTracks)	{
							//	if we're doing synopsis analysis, we need an analysis output!
							if (performSynopsisAnalysis)	{
								[readerVideoPassthruOutputs addObject:[NSNull null]];
								//	analysis output (normalized)
								if ([track isHapTrack])	{
									AVAssetReaderHapTrackOutput		*tmpHapOutput = [[AVAssetReaderHapTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
									[tmpHapOutput setOutputAsRGB:YES];
									[tmpHapOutput setAlwaysCopiesSampleData:NO];
									[readerVideoAnalysisOutputs addObject:tmpHapOutput];
								}
								else	{
									AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
									[tmpOutput setAlwaysCopiesSampleData:NO];
									[readerVideoAnalysisOutputs addObject:tmpOutput];
								}
							}
							//	else we're not doing synopsis analysis- we don't need anything for this track
							else	{
								[readerVideoPassthruOutputs addObject:[NSNull null]];
								[readerVideoAnalysisOutputs addObject:[NSNull null]];
							}
							[writerVideoInputs addObject:[NSNull null]];
						}
						//	else if (the codec & resolution match and we therefore don't have to transcode) OR user didn't want to transcode, we need a passthru output AND an analysis output!
						else if ((exportCodecMatches && exportResolutionMatches) || localTransOpts==nil)	{
							//	passthru output
							AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
							[tmpOutput setAlwaysCopiesSampleData:NO];
							[readerVideoPassthruOutputs addObject:tmpOutput];
							//	we only need the analysis output if we're doing synopsis analysis!
							if (performSynopsisAnalysis)	{
								//	analysis output (normalized)
								if ([track isHapTrack])	{
									AVAssetReaderHapTrackOutput		*tmpHapOutput = [[AVAssetReaderHapTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
									[tmpHapOutput setOutputAsRGB:YES];
									[tmpHapOutput setAlwaysCopiesSampleData:NO];
									[readerVideoAnalysisOutputs addObject:tmpHapOutput];
								}
								else	{
									tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
									[tmpOutput setAlwaysCopiesSampleData:NO];
									[readerVideoAnalysisOutputs addObject:tmpOutput];
								}
							}
							//	else we're not doing synopsis analysis- we don't need the analysis track...
							else	{
								[readerVideoAnalysisOutputs addObject:[NSNull null]];
							}
							//	writer input
							AVAssetWriterInput		*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:nil];
							[tmpInput setExpectsMediaDataInRealTime:NO];
							[tmpInput setTransform:transform];
							[writerVideoInputs addObject:tmpInput];
						}
						//	else we need to transcode, so the reader needs a normalized video output but no passthru output
						else	{
							[readerVideoPassthruOutputs addObject:[NSNull null]];
							//	analysis output (normalized)
							if ([track isHapTrack])	{
								AVAssetReaderHapTrackOutput		*tmpHapOutput = [[AVAssetReaderHapTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
								[tmpHapOutput setOutputAsRGB:YES];
								[tmpHapOutput setAlwaysCopiesSampleData:NO];
								[readerVideoAnalysisOutputs addObject:tmpHapOutput];
							}
							else	{
								AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:videoReadNormalizedOutputSettings];
								if (multiPassExport)
									[tmpOutput setSupportsRandomAccess:YES];
								[tmpOutput setAlwaysCopiesSampleData:NO];
								[readerVideoAnalysisOutputs addObject:tmpOutput];
							}
							//	writer input
							NSString			*codecString = (localTransOpts==nil) ? nil : [localTransOpts objectForKey:AVVideoCodecKey];
							//	we need to make a custom writer input if we're exporting to a hap codec
							if (codecString!=nil && ([codecString isEqualToString:AVVideoCodecHap] || [codecString isEqualToString:AVVideoCodecHapAlpha] || [codecString isEqualToString:AVVideoCodecHapQ] || [codecString isEqualToString:AVVideoCodecHapQAlpha] || [codecString isEqualToString:AVVideoCodecHapAlphaOnly]))	{
								AVAssetWriterHapInput		*tmpInput = [[AVAssetWriterHapInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:localTransOpts];
								[tmpInput setExpectsMediaDataInRealTime:NO];
								[tmpInput setTransform:transform];
								[writerVideoInputs addObject:tmpInput];
							}
							//	else non-hap codec input
							else	{
								AVAssetWriterInput		*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:localTransOpts];
								if (multiPassExport)
									[tmpInput setPerformsMultiPassEncodingIfSupported:YES];
								[tmpInput setExpectsMediaDataInRealTime:NO];
								[tmpInput setTransform:transform];
								[writerVideoInputs addObject:tmpInput];
							}
						}
						[readerAudioPassthruOutputs addObject:[NSNull null]];
						[readerAudioAnalysisOutputs addObject:[NSNull null]];
						[readerMiscPassthruOutputs addObject:[NSNull null]];
					
						[writerAudioInputs addObject:[NSNull null]];
						[writerMiscInputs addObject:[NSNull null]];
						
						//	if we're performing synopsis analysis, we need to make a metadata track
						if (performSynopsisAnalysis)	{
							CMFormatDescriptionRef	metadataFormatDesc = NULL;
							NSArray					*metadataSpecs = @[
								@{
									(__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier : kSynopsisMetadataIdentifier,
									(__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType : (__bridge NSString *)kCMMetadataBaseDataType_RawData,
								}
							];
							OSStatus				osErr = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
								kCFAllocatorDefault,
								kCMMetadataFormatType_Boxed,
								(__bridge CFArrayRef)metadataSpecs,
								&metadataFormatDesc);
							AVAssetWriterInput		*metadataInput = nil;
							if (osErr == noErr)
								metadataInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:metadataFormatDesc];
							[metadataInput setExpectsMediaDataInRealTime:NO];
							if (!stripVideoTracks)
								[metadataInput addTrackAssociationWithTrackOfInput:[writerVideoInputs lastObject] type:AVTrackAssociationTypeMetadataReferent];
							[writerMetadataInputs addObject:metadataInput];
							AVAssetWriterInputMetadataAdaptor		*metadataInputAdaptor = [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:metadataInput];
							[writerMetadataInputAdapters addObject:metadataInputAdaptor];
						}
						//	else we're not doing synopsis analysis...
						else	{
							[writerMetadataInputs addObject:[NSNull null]];
							[writerMetadataInputAdapters addObject:[NSNull null]];
						}
					}
					@catch (NSException *err)	{
						NSString		*errString = [NSString stringWithFormat:@"ERR creating asset IO, %@",[err reason]];
						NSLog(errString);
						self.jobStatus = JOStatus_Err;
						self.jobErr = JOErr_AVFErr;
						self.jobErrString = errString;
						[self _cleanUp];
						return;
					}
					
					//	the global metadata stores some of the values we just computed in it
					NSMutableDictionary		*containerFormatMetadata = [NSMutableDictionary new];
					containerFormatMetadata[@"Duration"] = @( durationInSeconds * 1000.0 );
					containerFormatMetadata[@"Width"] = @( trackSize.width );
					containerFormatMetadata[@"Height"] = @( trackSize.height );
					containerFormatMetadata[@"FPS"] = @( [track nominalFrameRate] );
					self.globalMetadata[@"ContainerFormatMetadata"] = containerFormatMetadata;
				}
				//	else if it's an audio track
				else if (trackMediaType!=nil && [trackMediaType isEqualToString:AVMediaTypeAudio])	{
					NSArray			*formatDescriptions = [track formatDescriptions];
					CMFormatDescriptionRef		trackFmt = (__bridge CMFormatDescriptionRef)formatDescriptions[0];
					NSMutableDictionary			*localTransOpts = [self.audioTransOpts mutableCopy];
					
					//	determine if the format matches
					BOOL							exportFormatMatches = NO;
					size_t							layoutSize = 0;
					AudioStreamBasicDescription		*trackDescription = (AudioStreamBasicDescription*)CMAudioFormatDescriptionGetStreamBasicDescription(trackFmt);
					if (localTransOpts!=nil		&&
					localTransOpts[AVFormatIDKey]!=nil		&&
					localTransOpts[AVFormatIDKey]!=[NSNull null]		&&
					[localTransOpts[AVFormatIDKey] intValue]==trackDescription->mFormatID)
						exportFormatMatches = YES;
					
					//	determine if the channel count & channel layout match
					BOOL							exportChannelCountMatches = NO;
					BOOL							exportChannelLayoutMatches = NO;
					const AudioChannelLayout		*trackChannelLayout = CMAudioFormatDescriptionGetChannelLayout(trackFmt, &layoutSize);
					unsigned int					trackChannelCount = 0;
					if (trackChannelLayout != NULL)
						trackChannelCount = AudioChannelLayoutTag_GetNumberOfChannels(trackChannelLayout->mChannelLayoutTag);
					NSData							*trackChannelLayoutData = (trackChannelLayout==NULL) ? nil : [NSData dataWithBytes:trackChannelLayout length:layoutSize];
					
					if (localTransOpts != nil)	{
						//	if there's no channel layout/# of channels keys, add them to the transcode dict
						if (localTransOpts[AVNumberOfChannelsKey]==nil || localTransOpts[AVNumberOfChannelsKey]==[NSNull null])
							localTransOpts[AVNumberOfChannelsKey] = [NSNumber numberWithInteger:trackChannelCount];
						if (localTransOpts[AVChannelLayoutKey]==nil || localTransOpts[AVChannelLayoutKey]==[NSNull null])
							localTransOpts[AVChannelLayoutKey] = trackChannelLayoutData;
						
						//	check to see if the # of channels/channel layout keys in the transcode dicts match the track
						if (localTransOpts[AVNumberOfChannelsKey]!=nil		&& 
						localTransOpts[AVNumberOfChannelsKey]!=[NSNull null]		&& 
						[localTransOpts[AVNumberOfChannelsKey] intValue]==trackChannelCount)	{
							exportChannelCountMatches = YES;
						}
						
						if (localTransOpts[AVChannelLayoutKey] == nil || localTransOpts[AVChannelLayoutKey] == [NSNull null])	{
							exportChannelLayoutMatches = YES;
						}
						else	{
							NSData		*passedChannelLayoutData = localTransOpts[AVChannelLayoutKey];
							if (passedChannelLayoutData!=nil && trackChannelLayoutData!=nil && [passedChannelLayoutData isEqualToData:trackChannelLayoutData])	{
								exportChannelLayoutMatches = YES;
							}
						}
					}
					
					//	we need a sample rate key- if there isn't one yet, create one
					BOOL					exportSampleRateMatches = NO;
					double					trackSampleRate = trackDescription->mSampleRate;
					if (localTransOpts != nil)	{
						//	if there's no sample rate key, add the track's sample rate to the dict
						if (localTransOpts[AVSampleRateKey] == nil)
							localTransOpts[AVSampleRateKey] = [NSNumber numberWithDouble:trackSampleRate];
						//	check to see if the sample rate key in the transcode dict matches the track sample rate
						if (localTransOpts[AVSampleRateKey]!=nil	&&
						localTransOpts[AVSampleRateKey]!=[NSNull null]	&&
						[localTransOpts[AVSampleRateKey] doubleValue]==trackSampleRate)	{
							exportSampleRateMatches = YES;
						}
					}
					
					//	wrap the input-/output-creation stuff in an exception handler so we can recover gracefully with an error message
					@try	{
						//	if we're stripping audio tracks...
						if (stripAudioTracks)	{
							[readerAudioPassthruOutputs addObject:[NSNull null]];
							[readerAudioAnalysisOutputs addObject:[NSNull null]];
							[writerAudioInputs addObject:[NSNull null]];
						}
						//	else if (the codec matches AND the channel count matches AND the channel layout matches) OR user didn't want to transcode, we need a passthru output
						else if ((exportFormatMatches && exportChannelCountMatches && exportChannelLayoutMatches && exportSampleRateMatches) || localTransOpts==nil)	{
							AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
							[tmpOutput setAlwaysCopiesSampleData:NO];
							[readerAudioPassthruOutputs addObject:tmpOutput];
							[readerAudioAnalysisOutputs addObject:[NSNull null]];
							AVAssetWriterInput			*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
							[tmpInput setExpectsMediaDataInRealTime:NO];
							[writerAudioInputs addObject:tmpInput];
						}
						//	else we need to transcode, so the reader needs a normalized audio output but no passthru output
						else	{
							[readerAudioPassthruOutputs addObject:[NSNull null]];
							AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:audioReadNormalizedOutputSettings];
							[tmpOutput setAlwaysCopiesSampleData:NO];
							[readerAudioAnalysisOutputs addObject:tmpOutput];
							AVAssetWriterInput			*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:localTransOpts];
							[tmpInput setExpectsMediaDataInRealTime:NO];
							[writerAudioInputs addObject:tmpInput];
						}
						[readerVideoPassthruOutputs addObject:[NSNull null]];
						[readerVideoAnalysisOutputs addObject:[NSNull null]];
						[readerMiscPassthruOutputs addObject:[NSNull null]];
					
						[writerVideoInputs addObject:[NSNull null]];
						[writerMiscInputs addObject:[NSNull null]];
						[writerMetadataInputs addObject:[NSNull null]];
						[writerMetadataInputAdapters addObject:[NSNull null]];
					}
					@catch (NSException *err)	{
						NSString		*errString = [NSString stringWithFormat:@"ERR creating asset IO, %@",[err reason]];
						NSLog(errString);
						self.jobStatus = JOStatus_Err;
						self.jobErr = JOErr_AVFErr;
						self.jobErrString = errString;
						[self _cleanUp];
						return;
					}
				}
				//	else if it's a metadata track....
				else if (trackMediaType!=nil && [trackMediaType isEqualToString:AVMediaTypeMetadata])	{
					BOOL			isSynopsisTrack = NO;
					NSArray			*formatDescriptions = [track formatDescriptions];
					for (int i=0; i<formatDescriptions.count; ++i)	{
						CMFormatDescriptionRef		desc = (__bridge CMFormatDescriptionRef)formatDescriptions[i];
						
						NSArray				*identifiers = CMMetadataFormatDescriptionGetIdentifiers(desc);
						if (identifiers!=nil && identifiers.count>0)	{
							NSString			*identifier = identifiers[0];
							if ([identifier isKindOfClass:[NSString class]] && [identifier isEqualToString:kSynopsisMetadataIdentifier])	{
								isSynopsisTrack = YES;
								break;
							}
						}
						
						//	if it's a synopsis track, we want to trash it (and replace it with our new synopsis data)
						if (isSynopsisTrack)	{
							[readerVideoPassthruOutputs addObject:[NSNull null]];
							[readerVideoAnalysisOutputs addObject:[NSNull null]];
							[readerAudioPassthruOutputs addObject:[NSNull null]];
							[readerAudioAnalysisOutputs addObject:[NSNull null]];
							[readerMiscPassthruOutputs addObject:[NSNull null]];
							
							[writerVideoInputs addObject:[NSNull null]];
							[writerAudioInputs addObject:[NSNull null]];
							[writerMiscInputs addObject:[NSNull null]];
							[writerMetadataInputs addObject:[NSNull null]];
							[writerMetadataInputAdapters addObject:[NSNull null]];
						}
						//	else it's not a synopsis track- pass it through unaltered
						else	{
							[readerVideoPassthruOutputs addObject:[NSNull null]];
							[readerVideoAnalysisOutputs addObject:[NSNull null]];
							[readerAudioPassthruOutputs addObject:[NSNull null]];
							[readerAudioAnalysisOutputs addObject:[NSNull null]];
							AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
							[tmpOutput setAlwaysCopiesSampleData:NO];
							[readerMiscPassthruOutputs addObject:tmpOutput];
							
							[writerVideoInputs addObject:[NSNull null]];
							[writerAudioInputs addObject:[NSNull null]];
							AVAssetWriterInput			*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:[track mediaType] outputSettings:nil];
							[tmpInput setExpectsMediaDataInRealTime:NO];
							[writerMiscInputs addObject:tmpInput];
							[writerMetadataInputs addObject:[NSNull null]];
							[writerMetadataInputAdapters addObject:[NSNull null]];
						}
						
					}
					
				}
				//	else it's any other track type- just pass it through unmodified
				else	{
					[readerVideoPassthruOutputs addObject:[NSNull null]];
					[readerVideoAnalysisOutputs addObject:[NSNull null]];
					[readerAudioPassthruOutputs addObject:[NSNull null]];
					[readerAudioAnalysisOutputs addObject:[NSNull null]];
					AVAssetReaderTrackOutput		*tmpOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
					[tmpOutput setAlwaysCopiesSampleData:NO];
					[readerMiscPassthruOutputs addObject:tmpOutput];
					
					[writerVideoInputs addObject:[NSNull null]];
					[writerAudioInputs addObject:[NSNull null]];
					AVAssetWriterInput			*tmpInput = [AVAssetWriterInput assetWriterInputWithMediaType:[track mediaType] outputSettings:nil];
					[tmpInput setExpectsMediaDataInRealTime:NO];
					[writerMiscInputs addObject:tmpInput];
					[writerMetadataInputs addObject:[NSNull null]];
					[writerMetadataInputAdapters addObject:[NSNull null]];
				}
			}
		}
	}	//	end for loop iterating across tracks in src asset
	
	
	
	
	//NSLog(@"-----------");
	//NSLog(@"readerVideoPassthruOutputs = %@",readerVideoPassthruOutputs);
	//NSLog(@"readerVideoAnalysisOutputs = %@",readerVideoAnalysisOutputs);
	//NSLog(@"readerAudioPassthruOutputs = %@",readerAudioPassthruOutputs);
	//NSLog(@"readerAudioAnalysisOutputs = %@",readerAudioAnalysisOutputs);
	//NSLog(@"readerMiscPassthruOutputs = %@",readerMiscPassthruOutputs);
	//NSLog(@"-----------");
	//NSLog(@"writerVideoInputs = %@",writerVideoInputs);
	//NSLog(@"writerAudioInputs = %@",writerAudioInputs);
	//NSLog(@"writerMiscInputs = %@",writerMiscInputs);
	//NSLog(@"writerMetadataInputs = %@",writerMetadataInputs);
	//NSLog(@"writerMetadataInputAdapters = %@",writerMetadataInputAdapters);
	//NSLog(@"-----------");
	
	
	
	
	//	at this point, we're done creating the reader outputs/writer inputs.  run through all the 
	//	arrays we created, adding them to the reader/writer, bailing if we run into any issues.
	{
		NSArray<NSMutableArray*>		*outputArrays = @[ readerVideoPassthruOutputs,readerVideoAnalysisOutputs,readerAudioPassthruOutputs,readerAudioAnalysisOutputs,readerMiscPassthruOutputs ];
		for (NSMutableArray *outputArray in outputArrays)	{
			int			tmpIndex = 0;
			for (AVAssetReaderOutput *output in outputArray)	{
				if (output == (AVAssetReaderOutput*)[NSNull null])	{
					++tmpIndex;
					continue;
				}
				
				if (![reader canAddOutput:output])	{
					NSLog(@"ERR: cannot add output (%@) to reader",output);
					self.jobStatus = JOStatus_Err;
					self.jobErr = JOErr_AVFErr;
					self.jobErrString = [NSString stringWithFormat:@"Err adding reader output (%@)",[output description]];
					pthread_mutex_unlock(&theLock);
					[self _cancelAndCleanUp];
					return;
				}
				else	{
					//NSLog(@"\tadding output at index %d to reader (%@)",tmpIndex,output);
					[reader addOutput:output];
				}
				++tmpIndex;
			}
		}
		NSArray<NSMutableArray*>		*inputArrays = @[ writerVideoInputs,writerAudioInputs,writerMiscInputs,writerMetadataInputs ];
		for (NSMutableArray *inputArray in inputArrays)	{
			int			tmpIndex = 0;
			for (AVAssetWriterInput *input in inputArray)	{
				if (input == (AVAssetWriterInput*)[NSNull null])	{
					++tmpIndex;
					continue;
				}
				if (![writer canAddInput:input])	{
					NSLog(@"ERR: cannot add input (%@) to writer",input);
					self.jobStatus = JOStatus_Err;
					self.jobErr = JOErr_AVFErr;
					self.jobErrString = [NSString stringWithFormat:@"Err adding writer input (%@)",[input description]];
					pthread_mutex_unlock(&theLock);
					[self _cancelAndCleanUp];
					return;
				}
				else	{
					//NSLog(@"\tadding input at index %d to writer (%@)",tmpIndex,input);
					[writer addInput:input];
				}
				++tmpIndex;
			}
		}
	}
	
	
	//NSLog(@"reader outputs check: %@",[reader outputs]);
	//NSLog(@"writer inputs check: %@",[writer inputs]);
	//	tell the reader to start reading, and the writer to start writing
	[reader startReading];
	[writer startWriting];
	//	start the session (this actually starts processing data)
	[writer startSessionAtSourceTime:kCMTimeZero];
	
	
	
	
	//	...at this point we've run across the tracks in the asset and have assembled all of the 
	//	writer inputs/reader outputs necessary to begin processing the asset
	
	//	every array of reader outputs/writer inputs has the same number of elements, and they 
	//	correspond to one another.  for example, the non-null "reader output" at index 0 corresponds 
	//	to the non-null "writer input" at index 0.
	//	
	//	- there will be one or two non-null "writer inputs" at any given index (two non-null inputs
	//	  only if it's a video track which is being analyzed- one for video, one for metadata)
	//	- there will be one or two non-null "reader outputs" at any given index (two non-null outputs 
	//	  only if it's a passthru video track and analysis is being performed on it)
	//	
	//	run through all of these arrays simultaneously, configuring each writer input to request data as needed
	__weak SynopsisJobObject		*bss = self;
	//__block int					trackIndex = 0;
	NSEnumerator				*vidReadPassthruOutIt = [readerVideoPassthruOutputs objectEnumerator];
	AVAssetReaderTrackOutput	*vidReadPassthruOut = [vidReadPassthruOutIt nextObject];
	NSEnumerator				*vidReadAnalysisOutIt = [readerVideoAnalysisOutputs objectEnumerator];
	AVAssetReaderTrackOutput	*vidReadAnalysisOut = [vidReadAnalysisOutIt nextObject];
	NSEnumerator				*audReadPassthruOutIt = [readerAudioPassthruOutputs objectEnumerator];
	AVAssetReaderTrackOutput	*audReadPassthruOut = [audReadPassthruOutIt nextObject];
	NSEnumerator				*audReadAnalysisOutIt = [readerAudioAnalysisOutputs objectEnumerator];
	AVAssetReaderTrackOutput	*audReadAnalysisOut = [audReadAnalysisOutIt nextObject];
	NSEnumerator				*miscReadPassthruOutIt = [readerMiscPassthruOutputs objectEnumerator];
	AVAssetReaderTrackOutput	*miscReadPassthruOut = [miscReadPassthruOutIt nextObject];
	
	NSEnumerator				*vidWriteInIt = [writerVideoInputs objectEnumerator];
	AVAssetWriterInput			*vidWriteIn = [vidWriteInIt nextObject];
	NSEnumerator				*audWriteInIt = [writerAudioInputs objectEnumerator];
	AVAssetWriterInput			*audWriteIn = [audWriteInIt nextObject];
	NSEnumerator				*miscWriteInIt = [writerMiscInputs objectEnumerator];
	AVAssetWriterInput			*miscWriteIn = [miscWriteInIt nextObject];
	NSEnumerator				*metadataWriteInIt = [writerMetadataInputs objectEnumerator];
	AVAssetWriterInput			*metadataWriteIn = [metadataWriteInIt nextObject];
	NSEnumerator				*metadataWriteInAdaptIt = [writerMetadataInputAdapters objectEnumerator];
	AVAssetWriterInputMetadataAdaptor	*metadataWriteInAdapt = [metadataWriteInAdaptIt nextObject];
	
	//	while at least one reader output AND at least one writer input are both non-nil...note that we don't check for metadata writer inputs
	while ((vidReadPassthruOut!=nil || vidReadAnalysisOut!=nil || audReadPassthruOut!=nil || audReadAnalysisOut!=nil || miscReadPassthruOut!=nil) &&
	(vidWriteIn!=nil || audWriteIn!=nil || miscWriteIn!=nil))	{
		//	make a local var for the primary reader output, writer input, and queue to use for processing
		AVAssetWriterInput				*localInput = nil;	//	this input will be video, audio, or misc- it will never point to a writer for a metadata input (there may be a non-NSNull metadata input at this index, if this track is being analyzed- but this won't point to it)
		AVAssetReaderOutput				*localOutput = nil;	//	this output corresponds to the local input- note that there may be another non-nil output (if it's a passthru encode, both the passthru output as well as the analysis output will be non-nil, and this will correspond to the passthru output)
		dispatch_queue_t				localQueue = NULL;
		BOOL							isVideoWriter = NO;
		BOOL							isAudioWriter = NO;
		BOOL							isMiscWriter = NO;
		BOOL							isMetadataWriter = NO;	//	only 'YES' if we're stripping the video, but performing analysis
		BOOL							writerIsPassthru = NO;
		
		//	if there's a video writer input for this track...
		if (vidWriteIn != (AVAssetWriterInput*)[NSNull null])	{
			//NSLog(@"\tconfiguring video writer track");
			localInput = vidWriteIn;
			localQueue = videoWriterQueue;
			isVideoWriter = YES;
			if (vidReadPassthruOut != (AVAssetReaderTrackOutput*)[NSNull null])	{
				writerIsPassthru = YES;
				localOutput = vidReadPassthruOut;
			}
			else
				localOutput = vidReadAnalysisOut;
		}
		//	else if there's an audio writer input for this track...
		else if (audWriteIn != (AVAssetWriterInput*)[NSNull null])	{
			//NSLog(@"\tconfiguring audio writer track");
			localInput = audWriteIn;
			localQueue = audioWriterQueue;
			isAudioWriter = YES;
			if (audReadPassthruOut!=(AVAssetReaderTrackOutput*)[NSNull null])	{
				writerIsPassthru = YES;
				localOutput = audReadPassthruOut;
			}
			else
				localOutput = audReadAnalysisOut;
		}
		//	else if there's a misc writer input for this track...
		else if (miscWriteIn != (AVAssetWriterInput*)[NSNull null])	{
			//NSLog(@"\tconfiguring misc writer track");
			localInput = miscWriteIn;
			localQueue = miscWriterQueue;
			isMiscWriter = YES;
			if (miscReadPassthruOut!=(AVAssetReaderTrackOutput*)[NSNull null])	{
				writerIsPassthru = YES;
				localOutput = miscReadPassthruOut;
			}
		}
		//	else there's no video/audio/misc writer input for this track...maybe we're stripping the actual tracks, and this is a metadata writer input?
		else if (metadataWriteIn != (AVAssetWriterInput*)[NSNull null])	{
			//NSLog(@"\tconfiguring metadata writer track (w/no video writer track)");
			localInput = metadataWriteIn;
			localQueue = videoWriterQueue;
			isMetadataWriter = YES;
			localOutput = vidReadAnalysisOut;
		}
		
		//	if the local input is null (because we're stripping this track)
		if (localInput == nil || localInput == (AVAssetWriterInput*)[NSNull null])	{
			//	increment the iterators
			vidReadPassthruOut = [vidReadPassthruOutIt nextObject];
			vidReadAnalysisOut = [vidReadAnalysisOutIt nextObject];
			audReadPassthruOut = [audReadPassthruOutIt nextObject];
			audReadAnalysisOut = [audReadAnalysisOutIt nextObject];
			miscReadPassthruOut = [miscReadPassthruOutIt nextObject];
		
			vidWriteIn = [vidWriteInIt nextObject];
			audWriteIn = [audWriteInIt nextObject];
			miscWriteIn = [miscWriteInIt nextObject];
			metadataWriteIn = [metadataWriteInIt nextObject];	
			metadataWriteInAdapt = [metadataWriteInAdaptIt nextObject];
			continue;
		}
		
		//	configure the input to respond to pass descriptions (this supports multi-pass encoding)
		[localInput respondToEachPassDescriptionOnQueue:localQueue usingBlock:^{
			//NSLog(@"respondToEachPassDescriptionOnQueue:, AVAssetMediaType is %@",[localInput mediaType]);
			__block NSUInteger			skippedBufferCount = 0;
			__block NSInteger			retrievedSampleBufferCount = 0;	//	the # of samples retrieved from the reader output corresponding to this writer input
			__block NSInteger			analyzedSampleBufferCount = 0;	//	the # of samples retrieved from the normalized/analysis output corresponding to this writer input
			//	if this is a passthru out and there's no corresponding analysis out, set 'analyzedSampleBufferCount' to -1 b/c we're not using it to verify that every sample has been analyzed
			if ((vidReadPassthruOut != nil && vidReadPassthruOut != [NSNull null]) && (vidReadAnalysisOut == nil || vidReadAnalysisOut == [NSNull null]))
				analyzedSampleBufferCount = -1;
			else if ((audReadPassthruOut != nil && audReadPassthruOut != [NSNull null]) && (audReadAnalysisOut == nil || audReadAnalysisOut == [NSNull null]))
				analyzedSampleBufferCount = -1;
			
			
			__block NSUInteger			inputPassIndex = 0;
			AVAssetWriterInputPassDescription		*tmpDesc = [localInput currentPassDescription];
			//NSLog(@"\t\tcurrentPassDescription is %@",tmpDesc);
			//	if there's no pass description, mark the input as being finished and remove them
			if (tmpDesc == nil)	{
				
				//NSLog(@"\t\tno pass description, marking input type (%@) as finished",[localInput mediaType]);
				//	mark the input as finished
				[localInput markAsFinished];
				pthread_mutex_lock(&theLock);
				{
					//	figure out the index of the writer that's finished
					NSUInteger		targetIndex;
					if (isVideoWriter)	{
						targetIndex = [writerVideoInputs indexOfObjectIdenticalTo:localInput];
						//	if this was a video input, we need to mark the metadata input as finished, too!
						AVAssetWriterInput		*synopsisInput = (targetIndex<0 || targetIndex>=writerMetadataInputs.count) ? nil : [writerMetadataInputs objectAtIndex:targetIndex];
						if (synopsisInput != nil && synopsisInput != (AVAssetWriterInput*)[NSNull null])
							[synopsisInput markAsFinished];
					}
					else if (isAudioWriter)
						targetIndex = [writerAudioInputs indexOfObjectIdenticalTo:localInput];
					else if (isMiscWriter)
						targetIndex = [writerMiscInputs indexOfObjectIdenticalTo:localInput];
					else if (isMetadataWriter)
						targetIndex = [writerMetadataInputs indexOfObjectIdenticalTo:localInput];
					//	delete the writer from the array of writer inputs, and also the corresponding 
					//	reader from the array of reader outputs.  remember, you have to delete the 
					//	same (corresponding) input/output from every array of inputs/outputs!
					NSArray			*tmpArray = @[ readerVideoPassthruOutputs, readerVideoAnalysisOutputs, readerAudioPassthruOutputs, readerAudioAnalysisOutputs, readerMiscPassthruOutputs, writerVideoInputs, writerAudioInputs, writerMiscInputs, writerMetadataInputs ];
					//NSUInteger		maxSubArrayCount = 0;
					for (NSMutableArray *subArray in tmpArray)	{
						if (targetIndex>=0 && targetIndex<subArray.count)
							[subArray removeObjectAtIndex:targetIndex];
					}
					//	now we have to check to see if we're finished writing.
					//	- we're finished if there aren't any more outputs/inputs in anything (if the inputs/outputs have all been deleted because they're finished)
					//	- we're also finished if the only outputs/inputs are NSNull (NSNull is used as a placeholder if we're stripping tracks)
					NSUInteger			maxNumberOfInputsOrOutputsPerSubArray = 0;
					NSUInteger			maxNumberOfNonNullInputsOrOutputsPerSubArray = 0;
					for (NSMutableArray *subArray in tmpArray)	{
						if ([subArray count]>maxNumberOfInputsOrOutputsPerSubArray)
							maxNumberOfInputsOrOutputsPerSubArray = [subArray count];
						
						int					nonNSNullCount = 0;
						for (id subArrayItem in subArray)	{
							if (subArrayItem != [NSNull null])
								++nonNSNullCount;
						}
						if (nonNSNullCount > maxNumberOfNonNullInputsOrOutputsPerSubArray)
							maxNumberOfNonNullInputsOrOutputsPerSubArray = nonNSNullCount;
					}
					if (maxNumberOfInputsOrOutputsPerSubArray == 0 || maxNumberOfNonNullInputsOrOutputsPerSubArray == 0)	{
						//dispatch_async(dispatch_get_main_queue(), ^{
							[self->writer finishWritingWithCompletionHandler:^{
								//NSLog(@"finished writing!");
								//	sometimes we're unable to create an AVMovie from the file in this handler, 
								//	so we can't just finish writing and clean up immediately.  instead, we 
								//	check to make sure the movie actually exists before we finish and clean up.
								
								bss.jobStatus = JOStatus_Complete;
								[bss _finishWritingAndCleanUp];
								
								
								/*
								[self _checkIfActuallyFinished:0];
								*/
							}];
						//});
					}
				}
				pthread_mutex_unlock(&theLock);
				
			}
			//	else there's a pass description, which means i need to do reading/writing/probably encoding
			else	{
				
				//NSLog(@"\t\tthere's a pass description, inputPassIndex for input type %@ is %lu",[localInput mediaType],(unsigned long)inputPassIndex);
				//	if this isn't the first pass, before proceeding we need to reset the reader output to the time range of the pass description
				if (inputPassIndex > 0)	{
					//	you can't resetForReadingTimeRanges until all the samples have been read from 
					//	the output (until copyNextSampleBuffer returns NULL), so make sure this has 
					//	happened...note that we may have to advance more than one output (if there's 
					//	both a passthru and an analysis output)
					NSArray			*outputsToAdvance = nil;
					if (isVideoWriter)
						outputsToAdvance = @[ vidReadPassthruOut, vidReadAnalysisOut ];
					else if (isAudioWriter)
						outputsToAdvance = @[ audReadPassthruOut, audReadAnalysisOut ];
					else if (isMiscWriter)
						outputsToAdvance = @[ miscReadPassthruOut ];
					else if (isMetadataWriter)
						outputsToAdvance = @[ vidReadAnalysisOut ];
					for (AVAssetReaderOutput *outputToAdvance in outputsToAdvance)	{
						CMSampleBufferRef		junkBuffer = NULL;
						do	{
							if (junkBuffer != NULL)	{
								CFRelease(junkBuffer);
								junkBuffer = NULL;
							}
							junkBuffer = [outputToAdvance copyNextSampleBuffer];
						} while (junkBuffer != NULL);
						//	sometimes, AVF gives conflicting time ranges, so we need to wrap this with an exception handler
						@try	{
							bss.jobErrString = @"";
							[outputToAdvance resetForReadingTimeRanges:[tmpDesc sourceTimeRanges]];
						}
						@catch (NSException *err)	{
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
								bss.jobErrString = [err description];
								bss.jobStatus = JOStatus_Err;
								bss.jobErr = JOErr_Transcode;
								[bss _cancelAndCleanUp];
							});
							break;
						}
					}
				}
				
				//	if there's no error, tell the writer input to begin requesting media data...
				//if (bss.jobErr == JOErr_NoErr)	{
					//	configure the input to request media data when ready
					[localInput requestMediaDataWhenReadyOnQueue:localQueue usingBlock:^{
						//NSLog(@"requestMediaDataWhenReadyOnQueue:usingBlock:, input is %@",localInput);
						//	if we don't limit the # of frame we write, this loop will write every frame, preventing pause/cancel from working...
						NSUInteger			runCount = 0;
						while ([localInput isReadyForMoreMediaData] && [writer status]==AVAssetWriterStatusWriting && runCount<5)	{
							//	no matter what kind of input it is, we need a sample buffer from the local output to apply to this input.
							CMSampleBufferRef		localSB = [localOutput copyNextSampleBuffer];
							CMSampleBufferRef		analysisSB = NULL;	//	we may need a sample buffer to be analyzed!
							//	this is the dictionary we're going to populate with analysis metadata from this frame
							NSMutableDictionary		*aggregatedMetadata = [[NSMutableDictionary alloc] init];
							//	we need some basic time properties to associate with the metadata
							CMTime					analysisPTS = kCMTimeInvalid;
							CMTimeRange				analysisTR = kCMTimeRangeInvalid;
							
							//	if we were able to copy a sample buffer from the local output
							if (localSB != NULL)	{
								//NSLog(@"\t\tcopied buffer at time %@",(__bridge id)CMTimeCopyDescription(kCFAllocatorDefault,CMSampleBufferGetOutputPresentationTimeStamp(localSB)));
								
								//	if this is a video writer, we need to get an analysis samplbe buffer
								if (isVideoWriter || isMetadataWriter)	{
									if (isVideoWriter)
										retrievedSampleBufferCount += CMSampleBufferGetNumSamples(localSB);
									
									//	if this was a passthru input...
									if (writerIsPassthru)	{
										//	(...the sample buffer's image buffer is NOT usable for analysis)
										//	copy a sample from the reader video analysis output that corresponds to this writer input
										analysisSB = (vidReadAnalysisOut==NULL || vidReadAnalysisOut==(AVAssetReaderOutput*)[NSNull null]) ? NULL : [vidReadAnalysisOut copyNextSampleBuffer];
										if (analysisSB != NULL)	{
											analyzedSampleBufferCount += CMSampleBufferGetNumSamples(analysisSB);
											//	update the date at which we last successfully copied a normalized video buffer
											self.dateOfLastCopiedNormalizedVideoBuffer = [NSDate date];
										}
									}
									//	else this was a non-passthru input...
									else	{
										//	update the date at which we last successfully copied a normalized video buffer
										if (isVideoWriter)
											self.dateOfLastCopiedNormalizedVideoBuffer = [NSDate date];
										//	(...the sample buffer from the local output is usable for analysis)
										analysisSB = CFRetain(localSB);
										if (isVideoWriter)
											analyzedSampleBufferCount += CMSampleBufferGetNumSamples(analysisSB);
									}
									
									
									if (analysisSB != NULL && videoConformSession != nil && performSynopsisAnalysis)	{
										
										//	enter the analysis group once before we start the conform session
										dispatch_group_enter(analysisGroup);
										//	populate the time vars we'll need for metadata
										analysisPTS = CMSampleBufferGetOutputPresentationTimeStamp(analysisSB);
										analysisTR = CMTimeRangeMake(analysisPTS, CMSampleBufferGetOutputDuration(analysisSB));
										//	pass the analysis sample buffer to the conform session on the analysis queue
										dispatch_async(analysisQueue, ^{
											//	pass the analysis sample buffer to the conform session
											CVPixelBufferRef		analysisPB = CMSampleBufferGetImageBuffer(analysisSB);
											CGRect					analysisPBRect = CGRectMake(0,0,CVPixelBufferGetWidth(analysisPB),CVPixelBufferGetHeight(analysisPB));
											CGRect					conformRect = RectForQualityHint(analysisPBRect, analysisQualityHint);
											[videoConformSession
												conformPixelBuffer:CMSampleBufferGetImageBuffer(analysisSB)
												atTime:analysisPTS
												withTransform:[localInput transform]
												rect:conformRect
												completionBlock:^(BOOL frameSkip, id<MTLCommandBuffer> commandBuffer, SynopsisVideoFrameCache *conformedFrameCache, NSError *conformErr)	{
													
													//	as soon as the conform session is done, start running the analysis plugins (still on the analysis queue)
													for (id<AnalyzerPluginProtocol> analyzer in bss.availableAnalyzers)	{
														//	enter the analysis group again before we tell each analyzer to start analyzing
														dispatch_group_enter(analysisGroup);
														//	tell the analyzer to analyze the frame cache
														NSString		*metadataKey = [analyzer pluginIdentifier];
														[analyzer
															analyzeFrameCache:conformedFrameCache
															commandBuffer:commandBuffer
															completionHandler:^(NSDictionary *metadataValue, NSError *analyzerError)	{
																if (analyzerError != nil)	{
																	bss.jobStatus = JOStatus_Err;
																	bss.jobErr = JOErr_Analysis;
																	bss.jobErrString = [analyzerError localizedDescription];
																	[bss _cancelAndCleanUp];	//	should we cancel, or just proceed?
																	//[[LogController global] appendErrorLog:[analyzerError description]];	//	from analyzer code
																}
													
																if (metadataValue != nil)	{
																	@synchronized(aggregatedMetadata)	{
																		[aggregatedMetadata setObject:metadataValue forKey:metadataKey];
																	}
																}
																
																//	leave the analysis group as soon as the analyzer's completion block has finished
																dispatch_group_leave(analysisGroup);
															}];
											
													}
													
													
													//	leave the analysis group as soon as the conform session's completion block has finished executing
													dispatch_group_leave(analysisGroup);
												}];	//	end videoConformSession completionBlock
												
										});	//	end dispatch_async
										
									}
									
									
								}
								
								//	update the progress ivar
								if (isVideoWriter || isMetadataWriter)	{
									pthread_mutex_lock(&theLock);
									CMTime			tmpTime = CMSampleBufferGetOutputPresentationTimeStamp(localSB);
									double			tmpProgress = 0.0;
									if (CMTIME_IS_VALID(tmpTime))
										tmpProgress = (CMTimeGetSeconds(tmpTime)/durationInSeconds);
									//bss.jobProgress = (inputPassIndex==1) ? tmpProgress : 0.5+tmpProgress;
									//if (bss.jobProgress >= 1.0)
									//	bss.jobProgress = 0.99;
									bss.jobProgress = tmpProgress;
									//NSLog(@"\t\tjobProgress is %0.2f",bss.jobProgress);
									//NSLog(@"\t\testimated time remaining is %0.2f",bss.jobTimeRemaining);
									pthread_mutex_unlock(&theLock);
									//	append the sample buffer from the local output to the local input
								}
								skippedBufferCount = 0;
								if (isVideoWriter || isAudioWriter || isMiscWriter)
									[localInput appendSampleBuffer:localSB];
								CFRelease(localSB);
								localSB = NULL;
								
								
								//	if there's a non-null analysis sample bufer, we've probably aggregated some metadata to pass to the metadata writer
								if (analysisSB != NULL)	{
									
									//	...wait here for analysis to finish up...
									dispatch_group_wait(analysisGroup, DISPATCH_TIME_FOREVER);
									
									//	if there's aggregated metadata, write it to the metadata input
									if (aggregatedMetadata!=nil && [aggregatedMetadata count]>0)	{
										//NSLog(@"aggregatedMetadata is %@",aggregatedMetadata);
										
										AVTimedMetadataGroup		*mdg = [synopsisEncoder encodeSynopsisMetadataToTimesMetadataGroup:aggregatedMetadata timeRange:analysisTR];
										if (mdg != nil)	{
											if ([metadataWriteIn isReadyForMoreMediaData])	{
												if (![metadataWriteInAdapt appendTimedMetadataGroup:mdg])	{
													NSLog(@"ERR: couldn't append metadata group to input adapter, %s",__func__);
													bss.jobStatus = JOStatus_Err;
													bss.jobErr = JOErr_AVFErr;
													bss.jobErrString = @"Couldn't append metadata group to input";
													[bss _cancelAndCleanUp];
												}
											}
										}
									}
									
								}
								
								
								if (analysisSB != NULL)	{
									CFRelease(analysisSB);
									analysisSB = NULL;
								}
							}
							//	else we couldn't copy a sample buffer from the local output
							else	{
								++skippedBufferCount;
								//NSLog(@"\t\tunable to copy the buffer, skipopedBufferCount is now %ld",skippedBufferCount);
								if (skippedBufferCount >4)	{
									[localInput markCurrentPassAsFinished];
									//	if this was a video track, and it didn't render any video frames, something went wrong
									if ((isVideoWriter && retrievedSampleBufferCount==0)	||
									(analyzedSampleBufferCount >= 0 && retrievedSampleBufferCount != analyzedSampleBufferCount))	{
										//NSLog(@"\t\tretrieved vs analyzed count is %ld - %ld for job %@",retrievedSampleBufferCount,analyzedSampleBufferCount,self);
										//unexpectedErr = YES;
										bss.jobStatus = JOStatus_Err;
										bss.jobErr = JOErr_AVFErr;
										bss.jobErrString = @"Problem retrieving image buffer from AVFoundation";
										[self _cancelAndCleanUp];
										return;
									}
								}
								break;
							}
							
							++runCount;
						}
					}];
				//}
				
			}
			
			//	increment the input pass index (tracked so i know when to reset the reading ranges and whether or not i need to perform analysis)
			++inputPassIndex;
			//	update the track index, so we can more easily retrieve corresponding reader outputs/writer inputs
			//++trackIndex;
		}];
		
		
		//	increment the iterators
		vidReadPassthruOut = [vidReadPassthruOutIt nextObject];
		vidReadAnalysisOut = [vidReadAnalysisOutIt nextObject];
		audReadPassthruOut = [audReadPassthruOutIt nextObject];
		audReadAnalysisOut = [audReadAnalysisOutIt nextObject];
		miscReadPassthruOut = [miscReadPassthruOutIt nextObject];
		
		vidWriteIn = [vidWriteInIt nextObject];
		audWriteIn = [audWriteInIt nextObject];
		miscWriteIn = [miscWriteInIt nextObject];
		metadataWriteIn = [metadataWriteInIt nextObject];	
		metadataWriteInAdapt = [metadataWriteInAdaptIt nextObject];
	}
	
	
	pthread_mutex_unlock(&theLock);
}
- (void) cancel	{
	//NSLog(@"%s",__func__);
	self.jobStatus = JOStatus_Cancel;
	
	[self _cancelAndCleanUp];
}
- (void) setPaused:(BOOL)n	{
	//NSLog(@"%s ... %d",__func__,n);
	pthread_mutex_lock(&theLock);
	if (paused != n)	{
		paused = n;
		if (paused)	{
			self.dateOfLastCopiedNormalizedVideoBuffer = [NSDate date];
			if (videoWriterQueue != NULL)
				dispatch_suspend(videoWriterQueue);
			if (audioWriterQueue != NULL)
				dispatch_suspend(audioWriterQueue);
			if (miscWriterQueue != NULL)
				dispatch_suspend(miscWriterQueue);
			if (analysisQueue != NULL)
				dispatch_suspend(analysisQueue);
		}
		else	{
			self.dateOfLastCopiedNormalizedVideoBuffer = [NSDate date];
			if (videoWriterQueue != NULL)
				dispatch_resume(videoWriterQueue);
			if (audioWriterQueue != NULL)
				dispatch_resume(audioWriterQueue);
			if (miscWriterQueue != NULL)
				dispatch_resume(miscWriterQueue);
			if (analysisQueue != NULL)
				dispatch_resume(analysisQueue);
		}
	}
	pthread_mutex_unlock(&theLock);
	
	if (n)
		self.jobStatus = JOStatus_Paused;
	else
		self.jobStatus = JOStatus_InProgress;
}
- (BOOL) paused	{
	return paused;
}


/*
- (void) _checkIfActuallyFinished:(int)inCheckCount	{
	//NSURL				*targetURL = (self.tmpFile != nil) ? self.tmpFile : self.dstFile;
	NSURL				*targetURL = self.dstFile;
	NSError				*nsErr = nil;
	AVMutableMovie		*mov = [[AVMutableMovie alloc]
		initWithURL:targetURL
		options:nil
		error:&nsErr];
	if ((inCheckCount < 4) && (mov == nil || nsErr != nil))	{
		NSLog(@"check failed!  count is %d, job is %@",inCheckCount,self);
		NSLog(@"\t\tAVMutableMovie error is %@",nsErr);
		NSLog(@"\t\tasset writer status is %ld, error is %@",[writer status],[writer error]);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5*NSEC_PER_SEC), videoWriterQueue, ^{
			[self _checkIfActuallyFinished:inCheckCount + 1];
		});
	}
	else	{
		self.jobStatus = JOStatus_Complete;
		[self _finishWritingAndCleanUp];
	}
}
*/
- (void) _finishWritingAndCleanUp	{
	//NSLog(@"%s",__func__);
	//	shut down the reader and the various outputs
	pthread_mutex_lock(&theLock);
	{
		if (reader != nil)	{
			[reader cancelReading];
			reader = nil;
		}
		NSArray<NSMutableArray*>		*outputArrays = @[ readerVideoPassthruOutputs,readerVideoAnalysisOutputs,readerAudioPassthruOutputs,readerAudioAnalysisOutputs,readerMiscPassthruOutputs ];
		for (NSMutableArray *outputArray in outputArrays)	{
			for (AVAssetReaderOutput *output in outputArray)	{
				if (output != (AVAssetReaderOutput*)[NSNull null])
					[output markConfigurationAsFinal];
			}
		}
		writer = nil;
	}
	pthread_mutex_unlock(&theLock);
	
	//	finalize the metadata dict
	for (id<AnalyzerPluginProtocol> analyzer in self.availableAnalyzers)	{
		NSError				*nsErr = nil;
		NSDictionary		*finalizedMD = [analyzer finalizeMetadataAnalysisSessionWithError:&nsErr];
		if (finalizedMD == nil || nsErr != nil)	{
			NSString			*finalizedErrString = [NSString stringWithFormat:@"Error finalizing analysis: %@",[nsErr localizedDescription]];
			NSLog(finalizedErrString);
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_Analysis;
			self.jobErrString = finalizedErrString;
			[self _cleanUp];
			return;
		}
		
		NSString			*pluginID = [analyzer pluginIdentifier];
		if (pluginID != nil)	{
			self.globalMetadata[pluginID] = finalizedMD;
		}
	}
	self.globalMetadata[kSynopsisMetadataVersionKey] = @( kSynopsisMetadataVersionValue );
	
	//	we need to pass this global metadata to the SynopsisMetadataEncoder (if we don't, it'll err when we try to export the JSON sidecar data)
	[synopsisEncoder
		encodeSynopsisMetadataToMetadataItem:self.globalMetadata
		timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)];
	
	//	write the finalized metadata to the appropriate file
	if (self.synopsisOpts != nil)	{
		NSURL			*targetURL = /*(self.tmpFile != nil) ? self.tmpFile :*/ self.dstFile;
		//NSString		*targetPathExt = (targetURL==nil) ? nil : [targetURL pathExtension];
		AVFileType		exportFileType = AVFileTypeQuickTimeMovie;
		//if (targetPathExt!=nil && [targetPathExt caseInsensitiveCompare:@"mp4"]==NSOrderedSame)
		//	exportFileType = AVFileTypeMPEG4;
		NSError				*nsErr = nil;
		AVMutableMovie		*mov = [[AVMutableMovie alloc]
			initWithURL:targetURL
			options:nil
			error:&nsErr];
		if (mov == nil || nsErr != nil)	{
			NSLog(@"ERR: couldnt append global metadata to output movie, %@",self);
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_AVFErr;
			self.jobErrString = @"Couldn't append global metadata to output movie";
			[self _cleanUp];
			return;
		}
	
		AVMutableMetadataItem		*newMDItem = [AVMutableMetadataItem metadataItem];
		//if (exportFileType == AVFileTypeMPEG4)	{
		//	[newMDItem setKeySpace:AVMetadataKeySpaceISOUserData];
		//	[newMDItem setKey:@"snpX"];
		//}
		//else	{
			[newMDItem setKeySpace:AVMetadataKeySpaceQuickTimeMetadata];
			[newMDItem setKey:@"info.synopsis.metadata"];
		//}
		[newMDItem setIdentifier:[AVMetadataItem identifierForKey:[newMDItem key] keySpace:[newMDItem keySpace]]];
		[newMDItem setDataType:(NSString*)kCMMetadataBaseDataType_RawData];
		[newMDItem setTime:kCMTimeInvalid];
		[newMDItem setDuration:kCMTimeInvalid];
		[newMDItem setStartDate:nil];
		[newMDItem setExtraAttributes:@{
			@"dataType": @0,
			@"dataTypeNamespace": @"com.apple.quicktime.mdta"
		}];
		
		NSData				*mdValData = [synopsisEncoder encodeSynopsisMetadataToData:self.globalMetadata];
		[newMDItem setValue:mdValData];
		
		NSArray				*mdItems = @[ newMDItem ];
		[mov setMetadata:mdItems];
	
		//	export the sidecare file (if appropriate)
		if (synopsisEncoder != nil && synopsisEncoder.exportOption != SynopsisMetadataEncoderExportOptionNone)	{
			NSURL			*sidecarURL = [[self.dstFile URLByDeletingPathExtension] URLByAppendingPathExtension:@"json"];
			[synopsisEncoder exportToURL:sidecarURL];
		}
		
		if (![mov
			writeMovieHeaderToURL:targetURL
			fileType:exportFileType
			options:AVMovieWritingAddMovieHeaderToDestination
			error:&nsErr])	{
			NSString		*errString = @"Err: couldnt write movie header to file";
			if (nsErr != nil)
				errString = [errString stringByAppendingFormat:@" %@",[nsErr localizedDescription]];
			NSLog(errString);
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_AVFErr;
			self.jobErrString = errString;
			[self _cleanUp];
			return;
		}
		
		//	update the xattrs so spotlight has an easier time finding this file...
		
		NSDictionary		*standardOutputs = self.globalMetadata[kSynopsisStandardMetadataDictKey];
		NSArray				*descriptionTags = standardOutputs[kSynopsisStandardMetadataDescriptionDictKey];
		if (![self file:targetURL xattrSetPlist:descriptionTags forKey:kSynopsisMetadataHFSAttributeDescriptorKey])	{
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_File;
			self.jobErrString = @"Error updating xattr metadata for file";
			[self _cleanUp];
			return;
		}
		NSArray				*mdVersion = @( synopsisEncoder.version );
		if (![self file:targetURL xattrSetPlist:mdVersion forKey:kSynopsisMetadataHFSAttributeVersionKey])	{
			self.jobStatus = JOStatus_Err;
			self.jobErr = JOErr_File;
			self.jobErrString = @"Error updating xattr metadata for file";
			[self _cleanUp];
			return;
		}
	}
	
	//	clean up
	[self _cleanUp];
	
	//NSLog(@"total time: %0.2f seconds",[self jobTimeElapsed]);
}
- (void) _cancelAndCleanUp	{
	NSLog(@"%s",__func__);
	pthread_mutex_lock(&theLock);
	{
		if (writer != nil)	{
			[writer cancelWriting];
			writer = nil;
		}
		if (reader != nil)	{
			[reader cancelReading];
			reader = nil;
		}
	}
	pthread_mutex_unlock(&theLock);
	
	[self _cleanUp];
}
- (void) _cleanUp	{
	//NSLog(@"%s",__func__);
	pthread_mutex_lock(&theLock);
	{
		NSArray<NSMutableArray*>		*outputArrays = @[ readerVideoPassthruOutputs,readerVideoAnalysisOutputs,readerAudioPassthruOutputs,readerAudioAnalysisOutputs,readerMiscPassthruOutputs ];
		for (NSMutableArray *outputArray in outputArrays)	{
			[outputArray removeAllObjects];
		}
		NSArray<NSMutableArray*>		*inputArrays = @[ writerVideoInputs,writerAudioInputs,writerMiscInputs,writerMetadataInputs,writerMetadataInputAdapters ];
		for (NSMutableArray *inputArray in inputArrays)	{
			[inputArray removeAllObjects];
		}
	}
	pthread_mutex_unlock(&theLock);
	
	//	if the job didn't complete....
	if (self.jobStatus != JOStatus_Complete)	{
		//	trash the dst and tmp files
		self.jobProgress = 0.0;
		NSFileManager		*fm = [NSFileManager defaultManager];
		/*
		if (self.tmpFile != nil)	{
			if ([fm fileExistsAtPath:[self.tmpFile path]])	{
				//[fm trashItemAtURL:self.tmpFile resultingItemURL:nil error:nil];
				[fm removeItemAtURL:self.tmpFile error:nil];
			}
		}
		*/
		if (self.dstFile != nil)	{
			if ([fm fileExistsAtPath:[self.dstFile path]])	{
				//[fm trashItemAtURL:self.dstFile resultingItemURL:nil error:nil];
				[fm removeItemAtURL:self.dstFile error:nil];
			}
		}
	}
	//	else the job completed successfully!  hooray!
	else	{
		self.jobProgress = 1.0;
		self.jobErrString = nil;
		//	do any file copying outside this class...
		/*
		//	if there's a temp file
		if (self.tmpFile != nil)	{
			NSFileManager		*fm = [NSFileManager defaultManager];
			NSError				*nsErr = nil;
			//	if i couldn't copy the temp file to the dst file, err out
			if (![fm copyItemAtURL:self.tmpFile toURL:self.dstFile error:&nsErr])	{
				NSLog(@"ERR: couldn't copy tmp file to dst file, %@",nsErr);
				self.jobProgress = 0.0;
				self.jobStatus = JOStatus_Err;
				self.jobErr = JOErr_CantWriteDest;
				if (nsErr == nil)
					self.jobErrString = @"Couldnt copy tmp file to dst file";
				else
					self.jobErrString = [NSString stringWithFormat:@"Couldnt copy tmp file to dst file: %@",[nsErr localizedDescription]];
			}
			//	else i copied the temp file to the dest file- trash the temp file
			else	{
				//[fm trashItemAtURL:self.tmpFile resultingItemURL:nil error:nil];
				[fm removeItemAtURL:self.tmpFile error:nil];
			}
		}
		*/
	}
	
	self.availableAnalyzers = nil;
	
    self.device = nil;
    
	if (self.completionBlock != nil)
		self.completionBlock(self);
	
	id<BaseJobObjectDelegate>		localDelegate = self.delegate;
	if (localDelegate != nil)
		[localDelegate finishedJob:self];
}
- (BOOL) file:(NSURL *)fileURL xattrSetPlist:(id)plist forKey:(NSString *)key	{
	//NSLog(@"%s ... %@: %@",__func__,plist,key);
	if (plist==nil || key==nil || fileURL==nil)
		return NO;
	if ([NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListBinaryFormat_v1_0])	{
		NSError				*nsErr = nil;
		NSData				*plistData = [NSPropertyListSerialization
			dataWithPropertyList:plist
			format:NSPropertyListBinaryFormat_v1_0
			options:0
			error:&nsErr];
		if (plistData != nil)	{
			int					tmpErr = setxattr(
				[fileURL fileSystemRepresentation],
				[[@"com.apple.metadata:" stringByAppendingString:key] UTF8String],
				plistData.bytes,
				plistData.length,
				0,
				XATTR_NOFOLLOW);
			if (tmpErr != 0)	{
				return NO;
			}
			return YES;
		}
	}
	return NO;
}


@end



































