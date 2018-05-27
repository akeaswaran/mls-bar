//
//  EventMonitor.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "EventMonitor.h"


@interface EventMonitor ()

@end

@implementation EventMonitor
+ (instancetype)newMonitor:(NSEventMask)maskIn handler:(EventMonitorHandler)handlerIn {
    EventMonitor *mon = [[EventMonitor alloc] init];
    mon.mask = maskIn;
    mon.handler = handlerIn;
    return mon;
}

-(void)dealloc {
    [self stop];
}

-(void)start {
    self.monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
}

-(void)stop {
    if (self.monitor) {
        [NSEvent removeMonitor:self.monitor];
        self.monitor = nil;
    }
}
@end
