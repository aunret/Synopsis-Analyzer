//
//  PrefsPathAbstraction.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/19/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PrefsPathAbstraction.h"




static const NSString * SPECIALIGNOREVALUE = @"XXXIGNOREMEXXX";




@interface PrefsPathAbstraction()

//	this property stores the key at which the path is saved in NSUserDefaults
@property (atomic,strong,nullable) NSString * internalUserDefaultsKey;

//	this property stores the original value of 'statusTextField' (the value set in interface builder)
@property (atomic,strong,nonnull) NSString * origStatusTextFieldValue;

- (void) _updateUI;
- (NSString *) _deriveEnableKey;
//- (void) _storeOrigStatusTextFieldValue;

@end




@implementation PrefsPathAbstraction


- (id) init	{
	self = [super init];
	if (self != nil)	{
		self.selectButtonBlock = nil;
		self.enableToggleBlock = nil;
		
		self.internalUserDefaultsKey = nil;
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


- (void) setUserDefaultsKey:(NSString *)n	{
	//	set the property
	self.internalUserDefaultsKey = n;
	//	update the UI
	[self _updateUI];
}
- (void) setPath:(NSString *)n	{
	//	set up the keys we'll need to store the val in the defaults...
	NSString			*valKey = self.internalUserDefaultsKey;
	if (valKey != nil)	{
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		[def setObject:n forKey:valKey];
		[def synchronize];
	}
	//	update the UI
	[self _updateUI];
}
- (NSString *) path	{
	//	set up the keys we'll need to retrieve the vals from the defaults...
	NSString			*valKey = self.internalUserDefaultsKey;
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	//	get and return the value
	NSString			*tmpString = (valKey==nil) ? nil : [def stringForKey:valKey];
	return tmpString;
}
- (NSURL *) url	{
	NSString		*tmpString = [self path];
	if (tmpString == nil)
		return nil;
	return [NSURL fileURLWithPath:tmpString];
}
- (BOOL) enabled	{
	//	set up the keys we'll need to retrieve the vals from the defaults...
	NSString			*valKey = self.internalUserDefaultsKey;
	NSString			*enableKey = [self _deriveEnableKey];
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	//	if this hasn't been enabled, return nil (even if it may have a value)
	BOOL				tmpBool = (enableKey==nil) ? NO : [def boolForKey:enableKey];
	return tmpBool;
}


#pragma mark - UI methods


- (IBAction) enableToggleUsed:(id)sender	{
	//	update the enable val stored in the user defaults
	NSString			*enableKey = [self _deriveEnableKey];
	if (enableKey != nil)	{
		NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
		BOOL				tmpBool = ([enableToggle intValue]==NSControlStateValueOn) ? YES : NO;
		[def setBool:tmpBool forKey:enableKey];
		[def synchronize];
	}
	//	update the UI
	[self _updateUI];
	//	if there's an enable toggle block, execute it now
	if (self.enableToggleBlock != nil)
		self.enableToggleBlock(self);
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
	//	store the original value of the 'status' text field (we don't know when this method is first called so we need to ensure that this is done even if something else has its 'awakeFromNib' called before this instance of PrefsPathAbstraction)
	if ([self.origStatusTextFieldValue isEqualToString:[SPECIALIGNOREVALUE copy]])	{
		NSString			*tmpString = (statusTextField==nil || ![statusTextField isKindOfClass:[NSTextField class]]) ? nil : [statusTextField stringValue];
		if (tmpString != nil)
			self.origStatusTextFieldValue = tmpString;
	}
	
	//	set up the keys we'll need to retrieve the vals from the defaults, bail if we can't
	NSString			*valKey = self.internalUserDefaultsKey;
	NSString			*enableKey = [self _deriveEnableKey];
	if (valKey==nil || enableKey==nil)
		return;
	
	//	retrieve the vals we need to display...
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	NSString			*tmpString = [def stringForKey:valKey];
	BOOL				tmpBool = [def boolForKey:enableKey];
	
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
- (NSString *) _deriveEnableKey	{
	NSString		*returnMe = self.internalUserDefaultsKey;
	if (returnMe == nil)
		return returnMe;
	return [returnMe stringByAppendingString:@"_enableKey"];
}


@end
