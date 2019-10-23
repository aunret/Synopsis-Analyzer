//
//  ProgressButton.h
//  ITProgressIndicator
//
//  Created by testAdmin on 10/22/19.
//  Copyright © 2019 Ilija Tovilo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProgressButton : NSControl <CALayerDelegate>
@property (atomic,readwrite) NSControlStateValue state;
@end

NS_ASSUME_NONNULL_END
