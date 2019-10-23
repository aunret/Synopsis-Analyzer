//
//  ProgressButton.h
//  ITProgressIndicator
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 Ilija Tovilo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN




typedef NS_ENUM(NSUInteger, ProgressButtonState)	{
	ProgressButtonState_Inactive,	//	no spinner + play button
	ProgressButtonState_Active,	//	spinning + stop button
	ProgressButtonState_Spinning,	//	just the spinner (for watch folders)
	ProgressButtonState_CompletedSuccessfully,
	ProgressButtonState_CompletedError
};




@interface ProgressButton : NSControl <CALayerDelegate>
@property (atomic,readwrite) ProgressButtonState state;
@end

NS_ASSUME_NONNULL_END
