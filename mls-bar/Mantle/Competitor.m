//
//  Competitor.m
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import "Competitor.h"
#import "Team.h"

@implementation Competitor

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"type" : @"type",
             @"competitorId": @"id",
             @"isHome": @"homeAway",
             @"winner": @"winner",
             @"score": @"score",
             @"records": @"records",
             @"statistics" : @"statistics",
             @"team" : @"team",
             @"form" : @"form"
    };
}

+ (NSValueTransformer *)teamJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:Team.class];
}

+ (NSValueTransformer *)typeJSONTransformer {
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
                                                                           @"team": @(CFBCompetitorTypeTeam)
                                                                           }];
}

+ (NSValueTransformer *)winnerJSONTransformer {
    return [MTLValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
}

+ (NSValueTransformer *)isHomeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *homeAwayString, BOOL *success, NSError *__autoreleasing *error) {
        if ([homeAwayString isEqualToString:@"home"]) {
            return [NSNumber numberWithBool:true];
        } else {
            return [NSNumber numberWithBool:false];
        }
    }];
}

+ (NSRegularExpression *)recordRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)-(\\d+)-(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return regex;
}

- (NSString *)points {
    NSString *overallRecord = (self.records.count > 0 && [[self.records[0] allKeys] containsObject:@"summary"]) ? self.records[0][@"summary"] : @"0-0-0";
    
    NSTextCheckingResult *match = [[self.class recordRegex] firstMatchInString:overallRecord options:0 range:NSMakeRange(0, overallRecord.length)];
    
    NSString *wins = [overallRecord substringWithRange:[match rangeAtIndex:1]];
    NSString *draws = [overallRecord substringWithRange:[match rangeAtIndex:2]];
    //NSString *losses = [overallRecord substringWithRange:[match rangeAtIndex:3]];
    
    return [NSString stringWithFormat:@"%i", ([wins intValue] * 3 + [draws intValue] * 1)];
}


@end

