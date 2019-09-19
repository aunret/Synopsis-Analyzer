//
//  FilePreviewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/18/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "FilePreviewController.h"




static FilePreviewController		*globalFilePreviewController = nil;




@implementation FilePreviewController

+ (id) global	{
	return globalFilePreviewController;
}
- (id) init	{
	self = [super init];
	if (self != nil)	{
		globalFilePreviewController = self;
	}
	return self;
}

@end
