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
@property (weak) IBOutlet NSWindow *window;
@property (strong) NSStatusItem *statusItem;
@property (strong) NSPopover *popover;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.button.image = [NSImage imageNamed:@"mls-logo"];
    self.statusItem.button.action = @selector(togglePopover:);
    self.popover = [NSPopover new];
    self.popover.contentViewController = [[CCNNavigationController alloc] initWithRootViewController:[ScoresViewController freshScoresView]];
    
    eventMonitor = [EventMonitor newMonitor:NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown handler:^(NSEvent *event) {
        if (self.popover.isShown) {
            [self closePopover:nil];
        }
    }];
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

-(void)closePopover:(id)sender {
    [self.popover performClose:sender];
}

-(void)printQuote:(id)sender {
    NSString *quoteText = @"Never put off until tomorrow what you can do the day after tomorrow.";
    NSString *quoteAuthor = @"Mark Twain";
    NSLog(@"%@ - %@", quoteText, quoteAuthor);
}

-(void)constructSettingsMenu {
    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(printQuote:) keyEquivalent:@","]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(printQuote:) keyEquivalent:@"Q"]];
    self.statusItem.menu = menu;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
