//
//  SharedUtils.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Cocoa;

#define TEST_DATA_MODE false // set to true or false to enable/disable a sample json feed when clicking on any score cell
#define DNV_GOAL_NOTIFS_ALLOWED_KEY @"goalNotifsEnabled"
#define DNV_GOAL_NOTIFS_ALLOWED_NOTIFICATION_NAME @"toggledGoalNotifs"
#define DNV_TEAM_LOGOS_ALLOWED_KEY @"teamLogosEnabled"
#define DNV_TEAM_LOGOS_ALLOWED_NOTIFICATION_NAME @"teamLogosEnabled"
#define DNV_SCORE_UPDATE_NOTIFICATION @"scoresUpdated"

@interface SharedUtils : NSObject
+ (NSColor *)contrastColorFor:(NSColor *)givenColor;
+ (NSColor *)pickColorBasedOnContrastWithBackground:(NSColor *)backgroundColor color1:(NSColor *)color1 color2:(NSColor *)color2;
+ (NSComparisonResult)compareEvents:(id)obj1 obj2:(id)obj2;
@end
