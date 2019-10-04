//
//  SynopsisJobObject.h
//  SynopsisCleanRoom
//
//  Created by ray on 8/26/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN




#pragma mark - enums




//	enum describing the various job status states
typedef NS_ENUM(NSInteger, JOStatus)	{
	JOStatus_Unknown = 0,
	JOStatus_NotStarted,
	JOStatus_InProgress,
	JOStatus_Err,
	JOStatus_Complete,
	JOStatus_Cancel,
	JOStatus_Paused
};
//	enum describing the various job error states.  may be augmented with 'jobErr' string property.
typedef NS_ENUM(NSInteger, JOErr)	{
	JOErr_NoErr = 0,
	JOErr_NoSrcFile,	//	src file couldn't be accessed
	JOErr_CantWriteDest,	//	dest file or tmp file can't be written
	JOErr_AVFErr,	//	AVF-specific err
	JOErr_Transcode,	//	transcode-specific err
	JOErr_Analysis,	//	analysis-specific err
	JOErr_File	//	file-related err
};




#pragma mark - keys used in JSON object init method




//	required to be non-nil.  associated val is an NSString describing the path to the src file
extern NSString * const kSynopsisSrcFileKey;

//	required to be non-nil.  associated val is an NSString describing the path to the dst file.  if kSynopsisTmpDirKey is non-nil, file will be copied here when done, else file will be written here during processing.
extern NSString * const kSynopsisDstFileKey;

//	associated val is dict that gets passed to AVAssetWriterInput describing video transcode settings.  if nil or NSNull, don't transcode video (passthrough)
extern NSString * const kSynopsisTranscodeVideoSettingsKey;

//	associated val is dict that gets passed to AVAssetWriterInput describing audio transcode settings.  if nil or NSNull, don't transcode audio (passthrough)
extern NSString * const kSynopsisTranscodeAudioSettingsKey;


//	associated val is a dict that describes the analysis settings.  if nil or NSNull, don't perform synopsis analysis.
extern NSString * const kSynopsisAnalysisSettingsKey;

	// Key whose value is an NSNumber wrapping a SynopsisAnalysisQualityHint enum val to use for the analysis session.
	extern NSString * const kSynopsisAnalysisSettingsQualityHintKey;

	// Key whose value is an NSNumber/bool to enable threaded / concurrent analysis for modules and plugins.
	extern NSString * const kSynopsisAnalysisSettingsEnableConcurrencyKey;

	// Key whose value is an NSArray of NSStrings which are classnames of enabled pluggins used for the analysis session
	extern NSString * const kSynopsisAnalysisSettingsEnabledPluginsKey;

	// Key whose value is an NSDictionary of key value pairs of Encoder class names and an array of NSStrings modules enabled.
	extern NSString * const kSynopsisAnalysisSettingsEnabledPluginModulesKey;

	//	optional- val is NSNumber/bool indicating whether metadata should be exported as sidecar file (?)
	extern NSString * const kSynopsisAnalyzedMetadataExportOptionKey;


//	key whose value is a NSNumber/bool indicating whether or not the encode should be multi-pass.  only relevant in video transcode options dict (val associated with kSynopsisTranscodeVideoSettingsKey)
extern NSString * const VVAVVideoMultiPassEncodeKey;

//	key whose value is a NSNumber/bool indicating whether or not the track of this type should be stripped.  only relevant in video or audio transcode options dicts (a positive val indicates that the corresponding tracks should be stripped)
extern NSString * const kSynopsisStripTrackKey;




#pragma mark -




//	this delegate object is one way for a client to receive a notification that a job has completed (the completion block passed in on init is another)
@protocol BaseJobObjectDelegate
- (void) finishedJob:(id)finished;
@end




@interface SynopsisJobObject : NSObject

+ (NSString *) stringForStatus:(JOStatus)inStatus;
+ (NSString *) stringForErrorType:(JOErr)inErr;

+ (instancetype) createWithJobJSONString:(NSString *)inJSONStr completionBlock:(void (^)(SynopsisJobObject *theJob))inCompletionBlock;
- (instancetype) initWithSrcFile:(NSURL *)inSrcFile dstFile:(NSURL *)inDstFile videoTransOpts:(NSDictionary *)inVidTransOpts audioTransOpts:(NSDictionary *)inAudioTransOpts synopsisOpts:(NSDictionary *)inSynopsisOpts completionBlock:(void (^)(SynopsisJobObject *theJob))inCompletionBlock;

@property (atomic, readwrite, weak, nullable) id<BaseJobObjectDelegate> delegate;
@property (atomic, readwrite) JOStatus jobStatus;
@property (atomic, readwrite) JOErr jobErr;
@property (atomic, readwrite, strong, nullable) NSString * jobErrString;

@property (atomic, readwrite) double jobProgress;
@property (atomic, strong) NSDate * jobStartDate;
- (NSTimeInterval) jobTimeElapsed;
- (NSTimeInterval) jobTimeRemaining;

- (void) start;
- (void) cancel;
- (void) setPaused:(BOOL)n;
- (BOOL) paused;

@end




NS_ASSUME_NONNULL_END
