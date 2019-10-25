//
//  NSColor+SynopsisStatusColors.h
//  Synopsis Analyzer
//
//  Created by vade on 10/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <AppKit/AppKit.h>


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSColor (SynopsisStatusColors)

+ (NSColor*) synopsisErrorColor;
+ (NSColor*) synopsisSuccessColor;
+ (NSColor*) synopsisWarningColor;

@end

NS_ASSUME_NONNULL_END
