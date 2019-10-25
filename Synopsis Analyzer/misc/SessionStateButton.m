//
//  SessionStateButton.m
//  ITProgressIndicator
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 Ilija Tovilo. All rights reserved.
//

#import "SessionStateButton.h"
#import "ITProgressIndicator.h"




@interface SessionStateButton ()
- (void) generalInit;
- (void) _updateResources;
@property (strong,readwrite) ITProgressIndicator * progressIndicator;
@property (strong,readwrite) CALayer * buttonLayer;
@property (atomic,readwrite) BOOL mouseIsDown;
@property (atomic,readwrite) NSRect lastBounds;
@end




@implementation SessionStateButton

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

const CGFloat insetFactor = 0.75;

- (void) generalInit	{
	//NSLog(@"%s",__func__);
	[self setWantsLayer:YES];
	self.layer.delegate = self;
	self.lastBounds = NSZeroRect;
	
	self.progressIndicator = nil;
	
	self.buttonLayer = [[CALayer alloc] init];
	//self.buttonLayer.backgroundColor = [[NSColor lightGrayColor] CGColor];
	self.buttonLayer.frame = self.layer.bounds;
	self.buttonLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	self.buttonLayer.mask = [[CALayer alloc] init];
	double			insetAmount = self.buttonLayer.bounds.size.width * insetFactor;
	self.buttonLayer.mask.frame = NSInsetRect(self.buttonLayer.bounds, insetAmount, insetAmount);
	self.buttonLayer.mask.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	
	[self.layer addSublayer:self.buttonLayer];
	
	self.state = SSBState_Inactive;
	//self.state = SSBState_Active;
	
	[self _updateResources];
	
	//[self setAutoresizesSubviews:YES];
}


- (void) mouseDown:(NSEvent *)e	{
	@synchronized (self)	{
		self.mouseIsDown = YES;
		
		switch (self.state)	{
		case SSBState_Inactive:
			self.state = SSBState_Active;
			break;
		case SSBState_Active:
			self.state = SSBState_Inactive;
			break;
		case SSBState_Spinning:
		case SSBState_CompletedSuccessfully:
		case SSBState_CompletedError:
			return;
		}
	}
	
	[self.target performSelector:self.action withObject:self];
}
- (void) mouseUp:(NSEvent *)e	{
	self.mouseIsDown = NO;
}

/*
- (void) drawRect:(NSRect)r	{
	//NSLog(@"%s",__func__);
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
	if (!NSEqualRects(self.lastBounds, self.bounds))
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
- (void) setFrameSize:(NSSize)n	{
	[super setFrameSize:n];
	if (!NSEqualRects(self.lastBounds, self.bounds))
		[self _updateResources];
}
- (void) setBoundsSize:(NSSize)n	{
	[super setBoundsSize:n];
	if (!NSEqualRects(self.lastBounds, self.bounds))
		[self _updateResources];
}
/*
- (void) setFrame:(NSRect)n	{
	[super setFrame:n];
	[self _updateResources];
}
*/
- (void) updateConstraints	{
	//NSLog(@"%s",__func__);
	[super updateConstraints];
	if (!NSEqualRects(self.lastBounds, self.bounds))
		[self _updateResources];
}
- (void) drawRect:(NSRect)r	{
	if (self.progressIndicator == nil || !NSEqualRects(self.lastBounds, self.bounds))
		[self _updateResources];
}


- (void) _updateResources	{
	@synchronized (self)	{
		if (self.progressIndicator != nil)	{
			[self.progressIndicator removeFromSuperview];
			self.progressIndicator = nil;
		}
		
		//	update the button layer dims
		double			insetAmount = self.buttonLayer.bounds.size.width * insetFactor;
		self.buttonLayer.mask.frame = NSInsetRect(self.buttonLayer.bounds, insetAmount, insetAmount);
		
		//	configure the spinner
		switch (self.state)	{
		case SSBState_Inactive:
		case SSBState_CompletedSuccessfully:
		case SSBState_CompletedError:
			//	don't leave the progress indicator nil, but don't add it to the hierarchy
			//self.progressIndicator = [[ITProgressIndicator alloc] initWithFrame:NSMakeRect(0,0,4,4)];
			self.progressIndicator = nil;
			break;
		case SSBState_Active:
		case SSBState_Spinning:
			{
				NSRect		tmpRect = [self bounds];
				if (tmpRect.size.width<1 || tmpRect.size.height < 1)	{
					//NSLog(@"ERR: bounds %@ in %s",NSStringFromRect(tmpRect),__func__);
					return;
				}
				self.progressIndicator = [[ITProgressIndicator alloc] initWithFrame:[self bounds]];
				self.progressIndicator.isIndeterminate = YES;
				self.progressIndicator.animates = YES;
				self.progressIndicator.color = [NSColor lightGrayColor];
		
				self.progressIndicator.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		
				[self addSubview:self.progressIndicator];
		
				tmpRect = self.progressIndicator.frame;
				double			tmpDimension = (tmpRect.size.width < tmpRect.size.height) ? tmpRect.size.width/2.0 : tmpRect.size.height/2.0;
				double			tmpMargin = tmpDimension * 0.5;
				double			tmpLength = tmpDimension * 0.3;
				self.progressIndicator.lengthOfLine = tmpLength;
				self.progressIndicator.innerMargin = tmpMargin;
				self.progressIndicator.widthOfLine = 4.0;
			}
			break;
		}
		
		//	configure the button layer
		switch (self.state)	{
		case SSBState_Inactive:
			self.buttonLayer.mask.contents = [NSImage imageNamed:@"PlayButton"];
			self.buttonLayer.backgroundColor = [[NSColor lightGrayColor] CGColor];
			self.buttonLayer.mask.hidden = NO;
			break;
		case SSBState_Active:
			self.buttonLayer.mask.contents = [NSImage imageNamed:@"StopButton"];
			self.buttonLayer.backgroundColor = [[NSColor lightGrayColor] CGColor];
			self.buttonLayer.mask.hidden = NO;
			break;
		case SSBState_Spinning:
		case SSBState_CompletedSuccessfully:
			self.buttonLayer.mask.hidden = YES;
			break;
		case SSBState_CompletedError:
			self.buttonLayer.mask.contents = [NSImage imageNamed:@"ic_error_outline"];
			self.buttonLayer.backgroundColor = [[NSColor redColor] CGColor];
			self.buttonLayer.mask.hidden = NO;
			break;
		}
		
		self.lastBounds = self.bounds;
	}
}

@end
