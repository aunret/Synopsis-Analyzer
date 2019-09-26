//
//  SessionInspectorViewController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynSession;

NS_ASSUME_NONNULL_BEGIN




@interface SessionInspectorViewController : NSViewController

- (void) inspectSession:(SynSession *)n;

@end




NS_ASSUME_NONNULL_END
