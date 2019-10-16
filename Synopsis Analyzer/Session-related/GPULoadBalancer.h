//
//  GPULoadBalancer.h
//  Synopsis Analyzer
//
//  Created by vade on 10/15/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// We ideally need to:
// * Know that a GPU is in use by a job
// * Know that a GPU has finished being used by a job
// * Have a heuristic on how 'heavy' a job is // TODO:
// * have a heuristic on how 'fast' a GPU is // TODO:
// * use both to provide a way to keep a GPU busy but not over commited.

@class SynopsisJobObject;

@interface GPULoadBalancer : NSObject

+ (GPULoadBalancer *) sharedBalancer;

- (nullable id<MTLDevice> ) nextAvailableDevice;
- (void) checkoutGPU:(id<MTLDevice>)device forJob:(SynopsisJobObject*)sender;
- (void) returnGPU:(id<MTLDevice>)device from:(id)sender;

@end

NS_ASSUME_NONNULL_END
