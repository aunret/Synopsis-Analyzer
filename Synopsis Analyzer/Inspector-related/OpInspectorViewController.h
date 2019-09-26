//
//  OpInspectorViewController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynOp;

NS_ASSUME_NONNULL_BEGIN




@interface OpInspectorViewController : NSViewController

- (void) inspectOp:(SynOp *)n;

@end




NS_ASSUME_NONNULL_END
