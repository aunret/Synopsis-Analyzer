//
//  PresetSettings.h
//  Synopsis Analyzer
//
//  Created by testAdmin on 9/19/19.
//  Copyright © 2019 yourcompany. All rights reserved.
//

#import <Foundation/Foundation.h>



// We had / use unique types for NSOutlineView so we could determine the type of a preset
// this could probably go away	or be simplified into an NSDictionary category that
// returns a dictionary with a type key prepopulated...
// whatever man
// at some point this needs to be removed or made serializable

@interface PresetSettings : NSObject;
@property (copy) NSDictionary* settingsDictionary;
+ (instancetype) settingsWithDict:(NSDictionary*)dictionary;
+ (instancetype) none;
@end




@interface PresetAudioSettings : PresetSettings
@end




@interface PresetVideoSettings : PresetSettings
@end






@interface PresetAnalysisSettings : PresetSettings
@end


