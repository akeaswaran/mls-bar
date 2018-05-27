//
//  MatchViewController.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "MatchViewController.h"
#import "ScoresViewController.h"
@import HTMLReader;
@import CCNNavigationController;
@import SDWebImage;

#import "Game.h"
#import "SharedUtils.h"

typedef void (^GeneralLoadHandler)(NSDictionary *json, NSError *error);
typedef void (^ResponseHandler)(NSData *data, NSURLResponse *response, NSError *error);


@interface MatchViewController () {
    NSString *lastEventId;
    BOOL gameInProgress;
    NSTimer *gameTimer;
}
@property (strong) Game *selectedGame;
@end

@implementation MatchViewController

+ (instancetype)freshMatchupView:(Game *)g {
    MatchViewController *vc = [[MatchViewController alloc] initWithNibName:@"MatchViewController" bundle:nil];
    vc.selectedGame = g;
    return vc;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self.awayBackground setWantsLayer:YES];
    [self.homeBackground setWantsLayer:YES];
}


-(IBAction)popToRoot:(id)sender {
    [gameTimer invalidate];
    [self.navigationController popViewControllerAnimated:YES];
    [((ScoresViewController *)self.navigationController.viewControllers[0]).tableView deselectRow:((ScoresViewController *)self.navigationController.viewControllers[0]).tableView.selectedRow];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.statusField setStringValue:self.selectedGame.statusDescription];
    [self setAwayColor:self.selectedGame.awayCompetitor.team.color];
    [self setHomeColor:self.selectedGame.homeCompetitor.team.color];
    
    [self.homeScoreLabel setStringValue:self.selectedGame.homeCompetitor.score];
    [self.awayScoreLabel setStringValue:self.selectedGame.awayCompetitor.score];
    
    NSColor *homeContrastColor = [SharedUtils contrastColorFor:self.selectedGame.homeCompetitor.team.color];
    [self.homeScoreLabel setTextColor:homeContrastColor];
    
    NSColor *awayContrastColor = [SharedUtils contrastColorFor:self.selectedGame.awayCompetitor.team.color];
    [self.awayScoreLabel setTextColor:awayContrastColor];
    
    if (self.selectedGame.homeCompetitor.winner) {
        self.awayScoreLabel.alphaValue = 0.5;
    } else if (self.selectedGame.awayCompetitor.winner) {
        self.homeScoreLabel.alphaValue = 0.5;
    } else {
        self.awayScoreLabel.alphaValue = 1.0;
        self.homeScoreLabel.alphaValue = 1.0;
    }
    
    [self.awayBackground wantsUpdateLayer];
    self.awayBackground.layer.backgroundColor = self.awayColor.CGColor;
    [self.homeBackground wantsUpdateLayer];
    self.homeBackground.layer.backgroundColor = self.homeColor.CGColor;
    
    [self.homeTeamImgView sd_setImageWithURL:self.selectedGame.homeCompetitor.team.logoURL];
    [self.awayTeamImgView sd_setImageWithURL:self.selectedGame.awayCompetitor.team.logoURL];

    
    NSLog(@"GAMESTATE: %lu", self.selectedGame.status);
    if (self.selectedGame.status != GameStateFinal && self.selectedGame.status != GameStateScheduled && self.selectedGame.status != GameStateCancelled) {
        gameInProgress = YES;
        
        [self loadInititalCommentaryEventsForGame:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    NSArray *htmlEvents = json[@"commentary"];
                    NSMutableString *commentaryString = [NSMutableString string];
                    for (NSDictionary *event in htmlEvents) {
                        [commentaryString appendFormat:@"%@: %@\n", event[@"timestamp"],event[@"description"]];
                    }
                    [self.commentaryView setString:commentaryString];
                    [self.commentaryView scrollToEndOfDocument:nil];
                } else {
                    NSLog(@"ERROR: %@", error);
                }
                self->lastEventId = json[@"lastEventId"] != nil ? json[@"lastEventId"] : @"0";
                [self startAutoReload:60.0f];
            });
        }];
    } else {
        gameInProgress = NO;
        [self loadMatchStats:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
            NSLog(@"RESPONSE: %@", json);
        }];
    }
}

-(void)startAutoReload:(float)updateInterval {
    if (gameInProgress) {
        gameTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                         target:self selector:@selector(autoReload:) userInfo:nil repeats:YES];
    } else {
        NSLog(@"not reloading bc game not in progress");
        if (gameTimer) {
            [gameTimer invalidate];
        }
    }
}

-(void)autoReload:(NSTimer *)timer {
    NSLog(@"reloading...");
    [self continuousLoadCommentaryEventsForGame:self.selectedGame.gameId lastEventId:lastEventId completionHandler:^(NSDictionary *json, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"RELOAD DONE");
            if (!error) {
                NSArray *htmlEvents = json[@"commentary"];
                NSMutableString *commentaryString = [NSMutableString stringWithString:self.commentaryView.string];
                for (NSDictionary *event in htmlEvents) {
                    [commentaryString appendFormat:@"%@: %@\n", event[@"timestamp"],event[@"description"]];
                }
                [self.commentaryView setString:commentaryString];
                [self.commentaryView scrollToEndOfDocument:nil];
                self->lastEventId = json[@"lastEventId"] != nil ? json[@"lastEventId"] : @"0";
                self.statusField = json[@"timestamp"];
                
                if (json[@"homeScore"] != nil) {
                    if (self.selectedGame.homeCompetitor.score.intValue > [json[@"homeScore"] intValue]) {
                        self.selectedGame.homeCompetitor.score = json[@"homeScore"];
                        [self.homeScoreLabel setStringValue:json[@"homeScore"]];
                        
                        NSUserNotification *userNote = [[NSUserNotification alloc] init];
                        userNote.identifier = [NSString stringWithFormat:@"home-score-%@", self.selectedGame.gameId];
                        userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.homeCompetitor.team.abbreviation];
                        userNote.subtitle = [json[@"commentary"] lastObject][@"description"]; // assuming the most recent update is the score...
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                    }
                }
                
                if (json[@"awayScore"] != nil) {
                    if (self.selectedGame.awayCompetitor.score.intValue > [json[@"awayScore"] intValue]) {
                        self.selectedGame.awayCompetitor.score = json[@"awayScore"];
                        [self.awayScoreLabel setStringValue:json[@"awayScore"]];
                        
                        NSUserNotification *userNote = [[NSUserNotification alloc] init];
                        userNote.identifier = [NSString stringWithFormat:@"away-score-%@", self.selectedGame.gameId];
                        userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.awayCompetitor.team.abbreviation];
                        userNote.subtitle = [json[@"commentary"] lastObject][@"description"]; // assuming the most recent update is the score...
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                    }
                }
                if ([json[@"timestamp"] isEqualToString:@"FT"]) {
                    self->gameInProgress = NO;
                    [self->gameTimer invalidate];
                }
            } else {
                NSLog(@"Error: %@", error);
            }
            
        });
    }];
    
}

-(void)loadInititalCommentaryEventsForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    [self _loadESPNCommentaryForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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

-(void)continuousLoadCommentaryEventsForGame:(NSString *)gameId lastEventId:(NSString *)lastId completionHandler:(GeneralLoadHandler)callback {
    [self _loadESPNCommentaryForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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

-(void)loadMatchStats:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback {
    [self _loadESPNMatchupForGame:gameId completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            callback(@{@"matchup" :  @{
                               @"form" : @{},
                               @"team-statistics" : @[],
                               @"head-to-head" : @[]
                               }
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
                       @"matchup" :  @{
                               @"form" : forms,
                               @"team-statistics" : stats,
                               @"head-to-head" : h2hGames
                               }
                       }, nil);
        }
    }];
}

-(void)_loadESPNCommentaryForGame:(NSString*)gameId completionHandler:(ResponseHandler)callback {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/commentary?gameId=%@", gameId]]; // sample gameId: 502629
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
          callback(data, response, error);
      }] resume];
}

-(void)_loadESPNMatchupForGame:(NSString *)gameId completionHandler:(ResponseHandler)callback {
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/matchstats?gameId=%@", gameId]]; // sample gameId: 502620
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:URL completionHandler:
      ^(NSData *data, NSURLResponse *response, NSError *error) {
          callback(data, response, error);
      }] resume];
}

@end
