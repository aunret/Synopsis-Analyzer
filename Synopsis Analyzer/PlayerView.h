//
//  PlayerView.h
//  Synopsis Inspector
//
//  Created by vade on 10/18/18.
//  Copyright © 2018 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HapInAVFoundation/HapInAVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerView : NSView
@property (readonly) AVPlayerHapLayer* playerLayer;
- (void) seekToTime:(CMTime)seekTime;

@end

NS_ASSUME_NONNULL_END
