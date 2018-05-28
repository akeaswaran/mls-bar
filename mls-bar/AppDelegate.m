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

@import CCNNavigationController;

@interface AppDelegate ()
{
    EventMonitor *eventMonitor;
}
@property (strong) NSStatusItem *statusItem;
@property (strong) NSPopover *popover;
@end

@implementation AppDelegate

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
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"goalNotifsEnabled"];
    }
    
    [self.goalNotifButton setState:([[NSUserDefaults standardUserDefaults] boolForKey:@"goalNotifsEnabled"]) ? NSControlStateValueOn : NSControlStateValueOff];
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
    [[NSUserDefaults standardUserDefaults] setBool:(self.goalNotifButton.state == NSControlStateValueOn) forKey:@"goalNotifsEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggledGoalNotifs" object:nil];
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
//    let defaults = UserDefaults.standard
//    if let _ = defaults.string(forKey: "isAppAlreadyLaunchedOnce"){
//        print("App already launched")
//        return true
//    }else{
//        defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
//        print("App launched first time")
//        return false
//    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isAppAlreadyLaunchedOnce"]) {
        return true;
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"isAppAlreadyLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return false;
    }
}

-(void)openLink:(NSString *)link {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
