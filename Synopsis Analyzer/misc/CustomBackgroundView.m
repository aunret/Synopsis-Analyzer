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
	[self setState:NSVisualEffectStateActive];
	[self setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
	[self.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
	[self setMaterial:NSVisualEffectMaterialUltraDark];
}
/*
- (void)drawRect:(NSRect)dirtyRect {
	//[super drawRect:dirtyRect];
	
	// Drawing code here.
	[[NSColor darkGrayColor] set];
	
	NSRectFill(dirtyRect);
}
*/
@end
