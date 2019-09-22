//
//  NSPopUpButtonAdditions.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/20/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "NSPopUpButtonAdditions.h"
#import "NSMenuAdditions.h"




@implementation NSPopUpButton (NSPopUpButtonAdditions)


- (NSMenuItem *) selectItemWithRepresentedObject:(id)n	{
	return [self selectItemWithRepresentedObject:n andOutput:YES];
}
- (NSMenuItem *) selectItemWithRepresentedObject:(id)n andOutput:(BOOL)o	{
	//NSLog(@"%s ... %@- %@",__func__,n,self);
	NSMenuItem		*returnMe = [self.menu itemWithRepresentedObject:n];
	
	//	you can't call 'selectItem' if the item is in a submenu.  great, right?
	//[self selectItem:returnMe];
	
	//	only bother setting the title if we're not outputting (if we're outputting 
	//	@selector(sanityHack_menuItemChosen:) will set the title)
	if (returnMe != nil && !o)	{
		//	only call setTitle: if it's a pull-down (if you do this on a pop-up it adds an item to the top-level menu)
		if (self.pullsDown)	{
			[self setTitle:[returnMe title]];
		}
	}
	
	//	if we're outputting, call the sanity hack.  do this even if there's a nil menu item.
	if (o)	{
		[self sanityHack_menuItemChosen:returnMe];
	}
	
	return returnMe;
}


- (void) sanityHack_menuItemChosen:(NSMenuItem *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	
	
	//	we can't just call "selectItem:", because it doesn't work with submenu items.  at all.  go ahead, try it.
	//[self selectItem:n];
	
	
	//	NSPUBs don't select their menu items when you choose them with the mouse, so we have to do that ourselves...
	if (self.pullsDown)	{
		//	pull-down menu items are relatively simple, we can just set their title.
		[self setTitle:n.title];
	}
	else	{
		//	i don't know WTF to do with pop-up buttons: if you call 'setTitle:' like you would with 
		//	a pull-down button, but that title isn't in the top-level menu, a new menu item is automatically 
		//	created and added to the fucking menu.  really love to know the rationale behind this.
		
		//	seriously, i don't know what to do here.  we just can't use pop-up buttons, i guess?  we
		//	work around this in vdmx by having a custom pop-up button that doesn't inherit (we create 
		//	and open the NSMenu programmatically, like it's a contextual menu, and the UI item is basically 
		//	an NSControl subclass, so it behaves more like an NSButton/NSSlider with respect to target/action)
		
		[self selectItem:n];	//	doesn't actually do diddly-shit.  WTF.
	}
	
	//	..and even though the item appears to be selected with pull-down NSPUBs, it's NOT ACTUALLY SELECTED AT ALL
	//	(look at the actions in AppDelegate- the selectedItem property of the NSPUB is always nil)
	
	//	call my target/action, passing myself
	[self.target performSelector:self.action withObject:n];
}


@end

