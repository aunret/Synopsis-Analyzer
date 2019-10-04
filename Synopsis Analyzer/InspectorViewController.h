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
//	if this item is inspected, it will be uninspected.  if it's not inspected, nothing will happen (called when item is freed)
- (void) uninspectItem:(id)n;

//	call this if a change was made in the outline view, and we need to propagate the change to the inspector
- (void) reloadInspectorIfInspected:(id)n;
//	call this if a change was made in the inspector, and we need to propagate the change to the outline view
- (void) reloadRowForItem:(id)n;

@property (readonly,nonatomic,strong) OpInspectorViewController * opInspectorViewController;
@property (readonly,nonatomic,strong) SessionInspectorViewController *sessionInspectorViewController;
@property (readonly,nonatomic,strong) EmptyInspectorViewController *emptyInspectorViewController;



@end




NS_ASSUME_NONNULL_END
