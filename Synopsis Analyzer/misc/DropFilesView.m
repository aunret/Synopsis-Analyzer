//
//	DropFilesView.m
//	MetadataTranscoderTestHarness
//
//	Created by vade on 5/12/15.
//	Copyright (c) 2015 Synopsis. All rights reserved.
//

#import "DropFilesView.h"
#import <Synopsis/Synopsis.h>

@interface DropFilesView ()
@property (atomic, readwrite, assign) BOOL highLight;

@end

@implementation DropFilesView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
	}
	return self;
}
- (id) initWithCoder:(NSCoder *)c	{
	self = [super initWithCoder:c];
	if (self != nil)	{
		[self registerForDraggedTypes:@[NSFilenamesPboardType]];
	}
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)dealloc
{
	[self unregisterDraggedTypes];
}

- (BOOL) isOpaque
{
	return NO;
}

- (BOOL) allowsVibrancy
{
	return YES;
}

#pragma mark - Drag

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)wantsPeriodicDraggingUpdates
{
	return NO;
}

- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender
{
	if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
	{

		NSArray* types = [SynopsisSupportedFileTypes() arrayByAddingObject:(NSString*)kUTTypeFolder];
		// This thins out irrelevant items in our drag operation
		NSDictionary* searchOptions = @{//NSPasteboardURLReadingFileURLsOnlyKey : @YES,
										NSPasteboardURLReadingContentsConformToTypesKey :types };
	   
//		  NSDictionary* searchOptions = nil;
		__block NSUInteger countOfValidItems = 0;
		[sender
			enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationClearNonenumeratedImages
			forView:self
			classes:@[[NSURL class]]
			searchOptions:searchOptions
			usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
				countOfValidItems++;
			}];


		sender.numberOfValidItemsForDrop = countOfValidItems;
		
		if(countOfValidItems)	{
			self.highLight = YES;
			[self setNeedsDisplay:YES];
		}
		
		return NSDragOperationGeneric;
	}
	else
	{
		//since they aren't offering the type of operation we want, we have
		//to tell them we aren't interested
		return NSDragOperationNone;
	}
}

- (void) draggingExited:(id<NSDraggingInfo>)sender
{
	self.highLight = NO;
	[self setNeedsDisplay:YES];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray* classArray = @[[NSURL class]];
	
	NSArray* types = [SynopsisSupportedFileTypes() arrayByAddingObject:(NSString*)kUTTypeFolder];

	NSDictionary* searchOptions = @{//NSPasteboardURLReadingFileURLsOnlyKey : @YES,
									NSPasteboardURLReadingContentsConformToTypesKey : types };

	NSArray* urls = [[sender draggingPasteboard] readObjectsForClasses:classArray options:searchOptions];

	if(self.dragDelegate && [urls count])
	{
		if([self.dragDelegate respondsToSelector:@selector(analysisSessionForFiles:sessionCompletionBlock:)])
		{
			[self.dragDelegate analysisSessionForFiles:urls sessionCompletionBlock:^{
				//dispatch_async(dispatch_get_main_queue(),^{
				//	NSLog(@"Drag Session Completed");
				//});
			}];
		}
	}

	//re-draw the view with our new data
	self.highLight = NO;
	[self setNeedsDisplay:YES];
}

#pragma mark -


- (void)drawRect:(NSRect)rect {

	[super drawRect:rect];
	
	return;
//	  
////	// Following code courtesey of ImageOptim - thanks!
////	[[NSColor colorWithWhite:0.0 alpha:1.0] setFill];
////	NSRectFill(rect);
//	  
//	  NSColor *drawColor = [NSColor colorWithDeviceWhite:0.5 alpha:(self.highLight ? 1.0 : 0.1)];
//	  [drawColor set];
//	  [drawColor setFill];
//	  
//	  
//	  NSRect bounds = [self bounds];
//	  CGFloat size = MIN(bounds.size.width/2.0, bounds.size.height/1.5);
//	  CGFloat width = MAX(2.0, size/32.0);
//	  NSRect frame = NSMakeRect((bounds.size.width-size)/2.0, (bounds.size.height-size)/2.0, size, size);
//	  
//	  BOOL smoothSizes = YES;
//	  if (!smoothSizes) {
//		  width = round(width);
//		  size = ceil(size);
//		  frame = NSMakeRect(round(frame.origin.x)+((int)width&1)/2.0, round(frame.origin.y)+((int)width&1)/2.0, round(frame.size.width), round(frame.size.height));
//	  }
//	  
//	  [NSBezierPath setDefaultLineWidth:width];
//	  
//	  NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:size/14.0 yRadius:size/14.0];
//	  const CGFloat dash[2] = {size/10.0, size/16.0};
//	  [p setLineDash:dash count:2 phase:2];
//	  [p stroke];
//	  
//	  NSBezierPath *r = [NSBezierPath bezierPath];
//	  CGFloat baseWidth=size/8.0, baseHeight = size/8.0, arrowWidth=baseWidth*2, pointHeight=baseHeight*3.0, offset=-size/8.0;
//	  [r moveToPoint:NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 + baseHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 + baseHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 - baseHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + arrowWidth, bounds.size.height/2.0 - baseHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0, bounds.size.height/2.0 - pointHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0 - arrowWidth, bounds.size.height/2.0 - baseHeight - offset)];
//	  [r lineToPoint:NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 - baseHeight - offset)];
//	  [r fill];
}

@end
