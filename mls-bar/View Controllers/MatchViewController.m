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

@interface MatchEventCellView : NSTableCellView
@property (assign) IBOutlet NSTextField *timestampLabel;
@property (assign) IBOutlet NSTextField *eventLabel;
@end

@implementation MatchEventCellView
@end

@interface MatchViewController () {
    NSString *lastEventId;
    BOOL gameInProgress;
    NSTimer *gameTimer;
    BOOL goalNotifsEnabled;
    NSMutableArray *matchEvents;
}
@property (strong) Game *selectedGame;
@property (assign) IBOutlet NSTextField *noUpdatesLabel;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [((ScoresViewController *)self.navigationController.viewControllers[0]).tableView deselectRow:((ScoresViewController *)self.navigationController.viewControllers[0]).tableView.selectedRow];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.matchSpinner startAnimation:nil];
    self.noUpdatesLabel.alphaValue = 0.0;
    self.matchEventsView.alphaValue = 0.0;
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleToggledGoalNotifs:) name:@"toggledGoalNotifs" object:nil];
    
    NSLog(@"GAMESTATE: %lu", self.selectedGame.status);
    gameInProgress = YES;
    matchEvents = [NSMutableArray array];
    [MatchAPI loadInititalCommentaryEventsForGame:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                self->matchEvents = json[@"commentary"];
                
                [self.matchEventsView reloadData];
                [self.matchEventsView scrollToEndOfDocument:nil];
                if (self->matchEvents.count > 0) {
                    self.noUpdatesLabel.alphaValue = 0;
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = 0.75;
                        self.matchSpinner.animator.alphaValue = 0;
                        self.matchEventsView.animator.alphaValue = 1;
                    } completionHandler:^{
                        self.matchSpinner.alphaValue = 0;
                        self.matchEventsView.alphaValue = 1;
                    }];
                } else {
                    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                        context.duration = 0.75;
                        self.matchSpinner.animator.alphaValue = 0;
                        self.noUpdatesLabel.animator.alphaValue = 1;
                    } completionHandler:^{
                        self.matchSpinner.alphaValue = 0;
                        self.noUpdatesLabel.alphaValue = 1;
                    }];
                }
            } else {
                NSLog(@"ERROR: %@", error);
            }
            self->lastEventId = json[@"lastEventId"] != nil ? json[@"lastEventId"] : @"0";
            [self startAutoReload:60.0f];
        });
    }];
}

-(IBAction)openESPN:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/matchstats?gameId=%@",self.selectedGame.gameId]]];
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
                [self->matchEvents addObjectsFromArray:json[@"commentary"]];
                [self.matchEventsView reloadData];
                [self.matchEventsView scrollToEndOfDocument:nil];
                
                self->lastEventId = json[@"lastEventId"] != nil ? json[@"lastEventId"] : @"0";
                self.statusField.stringValue = json[@"timestamp"];
                
                if (self.selectedGame.homeCompetitor.score.intValue > [json[@"homeScore"] intValue]) {
                    NSLog(@"HOME GOAL");
                    //self.selectedGame.homeCompetitor.score = json[@"homeScore"];
                    [self.homeScoreLabel setStringValue:json[@"homeScore"]];
                    
                    if (self->goalNotifsEnabled) {
                        NSUserNotification *userNote = [[NSUserNotification alloc] init];
                        userNote.identifier = [NSString stringWithFormat:@"home-score-%@", self.selectedGame.gameId];
                        userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.homeCompetitor.team.abbreviation];
                        NSArray *goals = [[self->matchEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.type = goal AND SELF.description CONTAINS %@", self.selectedGame.homeCompetitor.team.name]] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            NSDictionary *objA = (NSDictionary *)obj1;
                            NSDictionary *objB = (NSDictionary *)obj2;
                            
                            return [[NSNumber numberWithInteger:[objA[@"id"] integerValue]] compare:[NSNumber numberWithInteger:[objB[@"id"] integerValue]]];
                        }];
                        userNote.subtitle = [goals lastObject][@"description"]; // assuming the most recent update with type goal is the score...
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                    }
                }
                
                if (self.selectedGame.awayCompetitor.score.intValue > [json[@"awayScore"] intValue]) {
                    NSLog(@"AWAY GOAL");
                    //self.selectedGame.awayCompetitor.score = json[@"awayScore"];
                    [self.awayScoreLabel setStringValue:json[@"awayScore"]];
                    
                    if (self->goalNotifsEnabled) {
                        NSUserNotification *userNote = [[NSUserNotification alloc] init];
                        userNote.identifier = [NSString stringWithFormat:@"away-score-%@", self.selectedGame.gameId];
                        userNote.title = [NSString stringWithFormat:@"⚽ %@ GOAL", self.selectedGame.awayCompetitor.team.abbreviation];
                        NSArray *goals = [[self->matchEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.type = goal AND SELF.description CONTAINS %@", self.selectedGame.awayCompetitor.team.name]] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            NSDictionary *objA = (NSDictionary *)obj1;
                            NSDictionary *objB = (NSDictionary *)obj2;
                            
                            return [[NSNumber numberWithInteger:[objA[@"id"] integerValue]] compare:[NSNumber numberWithInteger:[objB[@"id"] integerValue]]];
                        }];
                        userNote.subtitle = [goals lastObject][@"description"]; // assuming the most recent update with type goal is the score...
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNote];
                    }
                }
                
                if ([json[@"timestamp"] isEqualToString:@"FT"]) {
                    self->gameInProgress = NO;
                    [self->gameTimer invalidate];
                    NSLog(@"NO MORE UPDATES, GAME OVER");
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

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    MatchEventCellView *cellView = [[MatchEventCellView alloc] initWithFrame:NSMakeRect(0, 0, 344, 28)];
    NSDictionary *event = matchEvents[row];
    [cellView.timestampLabel setStringValue:event[@"timestamp"]];
    [cellView.timestampLabel sizeToFit];
    [cellView.eventLabel setStringValue:[[event[@"description"] stringByReplacingOccurrencesOfString:self.selectedGame.homeCompetitor.team.name withString:self.selectedGame.homeCompetitor.team.abbreviation] stringByReplacingOccurrencesOfString:self.selectedGame.awayCompetitor.team.name withString:self.selectedGame.awayCompetitor.team.abbreviation]];
    [cellView.eventLabel sizeToFit];
    return cellView.fittingSize.height > 0 ? cellView.fittingSize.height : 28;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return matchEvents.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MatchEventCellView *cellView = [tableView makeViewWithIdentifier:@"MatchEventCellView" owner:nil];
    NSDictionary *event = matchEvents[row];
    [cellView.timestampLabel setStringValue:event[@"timestamp"]];
    [cellView.eventLabel setStringValue:[[event[@"description"] stringByReplacingOccurrencesOfString:self.selectedGame.homeCompetitor.team.name withString:self.selectedGame.homeCompetitor.team.abbreviation] stringByReplacingOccurrencesOfString:self.selectedGame.awayCompetitor.team.name withString:self.selectedGame.awayCompetitor.team.abbreviation]];
    [cellView.eventLabel sizeToFit];
    return cellView;
}
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}



@end
