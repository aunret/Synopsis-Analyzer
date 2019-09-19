//
//	DropFilesView.h
//	MetadataTranscoderTestHarness
//
//	Created by vade on 5/12/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//
#import <Cocoa/Cocoa.h>

@protocol DropFileHelper <NSObject>

@required
- (void) analysisSessionForFiles:(NSArray *)fileURLArray sessionCompletionBlock:(void (^)(void))completionBlock;
@end


@interface DropFilesView : NSView<NSDraggingDestination>
@property (weak) id<DropFileHelper> dragDelegate;
@end
