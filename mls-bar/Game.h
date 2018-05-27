//
//  Game.h
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "Team.h"
#import "Competitor.h"

typedef enum : NSUInteger {
    CFBGameStateScheduled,
    CFBGameStateInProgress,
    CFBGameStateFinal,
    CFBGameStateCancelled
} CFBGameState;

@interface Game : MTLModel <MTLJSONSerializing>
@property (nonatomic, assign) CFBGameState status;
@property (nonatomic, copy) NSString *gameId;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSArray<Competitor*> *competitors;
@property (nonatomic, copy) NSString *statusDescription;
@property (nonatomic, copy) NSNumber *attendance;
@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSArray<NSDictionary *> *eventHeadlines;
-(Competitor*)homeCompetitor;
-(Competitor*)awayCompetitor;
@end
