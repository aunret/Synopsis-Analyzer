//
//  NSProgressIndicatorAnimated.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/28/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSProgressIndicatorAnimated.h"




@interface NSAnimationBlock : NSAnimation
@property (atomic, strong) void (^progressBlock)(NSAnimation *theAnimation);
@end

@implementation NSAnimationBlock
- (void) setCurrentProgress:(NSAnimationProgress)n	{
	//NSLog(@"%s",__func__);
	[super setCurrentProgress:n];
	if (self.progressBlock != nil)
		self.progressBlock(self);
}
@end




@interface NSProgressIndicatorAnimated ()
@property (strong,readwrite,nullable) NSAnimationBlock * anim;
@property (assign,readwrite) double animStartVal;
@property (assign,readwrite) double animEndVal;
- (void) generalInit;
@end




@implementation NSProgressIndicatorAnimated

- (id) initWithFrame:(NSRect)r	{
	self = [super initWithFrame:r];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (id) initWithCoder:(NSCoder *)c	{
	self = [super initWithCoder:c];
	if (self != nil)	{
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	self.anim = nil;
	self.animStartVal = 0.0;
	self.animEndVal = 0.0;
}
- (void) animateToValue:(double)n	{
	//NSLog(@"%s ... %0.2f",__func__,n);
	//@synchronized (self)	{
		self.animStartVal = self.doubleValue;
		self.animEndVal = n;
	
		if (self.anim != nil)	{
			[self.anim stopAnimation];
			self.anim = nil;
		}
	
		self.anim = [[NSAnimationBlock alloc] initWithDuration:1.0 animationCurve:NSAnimationLinear];
		self.anim.animationBlockingMode = NSAnimationNonblocking;
		
		__weak NSProgressIndicatorAnimated		*bss = self;
		self.anim.progressBlock = ^(NSAnimation *theAnim)	{
			if (bss == nil)
				return;
			float			tmpNormVal = theAnim.currentProgress;
			double			tmpProgressVal = (tmpNormVal * (bss.animEndVal - bss.animStartVal)) + bss.animStartVal;
			//NSLog(@"progress block: %0.2f: [%0.2f - %0.2f] - %0.2f",tmpNormVal,self.animStartVal,self.animEndVal,tmpProgressVal);
			bss.doubleValue = tmpProgressVal;
			if (tmpNormVal == 1.0)
				bss.anim = nil;
		};
	
		[self.anim startAnimation];
	//}
}
- (void) killAnimationSetDoubleValue:(double)n	{
	//@synchronized (self)	{
		if (self.anim != nil)	{
			[self.anim stopAnimation];
			self.anim = nil;
		}
	//}
	self.doubleValue = n;
}

@end
