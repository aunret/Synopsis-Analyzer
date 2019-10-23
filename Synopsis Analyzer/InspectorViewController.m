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
#import "SessionController.h"




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


- (id) initWithNibName:(NSString *)inNibName bundle:(NSBundle *)inBundle	{
	//NSLog(@"%s",__func__);
	self = [super initWithNibName:inNibName bundle:inBundle];
	if (self != nil)	{
		globalInspectorViewController = self;
		[self generalInit];
	}
	return self;
}
- (void) generalInit	{
	//	make the view controllers i own...
	self.opInspectorViewController = [[OpInspectorViewController alloc] initWithNibName:@"OpInspectorViewController" bundle:[NSBundle mainBundle]];
	self.sessionInspectorViewController = [[SessionInspectorViewController alloc] initWithNibName:@"SessionInspectorViewController" bundle:[NSBundle mainBundle]];
	self.emptyInspectorViewController = [[EmptyInspectorViewController alloc] initWithNibName:@"EmptyInspectorViewController" bundle:[NSBundle mainBundle]];
}


- (void)viewDidLoad {
	//NSLog(@"%s",__func__);
    [super viewDidLoad];
    
    [self addChildViewController:self.emptyInspectorViewController];
    
    [self.view addSubview:self.emptyInspectorViewController.view];
    [self.emptyInspectorViewController.view setFrame:self.view.bounds];
    
    self.currentViewController = self.emptyInspectorViewController;
    
 	//	force my view controllers to load/awake from nibs...
    NSViewController			*tmpVC = nil;
    tmpVC = self.opInspectorViewController;
    [tmpVC view];
    tmpVC = self.sessionInspectorViewController;
    [tmpVC view];
    tmpVC = self.emptyInspectorViewController;
    [tmpVC view];
}
- (void) awakeFromNib	{
	//NSLog(@"%s",__func__);
}
- (void) transitionToViewController:(NSViewController *)inVC	{
	NSViewControllerTransitionOptions		opt = NSViewControllerTransitionSlideRight;
	
	NSViewController		*oldVC = self.currentViewController;
	NSViewController		*newVC = inVC;
	if (oldVC == newVC)
		return;
	
	self.currentViewController = newVC;
	
	[self addChildViewController:newVC];
	//[newVC.view setFrame:oldVC.view.bounds];
	
	[self
		transitionFromViewController:oldVC
		toViewController:newVC
		options:opt
		completionHandler:^{
			[oldVC removeFromParentViewController];
			[self.currentViewController.view setFrame:self.view.bounds];
		}];
}


- (void) inspectSession:(SynSession *)n	{
	//NSLog(@"%s ... %@",__func__,n);
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
	//NSLog(@"%s ... %@",__func__,n);
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
	//NSLog(@"%s ... %@",__func__,n);
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
	//NSLog(@"%s",__func__);
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
- (void) uninspectItem:(id)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return;
	if ([n isKindOfClass:[SynSession class]])	{
		SynSession		*recastSession = (SynSession *)n;
		if (self.sessionInspectorViewController.inspectedObject == recastSession || self.sessionInspectorViewController.inspectedObject == nil)	{
			[self uninspectAll];
		}
	}
	else if ([n isKindOfClass:[SynOp class]])	{
		SynOp			*recastOp = (SynOp *)n;
		if (self.opInspectorViewController.inspectedObject == recastOp || self.opInspectorViewController.inspectedObject == nil)	{
			[self uninspectAll];
		}
	}
}
- (void) reloadInspectorIfInspected:(id)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)	{
		[self uninspectAll];
		return;
	}
	
	if ([n isKindOfClass:[SynOp class]])	{
		if (self.opInspectorViewController.inspectedObject == n)
			[self.opInspectorViewController updateUI];
	}
	else if ([n isKindOfClass:[SynSession class]])	{
		if (self.sessionInspectorViewController.inspectedObject == n)
			[self.sessionInspectorViewController updateUI];
	}
	else	{
		[self uninspectAll];
	}
}
- (void) reloadRowForItem:(id)n	{
	//NSLog(@"%s ... %@",__func__,n);
	if (n == nil)
		return;
	[[SessionController global] reloadRowForItem:n];
}


@end
