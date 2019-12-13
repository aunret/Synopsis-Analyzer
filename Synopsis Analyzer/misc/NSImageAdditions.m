//
//  NSImageAdditions.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 12/13/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSImageAdditions.h"

@implementation NSImage (NSImageAdditions)

- (NSImage *)imageTintedWithColor:(NSColor *)tint	{
	NSImage *image = [self copy];
	[image setTemplate:NO];
	if (tint) {
		[image lockFocus];
		[tint set];
		NSRect imageRect = {NSZeroPoint, [image size]};
		NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
		[image unlockFocus];
	}
	return image;
}

@end
