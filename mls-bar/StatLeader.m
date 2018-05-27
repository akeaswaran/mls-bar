//
//  StatLeader.m
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import "StatLeader.h"

@implementation StatLeader

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"teamId" : @"athlete.team.id",
             @"position": @"athlete.position.abbreviation",
             @"displayValue": @"displayValue",
             @"displayName": @"athlete.displayName",
             @"shortName": @"athlete.shortName",
             @"jerseyNumber": @"athlete.jersey",
             };
}
@end
