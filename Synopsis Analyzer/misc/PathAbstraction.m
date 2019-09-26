//
//  PathAbstraction.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/19/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PathAbstraction.h"




static const NSString * SPECIALIGNOREVALUE = @"XXXIGNOREMEXXX";




@interface PathAbstraction()

//	this property stores the original value of 'statusTextField' (the value set in interface builder)
@property (atomic,strong,nonnull) NSString * origStatusTextFieldValue;

- (void) _updateUI;

@end




@implementation PathAbstraction


- (id) init	{
	self = [super init];
	if (self != nil)	{
		self.path = nil;
		self.enabled = NO;
		self.selectButtonBlock = nil;
		self.enableToggleBlock = nil;
		
		//	set a known-bad value for this property so we know we need to update it the first time the UI is updated
		self.origStatusTextFieldValue = [SPECIALIGNOREVALUE copy];
	}
	return self;
}
- (void) awakeFromNib	{
	//	update the UI
	[self _updateUI];
}


#pragma mark - public key-value methods


@synthesize path=myPath;
- (void) setPath:(NSString *)n	{
	myPath = n;
	//	update the UI
	[self _updateUI];
}
- (NSString *) path	{
	return myPath;
}
@synthesize enabled=myEnabled;
- (void) setEnabled:(BOOL)n	{
	myEnabled = n;
	//	update the UI
	[self _updateUI];
}
- (BOOL) enabled	{
	return myEnabled;
}
- (NSURL *) url	{
	NSString		*tmpString = [self path];
	if (tmpString == nil)
		return nil;
	return [NSURL fileURLWithPath:tmpString];
}


#pragma mark - UI methods


- (IBAction) enableToggleUsed:(id)sender	{
	self.enabled = ([enableToggle intValue]==NSControlStateValueOn) ? YES : NO;
	//	update the UI
	[self _updateUI];
	//	if there's an enable toggle block, execute it now
	if (self.enableToggleBlock != nil)
		self.enableToggleBlock();
}
- (IBAction) selectButtonUsed:(id)sender	{
	//	execute 'selectButtonBlock', which should open an NSOpenPanel that calls 'setPath:' from within its completion block
	if (self.selectButtonBlock != nil)
		self.selectButtonBlock(self);
}
- (IBAction) revealButtonUsed:(id)sender	{
	//	open a folder displaying the appropriate path
	NSURL				*tmpURL = [self url];
	if (tmpURL == nil)
		return;
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ tmpURL ]];
}


#pragma mark - internal methods


- (void) _updateUI	{
	//	store the original value of the 'status' text field (we don't know when this method is first called so we need to ensure that this is done even if something else has its 'awakeFromNib' called before this instance of PathAbstraction)
	if ([self.origStatusTextFieldValue isEqualToString:[SPECIALIGNOREVALUE copy]])	{
		NSString			*tmpString = (statusTextField==nil || ![statusTextField isKindOfClass:[NSTextField class]]) ? nil : [statusTextField stringValue];
		if (tmpString != nil)
			self.origStatusTextFieldValue = tmpString;
	}
	
	NSString			*tmpString = self.path;
	BOOL				tmpBool = self.enabled;
	
	//	...actually update the UI!
	
	//	the enable toggle is straightforward...
	[enableToggle setIntValue:(tmpBool) ? NSControlStateValueOn : NSControlStateValueOff];
	
	//	the status text field is either the orig status text field value, or the path
	[statusTextField setStringValue:(tmpString==nil) ? self.origStatusTextFieldValue : tmpString];
	
	//	if the enable toggle is disabled, the status button is disabled
	if (!tmpBool)	{
		[statusButton setImage:[NSImage imageNamed:NSImageNameStatusNone]];
	}
	//	else the enable toggle is enabled...
	else	{
		NSFileManager			*fm = [NSFileManager defaultManager];
		//	if there's a path AND the path is a valid file/folder, the enable toggle is enabled
		if (tmpString!=nil && [fm fileExistsAtPath:tmpString])	{
			[statusButton setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
		}
		//	else the enable toggle is disabled
		else	{
			[statusButton setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
		}
	}
}


@end
