//
//  PrefsController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/17/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreferencesViewController;




@interface PrefsController : NSWindowController	{
	IBOutlet PreferencesViewController		*prefsViewController;
}

+ (PrefsController *) global;

@end


