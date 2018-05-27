//
//  Team.h
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import "Competitor.h"
@import AppKit;

@interface Team : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy, readonly) NSURL *logoURL;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *abbreviation;
@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *shortDisplayName;
@property (nonatomic, copy) NSColor *color;
@property (nonatomic, copy) NSColor *alternateColor;
@end
