//
//  NSStringAdditions.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/27/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (NSStringAdditionsSMPTE)

//	this presumes a start time of 0:0:0:1 for when describing the current play time
+ (NSString *) smpteStringForTimeInSeconds:(double)time withFPS:(double)fps;

@end

NS_ASSUME_NONNULL_END
