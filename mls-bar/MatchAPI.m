//
//  MatchAPI.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "MatchAPI.h"
@import Cocoa;
@import HTMLReader;
#import "Game.h"
#import "SharedUtils.h"

@implementation MatchAPI

+ (void)loadInititalCommentaryEventsForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    [MatchAPI _loadESPNCommentaryForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            callback(@{@"commentary" : @[], @"lastEventId" : @"0"}, error);
        } else {
            NSString *contentType = nil;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                contentType = headers[@"Content-Type"];
            }
            HTMLDocument *home = [HTMLDocument documentWithData:data
                                              contentTypeHeader:contentType];
            NSArray<HTMLElement *> *nodes = [home nodesMatchingSelector:@"#match-commentary-1-tab-1 table > tbody > tr"];
            NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSMutableArray *htmlEvents = [NSMutableArray array];
            for (HTMLElement *node in nodes) {
                NSMutableDictionary *event = [NSMutableDictionary dictionary];
                event[@"id"] = [node.attributes[@"data-id"] stringByReplacingOccurrencesOfString:@"comment-" withString:@""];
                event[@"type"] = node.attributes[@"data-type"];
                event[@"description"] = [[node firstNodeMatchingSelector:@".game-details"].textContent stringByTrimmingCharactersInSet:whitespace];
                event[@"timestamp"] = [[node firstNodeMatchingSelector:@".time-stamp"].textContent stringByTrimmingCharactersInSet:whitespace];
                [htmlEvents addObject:event];
            }
            [htmlEvents sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSDictionary *objA = (NSDictionary *)obj1;
                NSDictionary *objB = (NSDictionary *)obj2;
                
                return [[NSNumber numberWithInteger:[objA[@"id"] integerValue]] compare:[NSNumber numberWithInteger:[objB[@"id"] integerValue]]];
            }];
            
            NSString *lastId = (htmlEvents.count > 0) ? [htmlEvents lastObject][@"id"] : @"0";
            callback(@{@"commentary" : htmlEvents, @"lastEventId": lastId}, nil);
        }
    }];
}

+ (void)continuousLoadCommentaryEventsForGame:(NSString *)gameId lastEventId:(NSString *)lastId completionHandler:(GeneralLoadHandler)callback {
    [MatchAPI _loadESPNCommentaryForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            callback(@{@"commentary" : @[], @"lastEventId" : @"0"}, error);
        } else {
            NSString *contentType = nil;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                contentType = headers[@"Content-Type"];
            }
            HTMLDocument *home = [HTMLDocument documentWithData:data
                                              contentTypeHeader:contentType];
            NSArray<HTMLElement *> *nodes = [home nodesMatchingSelector:@"#match-commentary-1-tab-1 table > tbody > tr"];
            NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSMutableArray *htmlEvents = [NSMutableArray array];
            
            for (HTMLElement *node in nodes) {
                NSMutableDictionary *event = [NSMutableDictionary dictionary];
                event[@"id"] = [node.attributes[@"data-id"] stringByReplacingOccurrencesOfString:@"comment-" withString:@""];
                event[@"type"] = node.attributes[@"data-type"];
                event[@"description"] = [[node firstNodeMatchingSelector:@".game-details"].textContent stringByTrimmingCharactersInSet:whitespace];
                event[@"timestamp"] = [[node firstNodeMatchingSelector:@".time-stamp"].textContent stringByTrimmingCharactersInSet:whitespace];
                [htmlEvents addObject:event];
            }
            [htmlEvents sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSDictionary *objA = (NSDictionary *)obj1;
                NSDictionary *objB = (NSDictionary *)obj2;
                
                return [[NSNumber numberWithInteger:[objA[@"id"] integerValue]] compare:[NSNumber numberWithInteger:[objB[@"id"] integerValue]]];
            }];
            
            NSPredicate *bPredicate = [NSPredicate predicateWithFormat:@"SELF.id.intValue > %i", lastId.intValue];
            [htmlEvents filterUsingPredicate:bPredicate];
            
            NSString *lastId = (htmlEvents.count > 0) ? [htmlEvents lastObject][@"id"] : @"0";
            
            HTMLElement *homeScoreNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.away > div > div.score-container > .score"]; // home team listed first in soccer
            HTMLElement *awayScoreNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.home > div > div.score-container > .score"]; // away team listed second in soccer
            HTMLElement *timeNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.game-status > span.game-time"];
            
            callback(@{@"commentary" : htmlEvents, @"lastEventId": lastId, @"homeScore" : homeScoreNode.textContent, @"awayScore" : awayScoreNode.textContent, @"timestamp" : timeNode.textContent}, nil);
        }
    }];
}

+ (void)loadMatchStats:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    [MatchAPI _loadESPNMatchupForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            callback(@{
                       @"form" : @{},
                       @"team-statistics" : @[],
                       @"head-to-head" : @[]
                       }, error);
        } else {
            NSString *contentType = nil;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                contentType = headers[@"Content-Type"];
            }
            HTMLDocument *home = [HTMLDocument documentWithData:data
                                              contentTypeHeader:contentType];
            NSArray<HTMLElement *> *compares = [home nodesMatchingSelector:@"#gamepackage-soccer-league-team-stats .soccer-team-stats > .content > .stat-box-container > .stat-box"];
            NSMutableArray *stats = [NSMutableArray array];
            for (HTMLElement *node in compares) {
                NSMutableDictionary *stat = [NSMutableDictionary dictionary];
                stat[@"name"] = [node firstNodeMatchingSelector:@"h3"].textContent;
                stat[@"homeTeam"] = [NSMutableDictionary dictionary];
                NSArray<NSString *> *abbrRankHome = [[node firstNodeMatchingSelector:@".stat-graph > .homeTeam > .chartLabel"].textContent componentsSeparatedByString:@" "];
                stat[@"homeTeam"][@"abbr"] = abbrRankHome[0];
                stat[@"homeTeam"][@"rank"] = [abbrRankHome[1] stringByReplacingOccurrencesOfString:@"Tied" withString:@"T"];
                stat[@"homeTeam"][@"value"] = [node firstNodeMatchingSelector:@".stat-graph > .homeTeam > .chartValue"].textContent;
                
                stat[@"awayTeam"] = [NSMutableDictionary dictionary];
                NSArray<NSString *> *abbrRankAway = [[node firstNodeMatchingSelector:@".stat-graph > .awayTeam > .chartLabel"].textContent componentsSeparatedByString:@" "];
                stat[@"awayTeam"][@"abbr"] = abbrRankAway[0];
                stat[@"awayTeam"][@"rank"] = [abbrRankAway[1] stringByReplacingOccurrencesOfString:@"Tied" withString:@"T"];
                stat[@"awayTeam"][@"value"] = [node firstNodeMatchingSelector:@".stat-graph > .awayTeam > .chartValue"].textContent;
                
                [stats addObject:stat];
            }
            
            HTMLElement *homeFormNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.away > div > div.team-container > div.team-info > .record"]; // home team listed first in soccer
            HTMLElement *awayFormNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.home > div > div.team-container > div.team-info > .record"]; // away team listed second in soccer
            NSDictionary *forms = @{
                                    @"homeTeam" : [homeFormNode.textContent stringByReplacingOccurrencesOfString:@"Form: " withString:@""],
                                    @"awayTeam" : [awayFormNode.textContent stringByReplacingOccurrencesOfString:@"Form: " withString:@""]
                                    };
            
            NSArray<HTMLElement *> *h2h = [home nodesMatchingSelector:@"#gamepackage-team-form-away > .head-to-head > .content > table > tbody > tr"];
            NSMutableArray *h2hGames = [NSMutableArray array];
            for (HTMLElement *node in h2h) {
                NSMutableDictionary *game = [NSMutableDictionary dictionary];
                NSArray<HTMLElement *> *teams = [node nodesMatchingSelector:@"td > a > abbr"];
                game[@"homeTeam"] = teams[0].textContent;
                game[@"awayTeam"] = teams[1].textContent;
                game[@"score"] = [[node firstNodeMatchingSelector:@"td:nth-child(3) > a"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                game[@"date"] = [[node firstNodeMatchingSelector:@"td > span > .game-date"].textContent stringByReplacingOccurrencesOfString:@"," withString:@""];
                [h2hGames addObject:game];
            }
            
            callback(@{
                       @"form" : forms,
                       @"team-statistics" : stats,
                       @"head-to-head" : h2hGames
                       }, nil);
        }
    }];
}


+ (void)loadESPNPostGameSummaryForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    [MatchAPI _loadESPNMatchupForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *contentType = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
            contentType = headers[@"Content-Type"];
        }
        HTMLDocument *home = [HTMLDocument documentWithData:data
                                          contentTypeHeader:contentType];
        NSArray<HTMLElement *> *statList = [home nodesMatchingSelector:@"#gamepackage-soccer-match-stats > div > div > div.stat-list > table > tbody > tr"];
        NSMutableArray *stats = [NSMutableArray array];
        for (HTMLElement *node in statList) {
            NSMutableDictionary *stat = [NSMutableDictionary dictionary];
            stat[@"name"] = [node firstNodeMatchingSelector:@"td:nth-child(2)"].textContent;
            stat[@"homeValue"] = [node firstNodeMatchingSelector:@"td:nth-child(1)"].textContent;
            stat[@"awayValue"] = [node firstNodeMatchingSelector:@"td:nth-child(3)"].textContent;
            [stats addObject:stat];
        }
        
        HTMLElement *homePossessionPctNode = [home firstNodeMatchingSelector:@"#gamepackage-soccer-match-stats > div > div > div.data-vis > div.possession > div.stat-graph.compareLineGraph.twoTeam > span:nth-child(1)"];
        HTMLElement *awayPossessionPctNode = [home firstNodeMatchingSelector:@"#gamepackage-soccer-match-stats > div > div > div.data-vis > div.possession > div.stat-graph.compareLineGraph.twoTeam > span:nth-child(3)"];
        NSDictionary *possession = @{
                                     @"name" : @"Possession",
                                     @"homeValue" : homePossessionPctNode.textContent,
                                     @"awayValue" : awayPossessionPctNode.textContent
                                     };
        [stats addObject:possession];
        
        HTMLElement *shotsNode = [home firstNodeMatchingSelector:@"#gamepackage-soccer-match-stats > div > div > div.data-vis > div.shots"];
        HTMLElement *shotsTitleNode = [shotsNode firstNodeMatchingSelector:@"h4"];
        HTMLElement *homeShotsNode = [shotsNode firstNodeMatchingSelector:@"div > div:nth-child(1) > .data-vis-container > .number"];
        HTMLElement *awayShotsNode = [shotsNode firstNodeMatchingSelector:@"div > div:nth-child(2) > .data-vis-container > .number"];
        NSDictionary *shots = @{
                                @"name" : shotsTitleNode.textContent,
                                @"homeValue" : homeShotsNode.textContent,
                                @"awayValue" : awayShotsNode.textContent
                                };
        [stats addObject:shots];
        
        NSArray<HTMLElement *> *homeKeyNodes = [home nodesMatchingSelector:@"#custom-nav > div.game-details.footer.soccer.post > div > div > div.team.away > div > ul"];
        NSMutableDictionary *homeNotes = [NSMutableDictionary dictionary];
        for (HTMLElement *node in homeKeyNodes) {
            NSString *type = node.attributes[@"data-event-type"];
            
            NSArray<HTMLElement *> *playerNodes = [node nodesMatchingSelector:@"li"];
            NSMutableArray *events = [NSMutableArray array];
            for (HTMLElement *playerNode in playerNodes) {
                NSMutableString *playerString = [NSMutableString string];
                NSArray<NSString *> *playerList = [[playerNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n\t\t            \t"];
                [playerString appendString:playerList[0]];

                if ([playerNode.textContent containsString:@"PEN"]) {
                    [playerString appendString:@" (PK)"];
                }
                
                [events addObject:@{
                                    @"player" : playerString,
                                    @"timestamp" : [[[[[playerNode firstNodeMatchingSelector:@"span"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@" PEN" withString:@""]
                                    }];
            }
            homeNotes[type] = events;
        }
        
        NSArray<HTMLElement *> *awayKeyNodes = [home nodesMatchingSelector:@"#custom-nav > div.game-details.footer.soccer.post > div > div > div.team.home > div > ul"];
        NSMutableDictionary *awayNotes = [NSMutableDictionary dictionary];
        for (HTMLElement *node in awayKeyNodes) {
            NSString *type = node.attributes[@"data-event-type"];
            
            NSArray<HTMLElement *> *playerNodes = [node nodesMatchingSelector:@"li"];
            NSMutableArray *events = [NSMutableArray array];
            for (HTMLElement *playerNode in playerNodes) {
                NSMutableString *playerString = [NSMutableString string];
                NSArray<NSString *> *playerList = [[playerNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n\t\t            \t"];
                [playerString appendString:playerList[0]];
                
                if ([playerNode.textContent containsString:@"PEN"]) {
                    [playerString appendString:@" (PK)"];
                }
                
                [events addObject:@{
                                    @"player" : playerString,
                                    @"timestamp" : [[[[[playerNode firstNodeMatchingSelector:@"span"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@" PEN" withString:@""]
                                    }];
            }
            awayNotes[type] = events;
        }
        
        NSDictionary *keyEvents =  @{
                                     @"homeTeam" : homeNotes,
                                     @"awayTeam" : awayNotes
                                     };
        NSDictionary *result = @{
                                 @"keyEvents" : keyEvents,
                                 @"stats" : stats
                                 };
        callback(result, nil);
    }];
}

+ (void)_loadESPNCommentaryForGame:(NSString*)gameId completionHandler:(ResponseHandler)callback {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/commentary?gameId=%@", gameId]]; // sample gameId: 502629
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
          callback(data, response, error);
      }] resume];
}

+ (void)_loadESPNMatchupForGame:(NSString *)gameId completionHandler:(ResponseHandler)callback {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/matchstats?gameId=%@", gameId]]; // sample gameId: 502620
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
          callback(data, response, error);
      }] resume];
}

@end
