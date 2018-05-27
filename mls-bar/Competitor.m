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


@end

