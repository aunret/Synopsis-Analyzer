//
//  ProgressButton.m
//  ITProgressIndicator
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 Ilija Tovilo. All rights reserved.
//

#import "ProgressButton.h"
#import "ITProgressIndicator.h"




@interface ProgressButton ()
- (void) generalInit;
- (void) _updateResources;
@property (strong,readwrite) ITProgressIndicator * progressIndicator;
@property (strong,readwrite) CALayer * buttonLayer;
@property (atomic,readwrite) BOOL mouseIsDown;
@end




@implementation ProgressButton

- (id) initWithCoder:(NSCoder *)c	{
	self = [super initWithCoder:c];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (id) initWithFrame:(NSRect)r	{
	self = [super initWithFrame:r];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	NSLog(@"%s",__func__);
	[self setWantsLayer:YES];
	self.layer.delegate = self;
	
	self.progressIndicator = nil;
	
	self.buttonLayer = [[CALayer alloc] init];
	self.buttonLayer.backgroundColor = [[NSColor lightGrayColor] CGColor];
	self.buttonLayer.frame = self.layer.bounds;
	self.buttonLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	self.buttonLayer.mask = [[CALayer alloc] init];
	self.buttonLayer.mask.frame = NSInsetRect(self.buttonLayer.bounds, 12.0, 12.0);
	self.buttonLayer.mask.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	
	[self.layer addSublayer:self.buttonLayer];
	
	self.state = NSControlStateValueOff;
	//self.state = NSControlStateValueOn;
	
	[self _updateResources];
	
	//[self setAutoresizesSubviews:YES];
}


- (void) mouseDown:(NSEvent *)e	{
	@synchronized (self)	{
		self.mouseIsDown = YES;
		self.state = (self.state == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn;
	}
	
	[self.target performSelector:self.action withObject:self];
}
- (void) mouseUp:(NSEvent *)e	{
	self.mouseIsDown = NO;
}

/*
- (void) drawRect:(NSRect)r	{
	NSLog(@"%s",__func__);
	//[super drawRect:r];
	[[NSColor redColor] set];
	NSRectFill(self.bounds);
}
*/


- (void) layoutSublayersOfLayer:(CALayer *)layer	{
	/*
	NSRect			origFrame = layer.bounds;
	NSRect			tmpRect = NSInsetRect(origFrame, 10.0, 10.0);
	
	self.buttonLayer.frame = origFrame;
	//self.buttonLayer.frame = tmpRect;
	*/
	[self _updateResources];
	
}


@synthesize state=myState;
- (void) setState:(NSControlStateValue)n	{
	BOOL		changed = (myState == n) ? NO : YES;
	myState = n;
	if (changed)
		[self _updateResources];
}
- (NSControlStateValue) state	{
	return myState;
}
/*
- (void) setFrameSize:(NSSize)n	{
	[super setFrameSize:n];
	[self _updateResources];
}
- (void) setBoundsSize:(NSSize)n	{
	[super setBoundsSize:n];
	[self _updateResources];
}
- (void) setFrame:(NSRect)n	{
	[super setFrame:n];
	[self _updateResources];
}
*/


- (void) _updateResources	{
	@synchronized (self)	{
		if (self.progressIndicator != nil)	{
			[self.progressIndicator removeFromSuperview];
			self.progressIndicator = nil;
		}
		
		
		if (self.state == NSControlStateValueOn)	{
			//self.buttonLayer.contents = [NSImage imageNamed:@"StopButton"];
			//self.buttonLayer.mask = [[CALayer alloc] init];
			//self.buttonLayer.mask.frame = self.bounds;
			self.buttonLayer.mask.contents = [NSImage imageNamed:@"StopButton"];
			//self.buttonLayer.frame = self.bounds;
			
			self.progressIndicator = [[ITProgressIndicator alloc] initWithFrame:[self bounds]];
			self.progressIndicator.isIndeterminate = YES;
			self.progressIndicator.animates = YES;
			self.progressIndicator.color = [NSColor lightGrayColor];
	
			self.progressIndicator.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
			[self addSubview:self.progressIndicator];
	
			NSRect			tmpRect = self.progressIndicator.frame;
			double			tmpDimension = (tmpRect.size.width < tmpRect.size.height) ? tmpRect.size.width/2.0 : tmpRect.size.height/2.0;
			double			tmpMargin = tmpDimension * 0.5;
			double			tmpLength = tmpDimension * 0.3;
			self.progressIndicator.lengthOfLine = tmpLength;
			self.progressIndicator.innerMargin = tmpMargin;
			self.progressIndicator.widthOfLine = 4.0;
		}
		else	{
			//self.buttonLayer.contents = [NSImage imageNamed:@"PlayButton"];
			//self.buttonLayer.mask = [[CALayer alloc] init];
			//self.buttonLayer.mask.frame = self.bounds;
			self.buttonLayer.mask.contents = [NSImage imageNamed:@"PlayButton"];
			//self.buttonLayer.frame = self.bounds;
		}
	}
}

@end
