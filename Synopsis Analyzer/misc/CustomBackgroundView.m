//
//	CustomBackgroundView.m
//	Synopsis
//
//	Created by vade on 12/26/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "CustomBackgroundView.h"

@implementation CustomBackgroundView

- (void) awakeFromNib
{
	[self setState:NSVisualEffectStateInactive];
	[self setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
	[self.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
}

- (void)drawRect:(NSRect)dirtyRect {
	//[super drawRect:dirtyRect];
	
	// Drawing code here.
	[[NSColor darkGrayColor] set];
	
	NSRectFill(dirtyRect);
}

@end
