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
@end




@implementation OpInspectorViewController


- (void) inspectOp:(SynOp *)n	{
	self.inspectedObject = n;
	if (self.inspectedObject == nil)	{
		return;
	}
	
}
- (void) updateUI	{

}


@end
