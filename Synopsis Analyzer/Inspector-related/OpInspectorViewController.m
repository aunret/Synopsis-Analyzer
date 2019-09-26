//
//  OpInspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "OpInspectorViewController.h"

#import "SynOp.h"




@interface OpInspectorViewController ()
@property (readwrite,atomic,weak,nullable) SynOp * inspectedObject;
@end




@implementation OpInspectorViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void) inspectOp:(SynOp *)n	{
	self.inspectedObject = n;
	if (self.inspectedObject == nil)	{
		return;
	}
	
}


@end
