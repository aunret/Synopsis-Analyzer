//
//  SessionStateButton.h
//  ITProgressIndicator
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 Ilija Tovilo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN




typedef NS_ENUM(NSUInteger, SSBState)	{
	SSBState_Inactive,	//	no spinner + play button
	SSBState_Active,	//	spinning + stop button
	SSBState_Spinning,	//	just the spinner (for watch folders)
	SSBState_CompletedSuccessfully,
	SSBState_CompletedError
};




@interface SessionStateButton : NSControl <CALayerDelegate>
@property (atomic,readwrite) SSBState state;
@end

NS_ASSUME_NONNULL_END
