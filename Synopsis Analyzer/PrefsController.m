//
//  PrefsController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/17/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "PrefsController.h"
#import "PreferencesViewController.h"




PrefsController			*globalPrefsController = nil;




@interface PrefsController ()
- (void) generalInit;
@end




@implementation PrefsController


+ (PrefsController *) global	{
	if (globalPrefsController == nil)
		[[PrefsController alloc] init];
	return globalPrefsController;
}


- (id) init	{
	self = [super initWithWindowNibName:[NSString stringWithFormat:@"%@",[[self class] className]]];
	if (self != nil)	{
		globalPrefsController = self;
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	[self window];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
- (void) awakeFromNib	{
	NSLog(@"%s",__func__);
	[prefsViewController view];
}

@end
