//
//  SessionInspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "SessionInspectorViewController.h"

#import "SynSession.h"




@interface SessionInspectorViewController ()
@property (readwrite,atomic,weak,nullable) SynSession * inspectedObject;
@end




@implementation SessionInspectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void) inspectSession:(SynSession *)n	{
	self.inspectedObject = n;
	if (self.inspectedObject == nil)	{
		return;
	}
	
}

@end
