//
//	PreferencesFileViewController.h
//	Synopsis Analyzer
//
//	Created by vade on 10/3/17.
//	Copyright © 2017 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsPathAbstraction.h"




@interface PreferencesFileViewController : NSViewController	{
	IBOutlet PrefsPathAbstraction		*outputFolderAbs;
	IBOutlet PrefsPathAbstraction		*watchFolderAbs;
	IBOutlet PrefsPathAbstraction		*tempFolderAbs;
}

//- (BOOL) usingOutputFolder;
- (NSURL*) outputFolderURL;

//- (BOOL) usingWatchFolder;
- (NSURL*) watchFolderURL;

//- (BOOL) usingTempFolder;
- (NSURL*) tempFolderURL;

- (BOOL) usingMirroredFolders;


@end
