//
//  SessionRowView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionRowView.h"

#import "SynSession.h"




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


- (void) refreshWithSession:(SynSession *)n	{
}
- (void) refreshUI	{
}

- (IBAction) enableToggleUsed:(id)sender	{
}
- (IBAction) presetPUBUsed:(id)sender	{
}
- (IBAction) nameFieldUsed:(id)sender	{
}


@end
