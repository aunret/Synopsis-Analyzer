//
//	PreferencesFileViewController.h
//	Synopsis Analyzer
//
//	Created by vade on 10/3/17.
//	Copyright © 2017 metavisual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesFileViewController : NSViewController

- (BOOL) usingOutputFolder;
- (NSURL*) outputFolderURL;

- (BOOL) usingWatchFolder;
- (NSURL*) watchFolderURL;

- (BOOL) usingTempFolder;
- (NSURL*) tempFolderURL;

- (BOOL) usingMirroredFolders;


@end
