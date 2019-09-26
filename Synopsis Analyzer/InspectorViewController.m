//
//  InspectorViewController.m
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/25/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import "InspectorViewController.h"
#import "SynSession.h"
#import "SynOp.h"




@interface InspectorViewController ()
- (void) generalInit;
- (void) transitionToViewController:(NSViewController *)inVC;
//@property (readwrite,atomic,weak,nullable) id inspectedObject;
@property (readwrite,nonatomic,strong) OpInspectorViewController * opInspectorViewController;
@property (readwrite,nonatomic,strong) SessionInspectorViewController *sessionInspectorViewController;
@property (readwrite,nonatomic,strong) EmptyInspectorViewController *emptyInspectorViewController;
@property (weak) NSViewController * currentViewController;
@end




static InspectorViewController		*globalInspectorViewController = nil;




@implementation InspectorViewController


+ (instancetype) global	{
	return globalInspectorViewController;
}


- (id) init	{
	NSLog(@"%s",__func__);
	self = [super init];
	if (self != nil)	{
		globalInspectorViewController = self;
		//self.inspectedObject = nil;
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.opInspectorViewController = [[OpInspectorViewController alloc] initWithNibName:@"OpInspectorViewController" bundle:[NSBundle mainBundle]];
    self.sessionInspectorViewController = [[SessionInspectorViewController alloc] initWithNibName:@"SessionInspectorViewController" bundle:[NSBundle mainBundle]];
    self.emptyInspectorViewController = [[EmptyInspectorViewController alloc] initWithNibName:@"EmptyInspectorViewController" bundle:[NSBundle mainBundle]];
    
    [self addChildViewController:self.emptyInspectorViewController];
    
    [self.view addSubview:self.emptyInspectorViewController.view];
    [self.emptyInspectorViewController.view setFrame:self.view.bounds];
    
    self.currentViewController = self.emptyInspectorViewController;
    
    //	make sure my child views get loaded
    NSViewController			*tmpVC = nil;
    tmpVC = self.opInspectorViewController;
    tmpVC = self.sessionInspectorViewController;
    tmpVC = self.emptyInspectorViewController;
}

- (void) transitionToViewController:(NSViewController *)inVC	{
	NSViewControllerTransitionOptions		opt = NSViewControllerTransitionSlideRight;
	
	if (self.currentViewController == inVC)
		return;
	
	[self addChildViewController:inVC];
	
	[inVC.view setFrame:self.currentViewController.view.bounds];
	
	[self
		transitionFromViewController:self.currentViewController
		toViewController:inVC
		options:opt
		completionHandler:^{
			[self.currentViewController removeFromParentViewController];
			self.currentViewController = inVC;
		}];
}


- (void) inspectSession:(SynSession *)n	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self inspectSession:n];
		});
		return;
	}
	
	@synchronized (self)	{
		//self.inspectedObject = n;
		[self.opInspectorViewController inspectOp:nil];
		
		[self.sessionInspectorViewController inspectSession:n];
		[self transitionToViewController:self.sessionInspectorViewController];
	}
}
- (void) inspectOp:(SynOp *)n	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self inspectOp:n];
		});
		return;
	}
	
	@synchronized (self)	{
		//self.inspectedObject = n;
		[self.sessionInspectorViewController inspectSession:nil];
		
		[self.opInspectorViewController inspectOp:n];
		[self transitionToViewController:self.opInspectorViewController];
	}
}
- (void) inspectItem:(id)n	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self inspectItem:n];
		});
		return;
	}
	
	@synchronized (self)	{
		if (n == nil)	{
			[self uninspectAll];
		}
		else	{
			if ([n isKindOfClass:[SynSession class]])	{
				[self inspectSession:n];
			}
			else if ([n isKindOfClass:[SynOp class]])	{
				[self inspectOp:n];
			}
			else	{
				[self uninspectAll];
			}
		}
	}
}
- (void) uninspectAll	{
	if (![NSThread isMainThread])	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self uninspectAll];
		});
		return;
	}
	
	@synchronized (self)	{
		//self.inspectedObject = nil;
		[self.opInspectorViewController inspectOp:nil];
		[self.sessionInspectorViewController inspectSession:nil];
		
		[self transitionToViewController:self.emptyInspectorViewController];
	}
}


@end
