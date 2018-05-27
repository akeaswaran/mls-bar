//
//  EventMonitor.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Cocoa;

typedef void (^EventMonitorHandler)(NSEvent *event);

@interface EventMonitor : NSObject
@property (nonatomic) id monitor;
@property (nonatomic) NSEventMask mask;
@property (nonatomic) EventMonitorHandler handler;
+ (instancetype)newMonitor:(NSEventMask)maskIn handler:(EventMonitorHandler)handlerIn;
-(void)start;
-(void)stop;
@end
