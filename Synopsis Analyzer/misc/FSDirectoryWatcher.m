//
//  FSDirectoryWatcher.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/30/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "FSDirectoryWatcher.h"




//	used to simplify debug logging
static uint32_t myEventFlags[] = {
	kFSEventStreamEventFlagNone,
	kFSEventStreamEventFlagMustScanSubDirs,
	kFSEventStreamEventFlagUserDropped,
	kFSEventStreamEventFlagKernelDropped,
	kFSEventStreamEventFlagEventIdsWrapped,
	kFSEventStreamEventFlagHistoryDone,
	kFSEventStreamEventFlagRootChanged,
	kFSEventStreamEventFlagMount,
	kFSEventStreamEventFlagUnmount,
	kFSEventStreamEventFlagItemCreated,
	kFSEventStreamEventFlagItemRemoved,
	kFSEventStreamEventFlagItemInodeMetaMod,
	kFSEventStreamEventFlagItemRenamed,
	kFSEventStreamEventFlagItemModified,
	kFSEventStreamEventFlagItemFinderInfoMod,
	kFSEventStreamEventFlagItemChangeOwner,
	kFSEventStreamEventFlagItemXattrMod,
	kFSEventStreamEventFlagItemIsFile,
	kFSEventStreamEventFlagItemIsDir,
	kFSEventStreamEventFlagItemIsSymlink,
	kFSEventStreamEventFlagOwnEvent,
	kFSEventStreamEventFlagItemIsHardlink,
	kFSEventStreamEventFlagItemIsLastHardlink,
	kFSEventStreamEventFlagItemCloned
};
//	used to simplify debug logging
static NSString  * myEventNames[] = {
	@"None",
	@"MustScanSubDirs",
	@"UserDropped",
	@"KernelDropped",
	@"EventIdsWrapped",
	@"HistoryDone",
	@"RootChanged",
	@"Mount",
	@"Unmount",
	@"ItemCreated",
	@"ItemRemoved",
	@"ItemInodeMetaMod",
	@"ItemRenamed",
	@"ItemModified",
	@"ItemFinderInfoMod",
	@"ItemChangeOwner",
	@"ItemXattrMod",
	@"ItemIsFile",
	@"ItemIsDir",
	@"ItemIsSymlink",
	@"OwnEvent",
	@"ItemIsHardlink",
	@"ItemIsLastHardlink",
	@"ItemCloned"
};




//	declaration of my callback (definition below)
void myEventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallbackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIDs[]);




@interface FSDirectoryWatcher ()	{
	FSEventStreamRef		eventStream;
}

//@property (atomic,strong,readwrite) NSURL * directoryURL;
@property (atomic,strong,readwrite) NSString * directoryPath;
@property (nonatomic,strong,readwrite) NSMutableDictionary * coalesceDict;	//	key is path, value is NSDate when added
@property (strong,readwrite) dispatch_queue_t fsNotificationQueue;
@property (copy,readwrite) FSDirectoryWatcherCallbackBlock callbackBlock;
- (void) initEventStream;
- (void) pushToCoalesceDict:(NSArray *)inURLsToAdd;	//	associates NSDate with passed URLs, stores in coalesceDict
- (void) popCoalesceDict;	//	pops all items in 'coalesceDict' that are "too old"

@end




@implementation FSDirectoryWatcher


- (instancetype) initWithDirectoryAtURL:(NSURL *)inDirURL notificationBlock:(FSDirectoryWatcherCallbackBlock)inCallbackBlock	{
	//NSLog(@"%s ... %@",__func__,inDirURL);
	self = [super init];
	eventStream = NULL;
	if (inDirURL==nil)
		self = nil;
	if (self != nil)	{
		self.directoryPath = [inDirURL path];
		self.coalesceDict = [[NSMutableDictionary alloc] init];
		self.fsNotificationQueue = dispatch_queue_create("info.synopsis.filewatchqueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		self.callbackBlock = inCallbackBlock;
		[self initEventStream];
	}
	return self;
}
- (instancetype) initWithDirectory:(NSString *)inDirPath notificationBlock:(FSDirectoryWatcherCallbackBlock)inCallbackBlock	{
	//NSLog(@"%s ... %@",__func__,inDirPath);
	self = [super init];
	eventStream = NULL;
	if (inDirPath==nil)
		self = nil;
	if (self != nil)	{
		self.directoryPath = inDirPath;
		self.coalesceDict = [[NSMutableDictionary alloc] init];
		self.fsNotificationQueue = dispatch_queue_create("info.synopsis.filewatchqueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, -1));
		self.callbackBlock = inCallbackBlock;
		[self initEventStream];
	}
	return self;
}
- (void) dealloc	{
	//NSLog(@"%s",__func__);
	if (eventStream != NULL)	{
		FSEventStreamStop(eventStream);
		FSEventStreamInvalidate(eventStream);
		FSEventStreamRelease(eventStream);
		eventStream = NULL;
	}
}
- (void) initEventStream	{
	NSArray					*paths = @[ self.directoryPath ];
	FSEventStreamContext	*context = (FSEventStreamContext *)malloc(sizeof(FSEventStreamContext));
	context->info = (__bridge void *)self;
	context->release = NULL;
	context->retain = NULL;
	context->version = 0;
	context->copyDescription = NULL;
	
	eventStream = FSEventStreamCreate(
		kCFAllocatorDefault,
		myEventStreamCallback,
		context,
		(CFArrayRef)CFBridgingRetain(paths),
		kFSEventStreamEventIdSinceNow,
		1.0,
		kFSEventStreamCreateFlagNone | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
	
	//	could probably be made even more efficient by creating a standalone thread and using its run loop, and also using that thread instead of self.fsNotificationQueue for coalescing/other GCD stuff
	FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	FSEventStreamStart(eventStream);
}
- (void) pushToCoalesceDict:(NSArray *)inPathsToAdd	{
	//NSLog(@"%s",__func__);
	@synchronized (self)	{
		//	the paths are keys, use them to store the current date in the coalesce dict
		NSMutableDictionary		*dict = self.coalesceDict;
		NSDate					*now = [NSDate date];
		if (dict!=nil && now!=nil)	{
			for (NSString *pathToAdd in inPathsToAdd)	{
				[dict setObject:now forKey:pathToAdd];
			}
		}
	}
	
	//	call the pop method after a short delay on the same queue
	__weak FSDirectoryWatcher		*bss = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.05*NSEC_PER_SEC), self.fsNotificationQueue, ^{
		[bss popCoalesceDict];
	});
}
- (void) popCoalesceDict	{
	//NSLog(@"%s",__func__);
	__block NSMutableArray		*changedPaths = nil;
	
	@synchronized (self)	{
		NSDate			*now = [NSDate date];
		//	run through the dict, store any entries that are "too old" in 'changedPaths'
		[self.coalesceDict enumerateKeysAndObjectsUsingBlock:^(NSString * path, NSDate * date, BOOL *stop){
			if ([date timeIntervalSinceDate:now] <= -1.0)	{
				if (changedPaths == nil)
					changedPaths = [NSMutableArray arrayWithCapacity:0];
				[changedPaths addObject:path];
			}
		}]; 
		//	if there are 'changedPaths', run through them and delete the objects stored at these keys from the coalesce dict
		if (changedPaths != nil)	{
			[self.coalesceDict removeObjectsForKeys:changedPaths];
		}
		//	if there are still entries in the coalesce dict, call this method again later
		if ([self.coalesceDict count] > 0)	{
			__weak FSDirectoryWatcher		*bss = self;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.05*NSEC_PER_SEC), self.fsNotificationQueue, ^{
				[bss popCoalesceDict];
			});
		}
	}
	
	//	if paths changed, run my callback block with them
	if (changedPaths != nil)	{
		NSArray		*arrayToSendOut = [changedPaths copy];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.callbackBlock != nil)
				self.callbackBlock(arrayToSendOut);
		});
	}
}


@end




void myEventStreamCallback(
	ConstFSEventStreamRef streamRef, 
	void *clientCallbackInfo, 
	size_t numEvents, 
	void *eventPaths, 
	const FSEventStreamEventFlags eventFlags[], 
	const FSEventStreamEventId eventIDs[])
{
	if (clientCallbackInfo == NULL || numEvents < 1)
		return;
	
	@autoreleasepool	{
		FSDirectoryWatcher		*watcher = (__bridge FSDirectoryWatcher *)(clientCallbackInfo);
		NSArray				*recastEventPaths = (__bridge NSArray *)eventPaths;
		int					i = 0;
		NSMutableArray		*pathsToProcess = nil;
		
		for (NSString *eventPath in recastEventPaths)	{
			FSEventStreamEventFlags		flags = eventFlags[i];
			
			/*
			//	debug logging
			//NSLog(@"\tpath: %@",eventPath);
			for (int j=0; j<24; ++j)	{
				if ((flags & myEventFlags[j]) != 0)	{
					//NSLog(@"\t\tflag: %@",myEventNames[j]);
				}
			}
			*/
			
			//	if it's an "item change owner" event (fired when a copy is complete) or a "rename" event (fired when moved to trash or out of dir)
			if ((flags & kFSEventStreamEventFlagItemChangeOwner)		||
			(flags & kFSEventStreamEventFlagItemRenamed))	{
				//	add the event path to the tmp array for processing...
				if (pathsToProcess == nil)
					pathsToProcess = [NSMutableArray arrayWithCapacity:4];
				[pathsToProcess addObject:eventPath];
			}
			
			++i;
		}
		
		//	if we have event paths to process...
		if (pathsToProcess != nil)	{
			//	push them onto the dict on another queue so we don't wait for any locks during this callback
			dispatch_async(watcher.fsNotificationQueue, ^{
				[watcher pushToCoalesceDict:pathsToProcess];
			});
		}
	}
	
}


