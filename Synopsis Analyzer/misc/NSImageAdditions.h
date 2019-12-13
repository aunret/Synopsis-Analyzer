//
//  NSImageAdditions.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 12/13/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (NSImageAdditions)

- (NSImage *)imageTintedWithColor:(NSColor *)tint;

@end

NS_ASSUME_NONNULL_END
