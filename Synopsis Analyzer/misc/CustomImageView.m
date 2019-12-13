//
//  CustomImageView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 12/13/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "CustomImageView.h"
#import "NSImageAdditions.h"




@implementation CustomImageView


- (void) awakeFromNib	{
	NSOperatingSystemVersion		vers = {.majorVersion = 10, .minorVersion = 14, .patchVersion = 0};
	if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:vers])	{
		NSImage		*baseImg = [NSImage imageNamed:@"DragFileGraphic"];
		//NSImage		*tintedImg = [baseImg imageTintedWithColor:[NSColor lightGrayColor]];
		NSImage		*tintedImg = [baseImg imageTintedWithColor:[NSColor grayColor]];
		[self setImage:tintedImg];
	}
}

- (void) drawRect:(NSRect)r	{
	
	NSOperatingSystemVersion		vers = {.majorVersion = 10, .minorVersion = 14, .patchVersion = 0};
	if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:vers])	{
		//[[NSColor windowBackgroundColor] set];
		[[NSColor darkGrayColor] set];
		//[[NSColor blackColor] set];
		//[[NSColor colorWithDeviceRed:0.08 green:0.08 blue:0.08 alpha:1.0] set];
		NSRectFill(r);
	}
	
	[super drawRect:r];
}

@end
