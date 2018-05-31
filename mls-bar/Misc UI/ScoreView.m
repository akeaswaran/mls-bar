//
//  ScoreView.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "ScoreView.h"

@implementation ScoreView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [_awayColor setFill];
    NSRectFill(_awayBackground.frame);
    
    [_homeColor setFill];
    NSRectFill(_homeBackground.frame);
}

@end
