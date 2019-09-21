//
//  NSMenuAdditions.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/20/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSMenuAdditions.h"




@implementation NSMenu (NSMenuAdditions)

- (NSMenuItem *) _recursiveItemWithRepresentedObject:(id)n	{
	//NSLog(@"%s ... %@, self is %@",__func__,n,[self title]);
	if (n == nil)
		return nil;
	
	NSArray				*items = [self itemArray];
	for (NSMenuItem *item in items)	{
		//	check to see if the represented objects are identical
		id					ro = [item representedObject];
		if (ro == n)	{
			return item;
		}
		//	check to see if the represented objects are equal
		if ([self respondsToSelector:@selector(isEqual:)] && [ro respondsToSelector:@selector(isEqual:)])	{
			if ([(NSObject *)self isEqual:(NSObject *)ro])
				return item;
		}
		
		NSMenu				*submenu = [item submenu];
		if (submenu != nil)	{
			NSMenuItem			*returnMe = [submenu _recursiveItemWithRepresentedObject:n];
			if (returnMe != nil)	{
				//NSLog(@"\t\tfound the item we're looking for! %@",returnMe);
				return returnMe;
			}
		}
	}
	
	return nil;
	
}
- (NSMenuItem *) itemWithRepresentedObject:(id)n	{
	return [self _recursiveItemWithRepresentedObject:n];
}

@end




