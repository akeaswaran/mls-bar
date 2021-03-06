//
//  AppDelegate.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "AppDelegate.h"

#import "ScoresViewController.h"
#import "EventMonitor.h"
#import "SharedUtils.h"

#import <SDImageCache.h>

@import CCNNavigationController;

@interface AppDelegate ()
{
    EventMonitor *eventMonitor;
}
@property (strong) NSStatusItem *statusItem;
@property (strong) NSPopover *popover;
@end

@implementation AppDelegate
@synthesize updateInterval;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"status-bar-logo"];
    self.statusItem.button.action = @selector(togglePopover:);
    self.popover = [NSPopover new];
    self.popover.contentViewController = [[CCNNavigationController alloc] initWithRootViewController:[ScoresViewController freshScoresView]];
    
    eventMonitor = [EventMonitor newMonitor:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:^(NSEvent *event) {
        if (self.popover.isShown) {
            [self closePopover:nil];
        }
    }];
    
    if (![self appLaunchedBefore]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DNV_GOAL_NOTIFS_ALLOWED_KEY];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DNV_TEAM_LOGOS_ALLOWED_KEY];
        [[NSUserDefaults standardUserDefaults] setInteger:60 forKey:DNV_UPDATE_INTERVAL_KEY];
        self.updateInterval = @"60";
    }
    
    [self.goalNotifButton setState:([[NSUserDefaults standardUserDefaults] boolForKey:DNV_GOAL_NOTIFS_ALLOWED_KEY]) ? NSControlStateValueOn : NSControlStateValueOff];
    [self.teamLogoButton setState:([[NSUserDefaults standardUserDefaults] boolForKey:DNV_TEAM_LOGOS_ALLOWED_KEY]) ? NSControlStateValueOn : NSControlStateValueOff];
    self.updateInterval = [NSString stringWithFormat:@"%ld", (long)[SharedUtils retrieveCurrentUpdateInterval]];
    
    NSLog(@"[Preferences State Restoration] Loaded in prefs of goal notifs (%ld), logos shown (%ld), and update interval (%@)", self.goalNotifButton.state, self.teamLogoButton.state, self.updateInterval);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"Y"];
//    if let version: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
//
//    }
    
    [self.copyrightLabel setString:[NSString stringWithFormat:@"Copyright © %@ Akshay Easwaran | version %@ (%@).", [dateFormatter stringFromDate:[NSDate date]], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"],[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]]];
}

-(void)togglePopover:(id)sender {
    if (self.popover.isShown) {
        [self closePopover:nil];
    } else {
        [self showPopover:nil];
    }
}

-(void)showPopover:(id)sender {
    [self.popover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSRectEdgeMinY];
    [eventMonitor start];
}

-(IBAction)toggleGoalNotifs:(id)sender {
    NSLog(@"GOAL NOTIFS TURNED %@", (self.goalNotifButton.state == NSControlStateValueOn) ? @"ON" : @"OFF");
    [[NSUserDefaults standardUserDefaults] setBool:(self.goalNotifButton.state == NSControlStateValueOn) forKey:DNV_GOAL_NOTIFS_ALLOWED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:DNV_GOAL_NOTIFS_ALLOWED_NOTIFICATION_NAME object:nil];
}

-(IBAction)toggleTeamLogosScoreboard:(id)sender {
    NSLog(@"TEAM LOGOS TURNED %@", (self.teamLogoButton.state == NSControlStateValueOn) ? @"ON" : @"OFF");
    [[NSUserDefaults standardUserDefaults] setBool:(self.teamLogoButton.state == NSControlStateValueOn) forKey:DNV_TEAM_LOGOS_ALLOWED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:DNV_TEAM_LOGOS_ALLOWED_KEY object:nil];
}


-(void)closePopover:(id)sender {
    [self.popover performClose:sender];
}

-(IBAction)openESPN:(id)sender {
    [self openLink:@"https://espn.com/"];
}

-(IBAction)openMLS:(id)sender {
    [self openLink:@"https://mlssoccer.com/"];
}

-(IBAction)openGitHub:(id)sender {
    [self openLink:@"https://github.com/akeaswaran/mls-bar"];
}

-(IBAction)openIcons8:(id)sender {
    [self openLink:@"https://icons8.com/"];
}

-(BOOL)appLaunchedBefore {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isAppAlreadyLaunchedOnce"]) {
        return true;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"isAppAlreadyLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return false;
    }
}

-(IBAction)clearCache:(id)sender {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DNV_CACHE_CLEAR_NOTIFICATION object:nil];
    }];
}

-(IBAction)saveUpdateInterval:(id)sender {
    NSString *value = ((NSTextField *)sender).stringValue;
    [[NSUserDefaults standardUserDefaults] setInteger:[value integerValue] forKey:DNV_UPDATE_INTERVAL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:DNV_UPDATE_INTERVAL_NOTIFICATION object:nil];
}

-(void)openLink:(NSString *)link {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
