//
//  SessionInspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionInspectorViewController.h"

#import "SynSession.h"
#import "PrefsController.h"




@interface SessionInspectorViewController ()
@property (readwrite,atomic,weak,nullable) SynSession * inspectedObject;
@end




@implementation SessionInspectorViewController


- (id) initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle	{
	//NSLog(@"%s",__func__);
	self = [super initWithNibName:inNibName bundle:inBundle];
	if (self != nil)	{
	}
	return self;
}
- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
    [super viewDidLoad];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
	__block SessionInspectorViewController		*bss = self;
	
	[outputFolderPathAbs setSelectButtonBlock:^(PathAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Output Folder";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* outputFolderURL = [openPanel URL];
				[inAbs setPath:[outputFolderURL path]];
				
				//	update the inspected object's output dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setOutputDir:nil];
						else
							[bss.inspectedObject setOutputDir:inAbs.path];
					}
				});
			}
		}];
	}];
	[outputFolderPathAbs setEnableToggleBlock:^(PathAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setOutputDir:nil];
				else
					[bss.inspectedObject setOutputDir:inAbs.path];
			}
		});
	}];
	
	[tempFolderPathAbs setSelectButtonBlock:^(PathAbstraction *inAbs)	{
		NSOpenPanel* openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canCreateDirectories = YES;
		openPanel.canChooseFiles = NO;
		openPanel.message = @"Select Temporary Items Folder";
		
		[openPanel beginSheetModalForWindow:bss.view.window completionHandler:^(NSModalResponse result) {
			if(result == NSModalResponseOK)	{
				//	get the path we configured in the open panel
				NSURL* tempFolderURL = [openPanel URL];
				[inAbs setPath:[tempFolderURL path]];
				
				//	update the inspected object's output dir
				dispatch_async(dispatch_get_main_queue(), ^{
					if (bss.inspectedObject != nil)	{
						if (!inAbs.enabled || inAbs.path==nil)
							[bss.inspectedObject setTempDir:nil];
						else
							[bss.inspectedObject setTempDir:inAbs.path];
					}
				});
			}
		}];
	}];
	[tempFolderPathAbs setEnableToggleBlock:^(PathAbstraction *inAbs)	{
		//	update the inspected object's output dir
		dispatch_async(dispatch_get_main_queue(), ^{
			if (bss.inspectedObject != nil)	{
				if (!inAbs.enabled || inAbs.path==nil)
					[bss.inspectedObject setTempDir:nil];
				else
					[bss.inspectedObject setTempDir:inAbs.path];
			}
		});
	}];
}

- (void) inspectSession:(SynSession *)n	{
	//NSLog(@"%s ... %@",__func__,n);
	self.inspectedObject = n;
	if (self.inspectedObject == nil)	{
		return;
	}
	
	NSString		*tmpString = self.inspectedObject.outputDir;
	if (tmpString == nil)	{
		outputFolderPathAbs.enabled = NSControlStateValueOff;
		outputFolderPathAbs.path = [[[PrefsController global] outputFolderURL] path];
	}
	else	{
		outputFolderPathAbs.enabled = NSControlStateValueOn;
		outputFolderPathAbs.path = tmpString;
	}
	
	tmpString = self.inspectedObject.tempDir;
	if (tmpString == nil)	{
		tempFolderPathAbs.enabled = NSControlStateValueOff;
		tempFolderPathAbs.path = [[[PrefsController global] tempFolderURL] path];
	}
	else	{
		tempFolderPathAbs.enabled = NSControlStateValueOn;
		tempFolderPathAbs.path = tmpString;
	}
}


- (IBAction) presetsPUBUsed:(id)sender	{
}
- (IBAction) copyNonMediaToggleUsed:(id)sender	{
}


@end
