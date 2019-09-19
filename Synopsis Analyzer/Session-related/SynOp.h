//
//  SynOp.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/16/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>




typedef NS_ENUM(NSUInteger, OpStatus)	{
	OpStatus_Pending = 0,	//	hasn't been started yet
	OpStatus_Analyze,	//	analyzing
	OpStatus_Cleanup,	//	cleaning up (copying/moving files)
	OpStatus_Complete,	//	everything finished successfully
	OpStatus_Err	//	err encountered somewhere
};




@interface SynOp : NSObject

@property (atomic,readwrite) NSURL * src;
@property (atomic,readwrite) NSURL * dst;

@property (atomic,readwrite) OpStatus status;

@end


