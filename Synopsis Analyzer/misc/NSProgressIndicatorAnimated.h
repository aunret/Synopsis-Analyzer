//
//  NSProgressIndicatorAnimated.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/28/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSProgressIndicatorAnimated : NSProgressIndicator

- (void) animateToValue:(double)n;
- (void) killAnimationSetDoubleValue:(double)n;

@end

NS_ASSUME_NONNULL_END
