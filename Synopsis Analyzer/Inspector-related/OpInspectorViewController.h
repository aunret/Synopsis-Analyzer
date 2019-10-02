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




@interface OpInspectorViewController : NSViewController	{
	IBOutlet NSClipView				*clipView;
	IBOutlet NSStackView			*stackView;
	
	IBOutlet NSTextField			*fileField;
	IBOutlet NSTextField			*videoField;
	IBOutlet NSTextField			*audioField;
}

- (void) inspectOp:(nullable SynOp *)n;

//	should be nil unless inspector is currently active
@property (readwrite,atomic,weak,nullable) SynOp * inspectedObject;

- (void) updateUI;

@end




NS_ASSUME_NONNULL_END
