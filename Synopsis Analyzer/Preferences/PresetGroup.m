//
//	PresetGroup.m
//	Synopsis
//
//	Created by vade on 12/28/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PresetGroup.h"
@interface PresetGroup ()
@property (readwrite) BOOL editable;
@end

@implementation PresetGroup

- (id) initWithTitle:(NSString*)title editable:(BOOL)editable
{
	self = [super init];
	if(self)
	{
		self.title = title;
		self.children = [NSArray new];
		self.editable = editable;
		return self;
	}
	return nil;
}

- (NSString*) description
{
	return self.title;
}

@end
