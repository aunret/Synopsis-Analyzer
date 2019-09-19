//
//	PreferencesViewController.m
//	Synopsis
//
//	Created by vade on 12/25/15.
//	Copyright (c) 2015 metavisual. All rights reserved.
//

#import "PreferencesViewController.h"
#import "Constants.h"
#import "PresetGroup.h"

@interface PreferencesViewController ()

@property (readwrite, nonatomic, strong) PreferencesGeneralViewController* preferencesGeneralViewController;
@property (readwrite, nonatomic, strong) PreferencesFileViewController* preferencesFileViewController;
@property (readwrite, nonatomic, strong) PreferencesPresetViewController* preferencesPresetViewController;
@property (readwrite, nonatomic, strong) PreferencesAdvancedViewController* preferencesAdvancedViewController;


@property (weak) NSViewController* currentViewController;

@end
static NSInteger currentTag = 0;

@implementation PreferencesViewController

- (void)viewDidLoad {
	NSLog(@"%s",__func__);
	[super viewDidLoad];
	
	self.preferencesGeneralViewController = [[PreferencesGeneralViewController alloc] initWithNibName:@"PreferencesGeneralViewController" bundle:[NSBundle mainBundle]];
	self.preferencesFileViewController = [[PreferencesFileViewController alloc] initWithNibName:@"PreferencesFileViewController" bundle:[NSBundle mainBundle]];
	self.preferencesPresetViewController = [[PreferencesPresetViewController alloc] initWithNibName:@"PreferencesPresetViewController" bundle:[NSBundle mainBundle]];
	self.preferencesAdvancedViewController = [[PreferencesAdvancedViewController alloc] initWithNibName:@"PreferencesAdvancedViewController" bundle:[NSBundle mainBundle]];
	
	[self addChildViewController:self.preferencesGeneralViewController];

	[self.view addSubview:self.preferencesGeneralViewController.view];
	[self.preferencesGeneralViewController.view setFrame:self.view.bounds];
	
	self.currentViewController = self.preferencesGeneralViewController;


	[self buildPresetMenu];
	
	//	make sure my child views get loaded
	self.preferencesGeneralViewController.view;
	self.preferencesFileViewController.view;
	self.preferencesPresetViewController.view;
	self.preferencesAdvancedViewController.view;
	
 //	   for(NSObject* object in [self.preferencesPresetViewController allPresets])
//	  {
//		  if([object isKindOfClass:[PresetObject class]])
//		  {
//			  PresetObject* preset = (PresetObject*)object;
//			  NSMenuItem* presetMenuItem = [[NSMenuItem alloc] initWithTitle:preset.title action:@selector(setDefaultPresetAction:) keyEquivalent:@""];
//			  
//			  presetMenuItem.representedObject = preset;
//			  presetMenuItem.target = self.preferencesGeneralViewController;
//			  
//			  [self.preferencesGeneralViewController.defaultPresetPopupButton.menu addItem:presetMenuItem];
//		  }
//		  
//	  }
	
	// set our default for now - since we arent loading for NSUserDefaults
//	  [[self.preferencesGeneralViewController.defaultPresetPopupButton menu] performActionForItemAtIndex:0];
}

- (void) buildPresetMenu
{
	// populate our general prefs default preset button with all available presets
	[self.preferencesGeneralViewController.defaultPresetPopupButton.menu removeAllItems];

	// Fix for #76
	[self.preferencesGeneralViewController.defaultPresetPopupButton.menu addItemWithTitle:@"Placeholder" action:NULL keyEquivalent:@""];
	
	NSMenuItem* defaultPresetMenuItem = nil;
	
	[self recursiveBuildMenu:self.preferencesGeneralViewController.defaultPresetPopupButton.menu
				  forObjects:[self.preferencesPresetViewController allPresets]
			selectedMenuItem: &defaultPresetMenuItem];
	
	
	[self.preferencesGeneralViewController setDefaultPresetAction:defaultPresetMenuItem];

}

- (void) recursiveBuildMenu:(NSMenu*)menu forObjects:(NSArray*)arrayOfPresetOrGroup selectedMenuItem:(NSMenuItem **)selectedMenuItem
{
	NSString* defaultPresetUUIDString = [[NSUserDefaults standardUserDefaults] objectForKey:kSynopsisAnalyzerDefaultPresetPreferencesKey];
	NSUUID* defaultPresetUUID = [[NSUUID alloc] initWithUUIDString:defaultPresetUUIDString];
	
	for(NSObject* object in arrayOfPresetOrGroup)
	{
		if([object isKindOfClass:[PresetObject class]])
		{
			PresetObject* preset = (PresetObject*)object;
			
			NSMenuItem* presetMenuItem = [[NSMenuItem alloc] initWithTitle:preset.title action:@selector(setDefaultPresetAction:) keyEquivalent:@""];
			
			presetMenuItem.representedObject = preset;
			presetMenuItem.target = self.preferencesGeneralViewController;
			
			[menu addItem:presetMenuItem];
			
			if([preset.uuid isEqual:defaultPresetUUID])
				*selectedMenuItem = presetMenuItem;
			
		}
		
		if ([object isKindOfClass:[PresetGroup class]])
		{
			PresetGroup* group = (PresetGroup*)object;
			
			NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:group.title action:NULL keyEquivalent:@""];
			
			NSMenu* subMenu = [[NSMenu alloc] initWithTitle:group.title];
			[menuItem setSubmenu:subMenu];
			
			[menu addItem:menuItem];
	 
			// recurse
			[self recursiveBuildMenu:subMenu forObjects:group.children selectedMenuItem:selectedMenuItem];
		}
	}
	
}

#pragma mark -

- (PresetObject*) defaultPreset
{
	return self.preferencesGeneralViewController.defaultPreset;
}

- (NSArray*) availablePresets
{
	return self.preferencesPresetViewController.allPresets;
}

#pragma mark -

- (IBAction)transitionToGeneral:(id)sender
{
	[self transitionToViewController:self.preferencesGeneralViewController tag:[sender tag]];
}

- (IBAction)transitionToFile:(id)sender
{
	[self transitionToViewController:self.preferencesFileViewController tag:[sender tag]];
}

- (IBAction)transitionToPreset:(id)sender
{
	[self transitionToViewController:self.preferencesPresetViewController tag:[sender tag]];
}

- (IBAction)transitionToAdvanced:(id)sender
{
	[self transitionToViewController:self.preferencesAdvancedViewController tag:[sender tag]];
}

- (void) transitionToViewController:(NSViewController*)viewController tag:(NSInteger)tag
{
	NSViewControllerTransitionOptions option = NSViewControllerTransitionSlideRight;
	if( tag > currentTag)
		option = NSViewControllerTransitionSlideLeft;

	currentTag = tag;
	
	// early bail if equality
	if(self.currentViewController == viewController)
		return;
	
	[self addChildViewController:viewController];
	
	// update frame to match source / dest
	[viewController.view setFrame:self.currentViewController.view.bounds];

	[self transitionFromViewController:self.currentViewController
					  toViewController:viewController
							   options:option
					 completionHandler:^{

						 [self.currentViewController removeFromParentViewController];
						 
						 self.currentViewController = viewController;
					 }];
}

@end
