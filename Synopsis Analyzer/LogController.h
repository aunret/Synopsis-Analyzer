//
//	LogController.h
//	MetadataTranscoderTestHarness
//
//	Created by vade on 5/12/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LogController : NSWindowController

+ (LogController*) global;

- (IBAction)changeLogLevel:(id)sender;

- (void) appendLog:(NSString*)log;//, ... NS_FORMAT_FUNCTION(1,2);
- (void) appendVerboseLog:(NSString*)log;//, ... NS_FORMAT_FUNCTION(1,2);
- (void) appendWarningLog:(NSString*)log;//, ... NS_FORMAT_FUNCTION(1,2);
- (void) appendErrorLog:(NSString*)log;//, ... NS_FORMAT_FUNCTION(1,2);
- (void) appendSuccessLog:(NSString*)log;//, ... NS_FORMAT_FUNCTION(1,2);

@end
