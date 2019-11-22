//
//  OpInspectorViewController.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SynOp;
@class PlayerView;

NS_ASSUME_NONNULL_BEGIN




@interface OpInspectorViewController : NSViewController	{
	IBOutlet NSClipView				*clipView;
	
	IBOutlet NSBox				*previewBox;
	IBOutlet NSBox				*fileBox;
	IBOutlet NSBox				*videoBox;
	IBOutlet NSBox				*audioBox;
	//IBOutlet NSView				*spacerView;
	
	IBOutlet NSView				*containerView;
	
	IBOutlet PlayerView				*previewView;
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
