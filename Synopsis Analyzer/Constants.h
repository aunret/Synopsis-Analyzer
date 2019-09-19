//
//  Constants.h
//  Synopsis
//
//  Created by vade on 7/19/17.
//  Copyright © 2017 metavisual. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#import <CoreFoundation/CoreFoundation.h>




#pragma mark - Enums & Constants - 




typedef enum : NSUInteger {
    SessionStateUnknown = 0,
    SessionStatePending,
    SessionStateRunning,
    SessionStateCancelled,
    SessionStateFailed,
    SessionStateSuccess,
} SessionState;


/*
// Support various types of Analysis file handling
// This might seem verbose, but its helpful for edge cases...
// TODO: Move to flags ?
typedef enum : NSUInteger {
    // Bail case
    OperationTypeUnknown = 0,
    
    // temp file and output file adjacent to input file
    OperationTypeFileInPlace,
    // temp file and output file within output folder
    OperationTypeFileToOutput,
    // temp file in temp folder, output file adjacent to input file
    OperationTypeFileToTempToInPlace,
    // temp file in temp folder, output file in output folder
    OperationTypeFileToTempToOutput,
    
    // temp file and output file adjacent to input file, in any subfolder of source URL
    OperationTypeFolderInPlace,
    // temp file flat within temp folder, output file adjacent to input file, in any subfolder of source URL
    OperationTypeFolderToTempToInPlace,
    OperationTypeFolderToTempToOutput,
    
} OperationType;
*/


typedef enum : NSUInteger {
    OperationStateUnknown = 0,
    OperationStatePending,
    OperationStateRunning,
    OperationStateCancelled,
    OperationStateFailed,
    OperationStateSuccess,
} OperationState;


//typedef enum : NSUInteger {
//    OperationPassAnalysis,
//    OperationPassFinal,
//} OperationPass;




#pragma mark - Preferences -




#define kSynopsisAnalyzerDefaultPresetPreferencesKey @"DefaultPreset" // UUID string
#define kSynopsisAnalyzerConcurrentJobAnalysisPreferencesKey @"ConcurrentJobAnalysis" // BOOL

#define kSynopsisAnalyzerConcurrentJobCountPreferencesKey @"ConcurrentJobCount" // NSNumber -1 = auto, anythign else = use that

#define kSynopsisAnalyzerConcurrentFrameAnalysisPreferencesKey @"ConcurrentFrameAnalysis" // BOOL

#define kSynopsisAnalyzerUseWatchFolderKey @"UseWatchFolder" // BOOL
#define kSynopsisAnalyzerUseOutputFolderKey @"UseOutputFolder" // BOOL
#define kSynopsisAnalyzerUseTempFolderKey @"UseTempFolder" // BOOL

#define kSynopsisAnalyzerWatchFolderURLKey @"WatchFolder" // NSString
#define kSynopsisAnalyzerOutputFolderURLKey @"OutputFolder" // NSString
#define kSynopsisAnalyzerTempFolderURLKey @"TempFolder" // NSString

// TODO: Is this necessary or should this just be implicit if we have an output folder selected?
#define kSynopsisAnalyzerMirrorFolderStructureToOutputKey @"MirrorFolderStructureToOutput" // BOOL




#pragma mark - Notifications -




#define kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification @"kSynopsisAnalyzerConcurrentJobAnalysisDidChangeNotification"
#define kSynopsisAnalyzerConcurrentFrameAnalysisDidChangeNotification @"kSynopsisAnalyzerConcurrentFrameAnalysisD"




#pragma mark - Prest-related -




//extern NSString* const kSynopsisAnalysisPresetSettingQualityHintKey;
//extern NSString* const kSynopsisAnalysisPresetSettingExportJSONKey;
#define kSynopsisAnalyzerPresetTitleKey @"Title"
#define kSynopsisAnalyzerPresetAudioSettingsKey @"AudioSettings"
#define kSynopsisAnalyzerPresetVideoSettingsKey @"VideoSettings"
#define kSynopsisAnalyzerPresetAnalysisSettingsKey @"AnalysisSettings"
#define kSynopsisAnalyzerPresetUseAudioKey @"UseAudio"
#define kSynopsisAnalyzerPresetUseVideoKey @"UseVideo"
#define kSynopsisAnalyzerPresetUseAnalysisKey @"Analysis"

#define kSynopsisAnalyzerPresetExportOptionsKey @"ExportJSON"
#define kSynopsisAnalyzerPresetExportJSONKey kSynopsisAnalyzerPresetJSONOptionsKey


#define kSynopsisAnalyzerPresetEditableKey @"Editable"
#define kSynopsisAnalyzerPresetUUIDKey @"PresetUUID"




#endif /* Constants_h */
