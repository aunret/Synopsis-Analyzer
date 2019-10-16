//
//  GPULoadBalancer.m
//  Synopsis Analyzer
//
//  Created by vade on 10/15/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "GPULoadBalancer.h"
#import <Metal/Metal.h>

#import "SynopsisJobObject.h"

@interface GPULoadBalancer ()
{
    // Token received from Metal to control notifications
    id <NSObject> _deviceObserver;
}
@property (atomic, readwrite, strong) dispatch_queue_t deviceQueue;
@property (atomic, readwrite, strong, nullable)NSMutableArray<id<MTLDevice>>* viableDevices;
@property (atomic, readwrite, assign) BOOL allowLowPowerDevices;
@property (atomic, readwrite, assign) BOOL allowBuiltInDevices;
@property (atomic, readwrite, assign) BOOL allowDetacableDevices;
@property (atomic, readwrite, strong, nonnull) NSMutableDictionary<NSNumber*, NSMutableSet<SynopsisJobObject*>*>* gpuJobDict;

@end

@implementation GPULoadBalancer

+ (GPULoadBalancer*) sharedBalancer
{
    static GPULoadBalancer* sharedBalancer = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBalancer = [[GPULoadBalancer alloc] init];
    });
    
    return sharedBalancer;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.deviceQueue = dispatch_queue_create("info.synopsis.gpuloadbalancer.devicequeue", DISPATCH_QUEUE_SERIAL);
        
        self.allowLowPowerDevices = NO;
        self.allowDetacableDevices = YES;
        self.allowBuiltInDevices = YES;

        self.gpuJobDict = [NSMutableDictionary new];
        
        __weak GPULoadBalancer* weakSelf = self;
        
        MTLDeviceNotificationHandler handler = ^(id <MTLDevice> device, MTLDeviceNotificationName name) {
            dispatch_sync(weakSelf.deviceQueue, ^{
                
                if ([name isEqualToString:MTLDeviceRemovalRequestedNotification]
                    || [name isEqualToString:MTLDeviceWasRemovedNotification])
                {
                    [weakSelf handleRemovalOfDevice:device];
                }
                else if ([name isEqualToString:MTLDeviceWasAddedNotification])
                {
                    if ([weakSelf devicePassesCurrentRequirements:device])
                    {
                        [weakSelf.viableDevices addObject:device];
                        NSLog(@"Found viable device named: %@", device.name);
                    }
                }
            });
        };

        id <NSObject> deviceObserver = nil;
        NSArray<id <MTLDevice>> *devices = MTLCopyAllDevicesWithObserver(&deviceObserver, handler);
        _deviceObserver = deviceObserver;
        
        // Set the initial preferred device.
        [self rebuildViableDeviceListFromDevices:devices];
        
        return self;
    }
    
    return nil;
}

- (void)dealloc
{
  MTLRemoveDeviceObserver(_deviceObserver);
}

- (nullable id<MTLDevice> ) nextAvailableDevice
{
    __block id<MTLDevice> nextDevice = nil;

    dispatch_sync(self.deviceQueue, ^{
        // iterate every viable device and get its jobs
        NSUInteger leastJobCount = NSUIntegerMax;
        
        for( id<MTLDevice> device in self.viableDevices)
        {
            NSSet* jobsForDevice = self.gpuJobDict[ @(device.registryID) ];
            if (jobsForDevice)
            {
                if (jobsForDevice.count < leastJobCount)
                {
                    leastJobCount = jobsForDevice.count;
                    nextDevice = device;
                }
            }
            // No jobs for a device, exit and just assign it!
            else
            {
                nextDevice = device;
                break;
            }
        }
    });
    
    return nextDevice;
}


- (void) checkoutGPU:(id<MTLDevice>)device forJob:(SynopsisJobObject*)sender
{
    dispatch_sync(self.deviceQueue, ^{
        
        id<MTLDevice> nextDevice = device;
        
        // Theres a potential that we ask for the next available device,
        // THEN get a device removal
        // and THEN try to check out a now remove device.
        // We need to ensure our device is within our CURRENT viable device list.
        if ( ![self.viableDevices containsObject:nextDevice])
        {
            nextDevice = [self.viableDevices firstObject];
        }
        
        // select it, increment job count for that device
        NSMutableSet<SynopsisJobObject*>* jobsForDevice = self.gpuJobDict[ @(nextDevice.registryID) ];
        if ( jobsForDevice )
        {
            [jobsForDevice addObject:sender];
        }
        else
        {
            [self.gpuJobDict setObject:[NSMutableSet setWithObject:sender] forKey: @(nextDevice.registryID) ];
        }
        
        // return it
        NSLog(@"Checking out %@", nextDevice.name);
    });
}

- (void) returnGPU:(id<MTLDevice>)device from:(id)sender
{
    dispatch_sync(self.deviceQueue, ^{

        NSMutableSet<SynopsisJobObject*>* jobsForDevice = self.gpuJobDict[ @(device.registryID) ];
        if ( jobsForDevice )
        {
            if([jobsForDevice containsObject:sender])
            {
                [jobsForDevice removeObject:sender];
                NSLog(@"Returning %@", device.name);
            }
            else
            {
                NSLog(@"Warning - trying to return %@ which has no job", device.name);
            }
        }
        else
        {
            NSLog(@"Warning - trying to return untracked GPU %@", device.name);
        }
    });
}


#pragma mark -
#pragma mark Private API

- (void) handleRemovalOfDevice:(id<MTLDevice>)device
{
    NSMutableArray* devicesToRemove = [NSMutableArray new];

    // sometimes we get different pointers to the same underlying MTLDevice
    // use registryID to identify duplicates
    for (id<MTLDevice> existingDevice in self.viableDevices)
    {
        if (device.registryID == existingDevice.registryID)
        {
            NSLog(@"Found match of viable device and device to remove" );
            [devicesToRemove addObject:existingDevice];
        }
    }
    
    [self.viableDevices removeObjectsInArray:devicesToRemove];
    
    NSMutableSet<SynopsisJobObject*>* jobsForDevice = self.gpuJobDict[ @(device.registryID) ];
    
    if (jobsForDevice)
    {
        for (SynopsisJobObject* job in jobsForDevice)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [job cancel];
            });
        }
        
        [self.gpuJobDict removeObjectForKey:@(device.registryID)];
    }
    
    NSLog(@"Removed device: %@", device.name);
    
}

- (void) rebuildViableDeviceListFromDevices:(NSArray<id<MTLDevice>>*)devices
{
    dispatch_async(self.deviceQueue, ^{
        self.viableDevices = [NSMutableArray new];
        
        for (id<MTLDevice> device in devices)
        {
            if([self devicePassesCurrentRequirements:device])
            {
                // Add the device to our viable device list
                NSLog(@"Found viable device named: %@", device.name);
                [self.viableDevices addObject:device];
            }
        }
    });
}

- (BOOL) devicePassesCurrentRequirements:(id<MTLDevice>)device
{
    BOOL deviceIsViable = FALSE;
    
    if (self.allowLowPowerDevices && device.isLowPower)
        deviceIsViable = TRUE;
    
    if (self.allowDetacableDevices && device.isRemovable)
        deviceIsViable = TRUE;
    
    if (self.allowBuiltInDevices && !device.isRemovable)
        deviceIsViable = TRUE;
    
    return deviceIsViable;
}


//- (nullable id<MTLDevice>) deviceForRegistryID:(uint64_t)registryID
//{
//    for (id<MTLDevice> device in MTLCopyAllDevices())
//    {
//        if (registryID == device.registryID)
//            return device;
//    }
//
//    return nil;
//}
//
//- (nullable id <MTLDevice>) roundRobinNextDevice
//{
//    //    prep some synopsis stuff
//    static int roundRobin = 0;
//
//    id<MTLDevice> device = nil;
//    @synchronized ([self class])
//    {
//        device = self.viableDevices[roundRobin];
//        ++roundRobin;
//        roundRobin = roundRobin % self.viableDevices.count;
//    }
//
//    if (@available(macOS 10.15, *))
//    {
//        NSLog(@"using Metal Device %@, is low power: %i, maxTransferRate: %llu", device.name, device.lowPower, device.maxTransferRate);
//
//    }
//    else
//    {
//        NSLog(@"using Metal Device %@, is low power: %i", device.name, device.lowPower);
//    }
//
//    return device;
//}
//
//- (nullable id<MTLDevice> ) nextDevice
//{
//    return [self roundRobinNextDevice];
//}



@end
