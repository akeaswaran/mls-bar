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
#import "MatchAPI.h"

@interface MatchViewController () {
    NSString *lastEventId;
    BOOL gameInProgress;
    NSTimer *gameTimer;
    BOOL goalNotifsEnabled;
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
    if ([gameTimer isValid]) {
        [gameTimer invalidate];
        NSLog(@"GAME IN PROGRESS BUT POPPED; TIMER INVALIDATED - NO MORE UPDATES");
    }
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

    [self handleToggledGoalNotifs:nil];
    
    NSLog(@"GAMESTATE: %lu", self.selectedGame.status);
    if (self.selectedGame.status == GameStateScheduled || self.selectedGame.status == GameStateCancelled) {
        gameInProgress = NO;
        [MatchAPI loadMatchStats:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
            NSLog(@"RESPONSE: %@", json);
        }];
    } else if (self.selectedGame.status == GameStateFinal) {
        gameInProgress = NO;
        [MatchAPI loadESPNPostGameSummaryForGame:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
            NSLog(@"RESPONSE: %@", json);
        }];
    } else {
        gameInProgress = YES;
        [MatchAPI loadInititalCommentaryEventsForGame:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
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
    [MatchAPI continuousLoadCommentaryEventsForGame:self.selectedGame.gameId lastEventId:lastEventId completionHandler:^(NSDictionary *json, NSError *error) {
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
                        NSLog(@"HOME GOAL");
                        self.selectedGame.homeCompetitor.score = json[@"homeScore"];
                        [self.homeScoreLabel setStringValue:json[@"homeScore"]];
                        
                        if (self->goalNotifsEnabled) {
                            NSUserNotification *userNote = [[NSUserNotification alloc] init];
                            userNote.identifier = [NSString stringWithFormat:@"home-score-%@", self.selectedGame.gameId];
                            userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.homeCompetitor.team.abbreviation];
                            userNote.subtitle = [json[@"commentary"] lastObject][@"description"]; // assuming the most recent update is the score...
                            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                        }
                    }
                }
                
                if (json[@"awayScore"] != nil) {
                    if (self.selectedGame.awayCompetitor.score.intValue > [json[@"awayScore"] intValue]) {
                        NSLog(@"AWAY GOAL");
                        self.selectedGame.awayCompetitor.score = json[@"awayScore"];
                        [self.awayScoreLabel setStringValue:json[@"awayScore"]];
                        
                        if (self->goalNotifsEnabled) {
                            NSUserNotification *userNote = [[NSUserNotification alloc] init];
                            userNote.identifier = [NSString stringWithFormat:@"away-score-%@", self.selectedGame.gameId];
                            userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.awayCompetitor.team.abbreviation];
                            userNote.subtitle = [json[@"commentary"] lastObject][@"description"]; // assuming the most recent update is the score...
                            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                        }
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

-(void)handleToggledGoalNotifs:(NSNotification *)notif {
    goalNotifsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"goalNotifsEnabled"];
}



@end
