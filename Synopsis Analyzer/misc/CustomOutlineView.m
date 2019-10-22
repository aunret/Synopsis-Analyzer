//
//  CustomOutlineView.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "CustomOutlineView.h"

@implementation CustomOutlineView

- (void) draggingExited:(id<NSDraggingInfo>)info	{
	//NSLog(@"%s",__func__);
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(draggingExited:)])
		[(id)self.delegate draggingExited:info];
	[super draggingExited:info];
}

@end
