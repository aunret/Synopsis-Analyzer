//
//	NSColor+SynopsisStatusColors.m
//	Synopsis Analyzer
//
//	Created by vade on 10/25/19.
//	Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSColor+SynopsisStatusColors.h"

#import <AppKit/AppKit.h>


@implementation NSColor (SynopsisStatusColors)

+ (NSColor*) synopsisErrorColor
{
	return [NSColor systemRedColor];
	//return [NSColor colorWithCalibratedRed:0.8 green:0 blue:0 alpha:1.0];
}

+ (NSColor*) synopsisSuccessColor
{
	//return [NSColor controlTextColor];
	return [NSColor colorWithCalibratedRed:0.0 green:0.8 blue:0 alpha:1.0];
}

+ (NSColor*) synopsisWarningColor
{
	return [NSColor systemRedColor];
	//return [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0 alpha:1.0];
}

@end
