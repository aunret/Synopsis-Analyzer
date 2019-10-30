//
//	PreferencesFileViewController.h
//	Synopsis Analyzer
//
//	Created by vade on 10/3/17.
//	Copyright © 2017 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsPathPickerAbstraction.h"




@interface PreferencesFileViewController : NSViewController	{
	IBOutlet PrefsPathPickerAbstraction		*outputFolderAbs;
	//IBOutlet PrefsPathPickerAbstraction		*watchFolderAbs;
	IBOutlet PrefsPathPickerAbstraction		*tempFolderAbs;
}

- (BOOL) outputFolderEnabled;
- (NSString *) outputFolder;
/*
- (BOOL) watchFolderEnabled;
- (NSURL*) watchFolderURL;
*/
- (BOOL) tempFolderEnabled;
- (NSString *) tempFolder;

- (BOOL) usingMirroredFolders;


@end
