//
//	PresetGroup.h
//	Synopsis
//
//	Created by vade on 12/28/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PresetSettings.h"




@interface PresetGroup : NSObject

@property (copy) NSString* title;
@property (readonly) BOOL editable;

@property (copy) NSArray* children;

- (id) initWithTitle:(NSString*)title editable:(BOOL)editable NS_DESIGNATED_INITIALIZER;
- (instancetype) init NS_UNAVAILABLE;

@end
