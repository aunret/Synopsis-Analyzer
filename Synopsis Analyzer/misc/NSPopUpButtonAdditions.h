//
//  NSPopUpButtonAdditions.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/20/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <AppKit/AppKit.h>




@interface NSPopUpButton (NSPopUpButtonAdditions)

- (NSMenuItem *) selectItemWithRepresentedObject:(id)n;
- (NSMenuItem *) selectItemWithRepresentedObject:(id)n andOutput:(BOOL)o;

- (void) sanityHack_menuItemChosen:(NSMenuItem *)n;

@end


