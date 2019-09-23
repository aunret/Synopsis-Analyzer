//
//  SessionRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionRowView.h"

#import "PrefsController.h"
#import "SynSession.h"

#import "NSPopUpButtonAdditions.h"




@interface SessionRowView ()
- (void) generalInit;
@end




@implementation SessionRowView


- (instancetype) initWithFrame:(NSRect)n	{
	self = [super initWithFrame:n];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (instancetype) initWithCoder:(NSCoder *)n	{
	self = [super initWithCoder:n];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
}
- (void) awakeFromNib	{
	PrefsController		*pc = [PrefsController global];
	[pc populatePopUpButtonWithPresets:presetPUB];
}


- (void) refreshWithSession:(SynSession *)n	{
	self.session = n;
	[self refreshUI];
}
- (void) refreshUI	{
	if (self.session == nil)	{
		[enableToggle setIntValue:NSControlStateValueOff];
		[nameField setStringValue:@""];
		[presetPUB selectItemWithRepresentedObject:nil andOutput:NO];
		[tabView selectTabViewItemAtIndex:0];
		[descriptionField setStringValue:@"XXX"];
		return;
	}
	
	[enableToggle setIntValue:(self.session.enabled) ? NSControlStateValueOn : NSControlStateValueOff];
	[nameField setStringValue:@"Session"];
	[presetPUB selectItemWithRepresentedObject:self.session.preset andOutput:NO];
	
	double			tmpProgress = [self.session calculateProgress];
	if (tmpProgress < 0.0)	{
		[tabView selectTabViewItemAtIndex:0];
		[descriptionField setStringValue:[self.session createDescriptionString]];
	}
	else	{
		[tabView selectTabViewItemAtIndex:1];
		[progressIndicator setDoubleValue:tmpProgress];
	}
}


- (IBAction) enableToggleUsed:(id)sender	{
	if (self.session == nil)	{
		[self refreshUI];
		return;
	}
	self.session.enabled = ([sender intValue]==NSControlStateValueOn) ? YES : NO;
}
- (IBAction) presetPUBItemSelected:(id)sender	{
	//NSLog(@"%s ... %@",__func__,[(NSMenuItem *)sender representedObject]);
	PresetObject		*newPreset = (sender==nil || ![sender isKindOfClass:[NSMenuItem class]]) ? nil : [(NSMenuItem*)sender representedObject];
	if (newPreset != nil && ![newPreset isKindOfClass:[PresetObject class]])
		newPreset = nil;
	self.session.preset = newPreset;
}
- (IBAction) nameFieldUsed:(id)sender	{
}


@end
