//
//  NSStringAdditions.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/27/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSStringAdditions.h"

@implementation NSString (NSStringAdditions)



+ (NSString *) smpteStringForTimeInSeconds:(double)time withFPS:(double)fps	{
	NSString		*returnMe = nil;
	double			smpteFPS = fps;
	BOOL			isNegative = (time < 0) ? YES : NO;
	double			rangedVal = (time < 0) ? -1.0 * time : time;
	
	long	tmpVal = floor(rangedVal);
	int		f = 0;
	int		h = 0;
	int		m = 0;
	int		s = 0;
	//NSLog(@"\t\tfps is %f, val is %f",smpteFPS,(rangedVal-floor(rangedVal)));
	//	note that a +1 is added for the frames because the start time is at 0:0:0:1
	//f = floor((rangedVal - floor(rangedVal)) * smpteFPS) + 1;
	f = round((rangedVal - floor(rangedVal)) * smpteFPS);
	if (f >= smpteFPS)
		f = ceil(smpteFPS) - 1.0;
	//NSLog(@"\t\tcalculated f is %d",f);
	s = tmpVal % 60;
	tmpVal = tmpVal / 60.0;
	m = tmpVal % 60;
	tmpVal = tmpVal / 60.0;
	h = tmpVal % 60;
	//NSLog(@"\t\t%d:%d:%d:%d",h,m,s,f);
	if (isNegative)
		returnMe = [NSString stringWithFormat:@"-%0.2d:%0.2d:%0.2d.%0.2d",h,m,s,f];
	else
		returnMe = [NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d.%0.2d",h,m,s,f];
	
	return returnMe;
}


@end
