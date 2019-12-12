//
//	LogController.m
//	MetadataTranscoderTestHarness
//
//	Created by vade on 5/12/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//

#import "LogController.h"




static LogController		*globalLogController = nil;





typedef enum : NSUInteger {
	LogLevelNone = 0,
	LogLevelNormal,
	LogLevelWarning,
	LogLevelVerbose,
} LogLevel;




@interface LogController ()
- (void) generalInit;
@property (atomic, readwrite, assign) LogLevel logLevel;
@property (strong) IBOutlet NSPopUpButton* logLevelPopUpButton;

@property (strong) IBOutlet NSTextView* logTextField;
@property (atomic, readwrite, strong) NSDateFormatter* dateFormatter;
@property (atomic, readwrite, strong) NSDictionary* logStyle;
@property (atomic, readwrite, strong) NSDictionary* verboseStyle;
@property (atomic, readwrite, strong) NSDictionary* warningStyle;
@property (atomic, readwrite, strong) NSDictionary* errorStyle;
@property (atomic, readwrite, strong) NSDictionary* successStyle;

@property (atomic, readwrite, strong) NSAttributedString* staticLogString;
@property (atomic, readwrite, strong) NSAttributedString* staticVerboseString;
@property (atomic, readwrite, strong) NSAttributedString* staticWarningString;
@property (atomic, readwrite, strong) NSAttributedString* staticErrorString;
@property (atomic, readwrite, strong) NSAttributedString* staticSuccessString;
@end




@implementation LogController


+ (LogController*) global	{
	if (globalLogController == nil)	{
		static dispatch_once_t		onceToken;
		dispatch_once(&onceToken, ^{
			globalLogController = [[LogController alloc] init];
		});
	}
	return globalLogController;
}

- (id) init	{
	self = [super initWithWindowNibName:[NSString stringWithFormat:@"%@",[[self class] className]]];
	if (self != nil)	{
		[self generalInit];

	}
	return self;
}

- (void) generalInit	{
	[self window];
	
	self.logLevel = LogLevelNormal;
	
	self.logStyle = @{ NSForegroundColorAttributeName : [NSColor lightGrayColor]};
	self.verboseStyle = @{ NSForegroundColorAttributeName : [NSColor darkGrayColor]};
	self.warningStyle = @{ NSForegroundColorAttributeName : [NSColor yellowColor]};
	self.errorStyle = @{ NSForegroundColorAttributeName : [NSColor redColor]};
	self.successStyle = @{ NSForegroundColorAttributeName : [NSColor greenColor]}; //[NSColor colorWithRed:0 green:0.66 blue:0 alpha:1]};
	
	self.staticLogString = [[NSAttributedString alloc] initWithString:@" [LOG] " attributes:self.logStyle];
	self.staticVerboseString = [[NSAttributedString alloc] initWithString:@" [INFO] " attributes:self.verboseStyle];
	self.staticWarningString = [[NSAttributedString alloc] initWithString:@" [WARNING] " attributes:self.warningStyle];
	self.staticErrorString = [[NSAttributedString alloc] initWithString:@" [ERROR] " attributes:self.errorStyle];
	self.staticSuccessString = [[NSAttributedString alloc] initWithString:@" [SUCCESS] " attributes:self.successStyle];
	
	self.dateFormatter = [[NSDateFormatter alloc] init] ;
	
	//Set the required date format
	[self.dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss : "];
}

- (IBAction)changeLogLevel:(id)sender
{
	NSInteger state = [sender tag];
	
	self.logLevel = LogLevelNormal;
	
	if(state == 0)
		self.logLevel = LogLevelNormal;
	else if(state == 1)
		self.logLevel = LogLevelWarning;
	else if(state == 2)
		self.logLevel = LogLevelVerbose;
}

- (NSMutableAttributedString*) logStringWithDate
{	 
	//Get the string date
	return [[NSMutableAttributedString alloc] initWithString:[self.dateFormatter stringFromDate:[NSDate date] ] attributes:self.logStyle];
}

- (NSMutableAttributedString*) logString
{
	NSMutableAttributedString* string = [self logStringWithDate];
	[string appendAttributedString:self.staticLogString];
	return string;
}

- (NSMutableAttributedString*) verboseString
{
	NSMutableAttributedString* string = [self logStringWithDate];
	[string appendAttributedString:self.staticVerboseString];
	return string;
}

- (NSMutableAttributedString*) warningString
{
	NSMutableAttributedString* string = [self logStringWithDate];
	[string appendAttributedString:self.staticWarningString];
	return string;
}

- (NSMutableAttributedString*) errorString
{
	NSMutableAttributedString* string = [self logStringWithDate];
	[string appendAttributedString:self.staticErrorString];
	return string;
}

- (NSMutableAttributedString*) successString
{
	NSMutableAttributedString* string = [self logStringWithDate];
	[string appendAttributedString:self.staticSuccessString];
	return string;
}

- (NSString*)appendLine:(NSString*)string
{
	unichar newLine = NSLineSeparatorCharacter;
	return [string stringByAppendingString:[NSString stringWithCharacters:&newLine length:1]];
}

+ (void) appendLog:(NSString*)log//, ... NS_FORMAT_FUNCTION(1,2)
{
	LogController		*gl = [LogController global];
	if (gl == nil)
		return;
	if(gl.logLevel >= LogLevelNormal)
	{
		NSAttributedString* logString = [[NSAttributedString alloc] initWithString:[gl appendLine:log] attributes:gl.logStyle];
		NSMutableAttributedString* verboseString = [gl logString];
		[verboseString appendAttributedString:logString];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			[gl.logTextField.textStorage appendAttributedString:verboseString];
		});
	}
}

+ (void) appendVerboseLog:(NSString*)log//, ... NS_FORMAT_FUNCTION(1,2)
{
	LogController		*gl = [LogController global];
	if (gl == nil)
		return;
	if(gl.logLevel >= LogLevelVerbose)
	{
		NSAttributedString* logString = [[NSAttributedString alloc] initWithString:[gl appendLine:log] attributes:gl.verboseStyle];
		NSMutableAttributedString* verboseString = [gl verboseString];
		[verboseString appendAttributedString:logString];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			[gl.logTextField.textStorage appendAttributedString:verboseString];
		});
	}
}

+ (void) appendWarningLog:(NSString*)log//, ... NS_FORMAT_FUNCTION(1,2)
{
	LogController		*gl = [LogController global];
	if (gl == nil)
		return;
	// Always Log Warnings
	NSLog(@" [WARNING] %@", log);
//	  if(gl.logLevel >= LogLevelWarning)
	{
		NSAttributedString* logString = [[NSAttributedString alloc] initWithString:[gl appendLine:log] attributes:gl.logStyle];
		
		NSMutableAttributedString* warningString = [gl warningString];
		[warningString appendAttributedString:logString];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[gl.logTextField.textStorage appendAttributedString:warningString];
		});
	}
}

+ (void) appendErrorLog:(NSString*)log//, ... NS_FORMAT_FUNCTION(1,2)
{
	LogController		*gl = [LogController global];
	if (gl == nil)
		return;
	// Always Log Errors
	NSLog(@" [ERROR] %@", log);
	NSAttributedString* logString = [[NSAttributedString alloc] initWithString:[gl appendLine:log] attributes:gl.logStyle];
	
	NSMutableAttributedString* errorString = [gl errorString];
	[errorString appendAttributedString:logString];

	dispatch_async(dispatch_get_main_queue(), ^{
		[gl.logTextField.textStorage appendAttributedString:errorString];
	});
}

+ (void) appendSuccessLog:(NSString*)log//, ... NS_FORMAT_FUNCTION(1,2)
{
	LogController		*gl = [LogController global];
	if (gl == nil)
		return;
	NSAttributedString* logString = [[NSAttributedString alloc] initWithString:[gl appendLine:log] attributes:gl.logStyle];
	
	NSMutableAttributedString* successString = [gl successString];
	[successString appendAttributedString:logString];

	dispatch_async(dispatch_get_main_queue(), ^{
		
		[gl.logTextField.textStorage appendAttributedString:successString];
	});

}




@end
