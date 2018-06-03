//
//  Competitor.h
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//


#import <Mantle/Mantle.h>
@class Team;

typedef enum : NSUInteger {
    CFBCompetitorTypeTeam,
    CFBCompetitorTypePlayer,
    CFBCompetitorTypeUnknown
} CFBCompetitorType;

@interface Competitor : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign) CFBCompetitorType type;
@property (nonatomic, copy) NSArray *records;
@property (nonatomic, copy) NSNumber *rank;
@property (nonatomic, copy) NSString *competitorId;
@property (nonatomic, assign) BOOL winner;
@property (nonatomic, copy) NSNumber *isHome;
@property (nonatomic, copy) NSString *score;
@property (nonatomic, copy) NSString *form;
@property (nonatomic, copy) Team *team;
@property (nonatomic, copy) NSArray *statistics;
- (NSString *)points;
@end
