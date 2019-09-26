//
//  InspectorViewController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OpInspectorViewController.h"
#import "SessionInspectorViewController.h"
#import "EmptyInspectorViewController.h"

@class SynSession;
@class SynOp;

NS_ASSUME_NONNULL_BEGIN




@interface InspectorViewController : NSViewController

+ (instancetype) global;

- (void) inspectSession:(SynSession *)n;
- (void) inspectOp:(SynOp *)n;
- (void) inspectItem:(id)n;
- (void) uninspectAll;

@property (readonly,nonatomic,strong) OpInspectorViewController * opInspectorViewController;
@property (readonly,nonatomic,strong) SessionInspectorViewController *sessionInspectorViewController;
@property (readonly,nonatomic,strong) EmptyInspectorViewController *emptyInspectorViewController;



@end




NS_ASSUME_NONNULL_END
