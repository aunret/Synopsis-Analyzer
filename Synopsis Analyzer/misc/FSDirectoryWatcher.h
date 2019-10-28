//
//  FSDirectoryWatcher.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/30/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN




/*	
	watches a given directory for changes made (by other apps) to its contents
	- also fires if changes are made to any subdirectories
	- only fires changes on completion of file xfers (this was the real PITA)
*/


typedef void(^FSDirectoryWatcherCallbackBlock)(NSArray<NSString*>*);


@interface FSDirectoryWatcher : NSObject
//	callback block is executed on the main thread!
- (instancetype) initWithDirectoryAtURL:(NSURL *)inDirURL notificationBlock:(FSDirectoryWatcherCallbackBlock)inCallbackBlock;
- (instancetype) initWithDirectory:(NSString *)inDirPath notificationBlock:(FSDirectoryWatcherCallbackBlock)inCallbackBlock;
@end




NS_ASSUME_NONNULL_END
