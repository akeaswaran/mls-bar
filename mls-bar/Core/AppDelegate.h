//
//  AppDelegate.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *goalNotifButton;
@property (weak) IBOutlet NSButton *teamLogoButton;
@property (weak) IBOutlet NSTextView *copyrightLabel;
@property (weak) NSString *updateInterval;
@end

