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
@import DateTools;
#import <Mantle/Mantle.h>
#import "Game.h"
#import "SharedUtils.h"

@implementation MatchAPI

+ (NSDictionary<NSNumber *, NSString *> *)leagueMappings {
    static dispatch_once_t onceToken;
    static NSDictionary *leagues;
    dispatch_once(&onceToken, ^{
        leagues = @{
            @(MatchLeagueCCL) : @"CONCACAF.CHAMPIONS",
            @(MatchLeagueMLS) : @"usa.1",
            @(MatchLeagueUSL) : @"usa.usl.1",
            @(MatchLeagueNWSL) : @"usa.nwsl",
            @(MatchLeagueUSOC) : @"usa.open"
        };
    });
    return leagues;
}

+ (void)loadGames:(NSString *)dateString completion:(GeneralLoadHandler)callback {
    [self loadGames:dateString forLeague:MatchLeagueMLS completion:callback];
}

+ (void)loadGames:(NSString *)dateString forLeague:(MatchLeague)league completion:(GeneralLoadHandler)callback {
    NSLog(@"datestring : %@", dateString);
    NSString *cacheBuster = [[NSDate date] formattedDateWithFormat:@"YYYYMMDD"];
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://site.api.espn.com/apis/site/v2/sports/soccer/%@/scoreboard?dates=%@&%@",[self leagueMappings][@(league)],dateString,cacheBuster]];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
          if (error) {
              callback(@{@"games" : @[]}, error);
          } else {
              NSError *jsonError;
              id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
              if (jsonError) {
                  callback(@{@"games" : @[]}, jsonError);
              } else {
                  if ([json isKindOfClass:[NSDictionary class]]) {
                      NSMutableArray *games = [NSMutableArray array];
                      NSDictionary *data = (NSDictionary*)json;
                      NSArray *events = data[@"events"];
                      
                      for (NSDictionary *gameEvent in events) {
                          NSArray *competitions = gameEvent[@"competitions"];
                          NSError *gameError;
                          [games addObjectsFromArray:[MTLJSONAdapter modelsOfClass:Game.class fromJSONArray:competitions error:&gameError]];
                          
                          NSLog(@"GAME ERROR: %@", gameError);
                      }
                      callback(@{@"games" : games}, nil);
                  } else {
                      NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : @"JSON was not returned as a dictionary."};
                      NSError *underlyingError = [[NSError alloc] initWithDomain:@"me.akeaswaran.mls-bar" code:500 userInfo:errorDictionary];
                      
                      callback(@{@"games" : @[]}, underlyingError);
                  }
              }
          }
      }] resume];
}

+ (void)loadInititalCommentaryEventsForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    if (TEST_DATA_MODE == true || gameId == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"test-mls-feed" ofType:@"json"];
        if (path) {
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if (json != nil) {
                NSMutableArray *htmlEvents = [NSMutableArray arrayWithArray:(NSArray *)json];
                [htmlEvents sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    return [SharedUtils compareEvents:obj1 obj2:obj2];
                }];
                
                NSString *lastId = (htmlEvents.count > 0) ? [htmlEvents lastObject][@"id"] : @"0";
                callback(@{@"commentary" : htmlEvents, @"lastEventId": lastId}, nil);
            } else {
                callback(@{@"commentary" : @[], @"lastEventId": @"0"}, nil);
            }
        }
    } else {
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
                    return [SharedUtils compareEvents:obj1 obj2:obj2];
                }];
    
                NSString *lastId = (htmlEvents.count > 0) ? [htmlEvents lastObject][@"id"] : @"0";
                callback(@{@"commentary" : htmlEvents, @"lastEventId": lastId}, nil);
            }
        }];
    }
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
                return [SharedUtils compareEvents:obj1 obj2:obj2];
            }];
            
            NSPredicate *bPredicate = [NSPredicate predicateWithFormat:@"SELF.id.intValue > %i", lastId.intValue];
            [htmlEvents filterUsingPredicate:bPredicate];
            
            NSString *lastId = (htmlEvents.count > 0) ? [htmlEvents lastObject][@"id"] : @"0";
            
            HTMLElement *homeScoreNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.away > div > div.score-container > span"]; // home team listed first in soccer
            HTMLElement *awayScoreNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.team.home > div > div.score-container > span"]; // away team listed second in soccer
            HTMLElement *timeNode = [home firstNodeMatchingSelector:@"#gamepackage-matchup-wrap--soccer > div.competitors.sm-score > div.game-status > span.game-time"];
            
            callback(@{@"commentary" : htmlEvents, @"lastEventId": lastId, @"homeScore" : [homeScoreNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"awayScore" : [awayScoreNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"timestamp" : [timeNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]}, nil);
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
                @"homeTeam" : (homeFormNode != nil) ? [homeFormNode.textContent stringByReplacingOccurrencesOfString:@"Form: " withString:@""] : @"",
                                    @"awayTeam" : (awayFormNode != nil) ? [awayFormNode.textContent stringByReplacingOccurrencesOfString:@"Form: " withString:@""] : @""
                                    };
            
            NSArray<HTMLElement *> *h2h = [home nodesMatchingSelector:@"#gamepackage-team-form-away > .head-to-head > .content > table > tbody > tr"];
            NSMutableArray *h2hGames = [NSMutableArray array];
            if (h2h.count > 0) {
                for (HTMLElement *node in h2h) {
                    NSMutableDictionary *game = [NSMutableDictionary dictionary];
                    NSArray<HTMLElement *> *teams = [node nodesMatchingSelector:@"td > a > abbr"];
                    game[@"homeTeam"] = teams[0].textContent;
                    game[@"awayTeam"] = teams[1].textContent;
                    NSString *score = [[node firstNodeMatchingSelector:@"td:nth-child(3) > a"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSError *regexError;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)-(\\d+)" options:NSRegularExpressionCaseInsensitive error:&regexError];
                    if (regexError) {
                        game[@"homeScore"] = score;
                        game[@"awayScore"] = score;
                    } else {
                        NSTextCheckingResult *match = [regex firstMatchInString:score options:0 range:NSMakeRange(0, score.length)];
                        NSString *homeScore = [score substringWithRange:[match rangeAtIndex:1]];
                        NSString *awayScore = [score substringWithRange:[match rangeAtIndex:2]];
                        game[@"homeScore"] = homeScore;
                        game[@"awayScore"] = awayScore;
                    }
                    game[@"date"] = [[node firstNodeMatchingSelector:@"td > span > .game-date"].textContent stringByReplacingOccurrencesOfString:@"," withString:@""];
                    [h2hGames addObject:game];
                }
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
        NSMutableArray *events = [NSMutableArray array];
        for (HTMLElement *node in homeKeyNodes) {
            NSString *type = node.attributes[@"data-event-type"];
            
            NSArray<HTMLElement *> *playerNodes = [node nodesMatchingSelector:@"li"];
            
            for (HTMLElement *playerNode in playerNodes) {
                NSMutableString *playerString = [NSMutableString string];
                NSArray<NSString *> *playerList = [[playerNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n\t\t            \t"];
                [playerString appendString:playerList[0]];

                if ([playerNode.textContent containsString:@"PEN"]) {
                    [playerString appendString:@" (PK)"];
                }
                
                
                if ([playerNode.textContent containsString:@"OG"]) {
                    [playerString appendString:@" (OG)"];
                }
                
                [events addObject:@{
                                    @"player" : playerString,
                                    @"team" : @"home",
                                    @"type" : type,
                                    @"timestamp" : [[[[[[playerNode firstNodeMatchingSelector:@"span"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@" PEN" withString:@""] stringByReplacingOccurrencesOfString:@" OG" withString:@""]
                                    }];
            }
        }
        
        NSArray<HTMLElement *> *awayKeyNodes = [home nodesMatchingSelector:@"#custom-nav > div.game-details.footer.soccer.post > div > div > div.team.home > div > ul"];
        for (HTMLElement *node in awayKeyNodes) {
            NSString *type = node.attributes[@"data-event-type"];
            
            NSArray<HTMLElement *> *playerNodes = [node nodesMatchingSelector:@"li"];
            for (HTMLElement *playerNode in playerNodes) {
                NSMutableString *playerString = [NSMutableString string];
                NSArray<NSString *> *playerList = [[playerNode.textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n\t\t            \t"];
                [playerString appendString:playerList[0]];
                
                if ([playerNode.textContent containsString:@"PEN"]) {
                    [playerString appendString:@" (PK)"];
                }
                
                if ([playerNode.textContent containsString:@"OG"]) {
                    [playerString appendString:@" (OG)"];
                }
                
                [events addObject:@{
                                    @"player" : playerString,
                                    @"team" : @"away",
                                    @"type" : type,
                                    @"timestamp" : [[[[[[playerNode firstNodeMatchingSelector:@"span"].textContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@" PEN" withString:@""] stringByReplacingOccurrencesOfString:@" OG" withString:@""]
                                    }];
            }
        }
        
        NSDictionary *result = @{
                                 @"keyEvents" : events,
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
