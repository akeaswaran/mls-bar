//
//  Team.m
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import "Team.h"

#import "HexColors.h"

@implementation Team

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"teamId" : @"id",
             @"location": @"location",
             @"name": @"name",
             @"displayName": @"displayName",
             @"shortDisplayName": @"shortDisplayName",
             @"color": @"color",
             @"alternateColor": @"alternateColor",
             @"logoURL" : @"logo",
             @"abbreviation" : @"abbreviation"
             };
}

+ (NSValueTransformer *)locationJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString* value, BOOL *success, NSError *__autoreleasing *error) {
        if (*error || !success || !value) {
            if (error) {
                NSLog(@"Error: %@ value: %@ success: %@", *error, value, success ? @"true" : @"false");
            } else if (!success) {
                NSLog(@"not successful unwrapping");
            } else {
                NSLog(@"no value");
            }
            return @"Unknown";
        } else {
            if ([value isEqualToString:@"Atlanta United FC"]) {
                return @"Atlanta";
            } else if ([value isEqualToString:@"FC Cincinnati"]) {
                return @"Cincinnati";
            } else if ([value isEqualToString:@"Columbus Crew SC"]) {
                return @"Columbus";
            } else if ([value isEqualToString:@"Colorado Rapids"]) {
                return @"Colorado";
            } else if ([value isEqualToString:@"Chicago Fire"]) {
                return @"Chicago";
            } else if ([value isEqualToString:@"Houston Dynamo"]) {
                return @"Houston";
            } else if ([value isEqualToString:@"Minnesota United FC"]) {
                return @"Minnesota";
            } else if ([value isEqualToString:@"New England Revolution"]) {
                return @"New England";
            } else if ([value isEqualToString:@"Montreal Impact"]) {
                return @"Montreal";
            } else if ([value isEqualToString:@"New York City FC"]) {
                return @"New York City";
            } else if ([value containsString:@"New York Red Bulls"]) {
                return [value stringByReplacingOccurrencesOfString:@"New York Red Bulls" withString:@"NYRB"];
            } else if ([value containsString:@"Philadelphia Union"]) {
                return [value stringByReplacingOccurrencesOfString:@"Philadelphia Union" withString:@"Philadelphia"];
            } else if ([value isEqualToString:@"Orlando City SC"]) {
                return @"Orlando";
            } else if ([value isEqualToString:@"Portland Timbers"]) {
                return @"Portland";
            } else if ([value isEqualToString:@"San Jose Earthquakes"]) {
                return @"San Jose";
            } else if ([value containsString:@"Sporting Kansas City"]) {
                return [value stringByReplacingOccurrencesOfString:@"Sporting Kansas City" withString:@"Sporting KC"];
            } else if ([value isEqualToString:@"Seattle Sounders FC"]) {
                return @"Seattle";
            } else if ([value isEqualToString:@"Vancouver Whitecaps"]) {
                return @"Vancouver";
            } else if ([value isEqualToString:@"Inter Miami CF"]) {
                return @"Miami";
            } else if ([value isEqualToString:@"Nashville SC"]) {
                return @"Nashville";
            } else if ([value containsString:@"Charlotte"]) {
                return @"Charlotte";
            } else if ([value isEqualToString:@"Austin FC"]) {
                return @"Austin";
            } else if ([value containsString:@"Sacramento"]) {
                return @"Sacramento";
            } else if ([value containsString:@"St. Louis"]) {
                return @"St. Louis";
            } else if ([value containsString:@"North Carolina Courage"]) {
                return @"NC Courage";
            } else if ([value containsString:@"El Paso"]) {
                return @"El Paso";
            } else if ([value containsString:@"Oklahoma City"]) {
                return [value stringByReplacingOccurrencesOfString:@"Oklahoma City" withString:@"OKC"];
            } else if ([value containsString:@"Las Vegas"]) {
                return @"Las Vegas";
            } else if ([value containsString:@"Rio Grande"]) {
                return @"RGVFC";
            } else if ([value containsString:@"Birmingham"]) {
                return @"Birmingham";
            } else if ([value containsString:@"Colorado Springs"]) {
                return @"Colorado Springs";
            } else if ([value containsString:@"Pittsburgh"]) {
                return @"Pittsburgh";
            } else {
                return value;
            }
        }
    }];
}

+ (NSValueTransformer *)abbreviationJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString* value, BOOL *success, NSError *__autoreleasing *error) {
        if (*error || !success || !value) {
            if (error) {
                NSLog(@"Error: %@ value: %@ success: %@", *error, value, success ? @"true" : @"false");
            } else if (!success) {
                NSLog(@"not successful unwrapping");
            } else {
                NSLog(@"no value");
            }
            return @"???";
        } else {
            if ([value isEqualToString:@"NWY"]) {
                return @"NYRB";
            }
            return value;
        }
    }];
}

+ (NSValueTransformer *)logoURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)colorJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *colorString, BOOL *success, NSError *__autoreleasing *error) {
        return [NSColor hx_colorWithHexRGBAString:colorString];
    }];
}

+ (NSValueTransformer *)alternateColorJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *colorString, BOOL *success, NSError *__autoreleasing *error) {
        return [NSColor hx_colorWithHexRGBAString:colorString];
    }];
}

@end
