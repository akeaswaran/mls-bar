//
//  Game.m
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import "Game.h"

@implementation Game


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"status": @"status.type.name",
             @"date": @"date",
             @"competitors": @"competitors",
             @"statusDescription": @"status",
             @"eventHeadlines" : @"headlines",
             @"startDate" : @"startDate",
             @"attendance" : @"attendance",
             @"gameId" : @"id"
             };
}

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"America/New_York"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
    return dateFormatter;
}

+ (NSValueTransformer *)dateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [self.dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)startDateJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *dateString, BOOL *success, NSError *__autoreleasing *error) {
        return [self.dateFormatter dateFromString:dateString];
    }];
}


+ (NSValueTransformer *)competitorsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:Competitor.class];
}

+ (NSValueTransformer *)statusJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString* value, BOOL *success, NSError *__autoreleasing *error) {
        if (*error || !success || !value) {
            return @(GameStateFinal);
        } else {
            if ([value isEqualToString:@"STATUS_SCHEDULED"]) {
                return @(GameStateScheduled);
            } else if ([value isEqualToString:@"STATUS_IN_PROGRESS"]) {
                return @(GameStateInProgress);
            } else if ([value isEqualToString:@"STATUS_CANCELLED"]) {
                return @(GameStateCancelled);
            } else if ([value isEqualToString:@"STATUS_FIRST_HALF"]) {
                return @(GameStateFirstHalf);
            } else if ([value isEqualToString:@"STATUS_SECOND_HALF"]) {
                return @(GameStateSecondHalf);
            } else if ([value isEqualToString:@"STATUS_EXTRA_TIME"]) {
                return @(GameStateExtraTime);
            } else if ([value isEqualToString:@"STATUS_HALF_TIME"]) {
                return @(GameStateHalfTime);
            } else if ([value isEqualToString:@"STATUS_PENALTIES"]) {
                return @(GameStatePKs);
            }  else {
                return @(GameStateFinal);
            }
        }
    }];
}

+ (NSValueTransformer *)statusDescriptionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *statusDict, BOOL *success, NSError *__autoreleasing *error) {
        NSString *clock = statusDict[@"displayClock"];
        NSString *type = statusDict[@"type"][@"name"];
        NSString *period = statusDict[@"type"][@"shortDetail"];
        if ([type isEqualToString:@"STATUS_FULL_TIME"] || [type isEqualToString:@"STATUS_SCHEDULED"]) {
            return period;
        } else {
            return clock;
        }
    }];
}

-(Competitor*)homeCompetitor {
    return [_competitors firstObject];
}

-(Competitor*)awayCompetitor {
    return [_competitors objectAtIndex:1];
}
@end
