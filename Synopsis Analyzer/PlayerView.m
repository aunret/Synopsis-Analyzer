//
//  PlayerView.m
//  Synopsis Inspector
//
//  Created by vade on 10/18/18.
//  Copyright © 2018 v002. All rights reserved.
//

#import "PlayerView.h"

#define CORNER_RADIUS     6.0     // corner radius of the shape in points
#define BORDER_WIDTH      1.0     // thickness of border when shown, in points

#define BGCOLOR 0.025
#define SELECTEDBGCOLOR 0.05

#define BORDERCOLOR 0.2
#define SELECTEDBORDERCOLOR 0.6


@interface PlayerView ()
@property (readwrite) AVPlayerHapLayer* playerLayer;
@property (readwrite) CALayer* playheadLayer;

@property (strong) IBOutlet NSTextField* currentTimeFromStart;
@property (strong) IBOutlet NSTextField* currentTimeToEnd;

@end


@implementation PlayerView

- (instancetype) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        [self commonInit];
    }
    return self;
}

- (void) awakeFromNib
{
    [self commonInit];
}

- (void) dealloc
{
    [self.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}


- (void) commonInit
{
    self.layer.backgroundColor = [NSColor colorWithWhite:BGCOLOR alpha:1.0].CGColor;
    self.layer.borderColor = [NSColor colorWithWhite:BORDERCOLOR alpha:1.0].CGColor;
    self.layer.borderWidth = BORDER_WIDTH;//(self.borderColor ? BORDER_WIDTH : 0.0);
    self.layer.cornerRadius = CORNER_RADIUS;
    
    self.currentTimeToEnd.layer.opacity = 0.0;
    self.currentTimeFromStart.layer.opacity = 0.0;
    
    self.playerLayer = [AVPlayerHapLayer layer];
    self.playerLayer.frame = self.layer.bounds;
    self.playerLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
//        self.playerLayer.asynchronous = YES;
    self.playerLayer.actions = @{@"contents" : [NSNull null], @"opacity" : [NSNull null]};
    
    [self.layer insertSublayer:self.playerLayer below:self.currentTimeFromStart.layer];
    
    self.playheadLayer = [CALayer layer];
    self.playheadLayer.frame = CGRectMake(0, 0, 1, self.layer.frame.size.height);
    self.playheadLayer.backgroundColor = [NSColor redColor].CGColor;
    self.playheadLayer.minificationFilter = kCAFilterNearest;
    self.playheadLayer.magnificationFilter = kCAFilterNearest;
    //    self.playheadLayer.compositingFilter = [CIFilter filterWithName:@"CIDifferenceBlendMode"];
    self.playheadLayer.actions = @{@"position" : [NSNull null]};
    self.playheadLayer.opacity = 1.0;
    self.playheadLayer.autoresizingMask =  kCALayerWidthSizable | kCALayerHeightSizable;

    [self.layer insertSublayer:self.playheadLayer above:self.playerLayer];
 
    [self.playerLayer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:NULL];
}


// If we lazily become ready to play, and we are not in optimize moment (scrolling) show then
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context
{
    if(object == self.playerLayer)
    {
        if(self.playerLayer.readyForDisplay)
        {
//                [self.playerLayer endOptimize];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL) allowsVibrancy
{
    return NO;
}


- (void) mouseMoved:(NSEvent *)event
{
    [self scrubViaEvent:event];
}

- (void) mouseEntered:(NSEvent *)theEvent
{
    //    [self.playerLayer play];
    [self scrubViaEvent:theEvent];
}

- (void) scrubViaEvent:(NSEvent*)theEvent
{
    self.playheadLayer.opacity = 1.0;
    //    self.label.layer.opacity = 1.0;
    self.currentTimeToEnd.layer.opacity = 1.0;
    self.currentTimeFromStart.layer.opacity = 1.0;

    NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
    
    CGFloat normalizedMouseX = mouseLocation.x / self.bounds.size.width;
    
    CMTime seekTime = CMTimeMultiplyByFloat64(self.playerLayer.player.currentItem.duration, normalizedMouseX);
    
    [self seekToTime:seekTime];
    // This is so ugly
    //    BOOL requiresFrameReordering = [[self.playerLayer.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] firstObject].requiresFrameReordering;
    
    //    if(requiresFrameReordering)
    //    {
    //        tolerance = kCMTimePositiveInfinity;
    //    }
}

- (void) seekToTime:(CMTime)seekTime
{
    CMTime tolerance = kCMTimeZero;
    CGFloat playheadPosition = CMTimeGetSeconds(seekTime) / CMTimeGetSeconds(self.playerLayer.player.currentItem.duration) * self.bounds.size.width;
    
    [self.playerLayer.player seekToTime:seekTime toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat height = self.playerLayer.videoRect.size.height;
            
            self.playheadLayer.frame = CGRectMake( playheadPosition  , (self.bounds.size.height - height) * 0.5, 1, height);
            
            CMTime currentTime = self.playerLayer.player.currentTime;
            
            Float64 currentTimeInSeconds = CMTimeGetSeconds(currentTime);
            Float64 durationInSeconds = CMTimeGetSeconds(self.playerLayer.player.currentItem.duration);
            
            Float64 hours = floor(currentTimeInSeconds / (60.0 * 60.0));
            Float64 minutes = floor(currentTimeInSeconds / 60.0);
            Float64 seconds = fmod(currentTimeInSeconds, 60.0);
            
            self.currentTimeFromStart.stringValue = [NSString stringWithFormat:@"%02.f:%02.f:%02.f", hours, minutes, seconds];
            
            Float64 reminaingInSeconds = durationInSeconds - currentTimeInSeconds;
            Float64 reminaingHours = floor(reminaingInSeconds / (60.0 * 60.0));
            Float64 reminaingMinutes = floor(reminaingInSeconds / 60.0);
            Float64 reminaingSeconds = fmod(reminaingInSeconds, 60.0);
            
            self.currentTimeToEnd.stringValue = [NSString stringWithFormat:@"-%02.f:%02.f:%02.f", reminaingHours, reminaingMinutes, reminaingSeconds];
            
            [self.playerLayer setNeedsDisplay];
        });
    }];
}

- (void) mouseExited:(NSEvent *)theEvent
{
    self.playheadLayer.opacity = 0.0;
    self.currentTimeToEnd.layer.opacity = 0.0;
    self.currentTimeFromStart.layer.opacity = 0.0;
}

- (void) updateTrackingAreas
{
    for(NSTrackingArea* trackingArea in self.trackingAreas)
    {
        [self removeTrackingArea:trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp | NSTrackingAssumeInside);
    NSTrackingArea* trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                                 options:opts
                                                                   owner:self
                                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    [super updateTrackingAreas];
}

- (BOOL) wantsLayer
{
    return YES;
}

- (BOOL) wantsUpdateLayer
{
    return YES;
}


- (void) updateLayer
{
    [super updateLayer];
    
    self.layer.bounds = self.bounds;
    self.playerLayer.frame = self.layer.bounds;
    
    //    CALayer *layer = self.layer;
    //    layer.borderColor = self.borderColor.CGColor;
    //    layer.borderWidth = BORDER_WIDTH;//(self.borderColor ? BORDER_WIDTH : 0.0);
    //    layer.cornerRadius = CORNER_RADIUS;
    //    layer.backgroundColor = (self.borderColor ? [NSColor colorWithWhite:0.05 alpha:1].CGColor : [NSColor colorWithWhite:0.15 alpha:1].CGColor);
    [self updateTrackingAreas];
    
}

@end
