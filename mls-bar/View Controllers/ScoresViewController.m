//
//  ScoresViewController.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "ScoresViewController.h"
@import CCNNavigationController;
@import DateTools;
#import <Mantle/Mantle.h>
#import "HexColors.h"
@import SDWebImage;

#import "ScoreView.h"
#import "MatchViewController.h"
#import "PregameViewController.h"
#import "PostgameViewController.h"
#import "SharedUtils.h"
#import "AppDelegate.h"
#import "MatchAPI.h"

#import "Game.h"
#import "Team.h"

@interface ScoresViewController () <NSTableViewDelegate, NSTableViewDataSource>
{
    NSDate *currentDate;
    BOOL showTeamLogos;
    NSTimer *scoreTimer;
    NSDate *autoUpdateDate;
    dispatch_group_t scoreDispatchGroup;
}
@property (strong) NSMutableArray *scoreboard;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSTextField *noGamesLabel;
@property (weak) IBOutlet NSButton *currentDateButton;
@property (weak) IBOutlet NSButton *nextDateButton;
@property (weak) IBOutlet NSButton *prevDateButton;
@end

@implementation ScoresViewController

+ (instancetype)freshScoresView {
    ScoresViewController *vc = [[ScoresViewController alloc] initWithNibName:@"ScoresViewController" bundle:nil];
    return vc;
}

-(IBAction)openPrefs:(id)sender {
    NSWindow *window = [((AppDelegate *)[NSApplication sharedApplication].delegate) window]; // Get the window to open
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

-(IBAction)quitApp:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [scoreTimer invalidate];
    [NSApp terminate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleToggledTeamLogos:) name:DNV_TEAM_LOGOS_ALLOWED_KEY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedLocalScores:) name:DNV_SCORE_UPDATE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedLocalScores:) name:DNV_CACHE_CLEAR_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(killAndRestartAutoUpdate:) name:DNV_UPDATE_INTERVAL_NOTIFICATION object:nil];
    
    currentDate = [NSDate date];
    scoreDispatchGroup = dispatch_group_create();
    [self checkAutoReload:currentDate updateEvery:[SharedUtils retrieveCurrentUpdateInterval]];
}

-(void)killAndRestartAutoUpdate:(NSNotification *)notif {
    if (scoreTimer != nil) {
        [scoreTimer invalidate];
        scoreTimer = nil;
    }
    
    [self checkAutoReload:autoUpdateDate updateEvery:[SharedUtils retrieveCurrentUpdateInterval]];
}

-(void)handleUpdatedLocalScores:(NSNotification *)notif {
    [self.tableView reloadData];
}

-(void)handleToggledTeamLogos:(NSNotification *)sender {
    NSLog(@"Checking team logo status");
    showTeamLogos = [[NSUserDefaults standardUserDefaults] boolForKey:DNV_TEAM_LOGOS_ALLOWED_KEY];
    [self.tableView reloadData];
}

-(IBAction)showCurrentDay:(id)sender {
    currentDate = [NSDate date];
    [self loadGamesForDate:currentDate];
}
    
-(IBAction)showNextDay:(id)sender {
    if (scoreTimer != nil && [scoreTimer isValid]) {
        [scoreTimer invalidate];
    }
    [self checkAutoReload:[currentDate dateByAddingDays:1] updateEvery:[SharedUtils retrieveCurrentUpdateInterval]];
}
    
-(IBAction)showPrevDay:(id)sender {
    if (scoreTimer != nil && [scoreTimer isValid]) {
        [scoreTimer invalidate];
    }
    [self checkAutoReload:[currentDate dateBySubtractingDays:1] updateEvery:[SharedUtils retrieveCurrentUpdateInterval]];
}

-(void)checkAutoReload:(NSDate*)date updateEvery:(float)updateInterval {
    if ([date daysFrom:currentDate calendar:[NSCalendar currentCalendar]] == 0) {
        autoUpdateDate = date;
        scoreTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                      target:self selector:@selector(autoReload:) userInfo:nil repeats:YES];
    }
    [self loadGamesForDate:date];
}

-(void)autoReload:(NSTimer *)timer {
    if (scoreTimer != nil) {
        NSLog(@"Reloading scores...");
        [self loadGamesForDate:currentDate];
    }
}

// Concurrency based on dispatch groups based on example:
// https://dispatchswift.com/introduction-to-dispatch-group-a5cf9d61ff4f
-(void)_loadLeague:(MatchLeague)league forDate:(NSString *)dateString {
    NSLog(@"Loading league (%ld)'s scores...", league);
    dispatch_group_enter(scoreDispatchGroup);
    [MatchAPI loadGames:dateString forLeague:league completion:^(NSDictionary *json, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"ERROR on league (%ld): %@", league, error);
            } else {
                [self.scoreboard addObjectsFromArray:json[@"games"]];
            }
            dispatch_group_leave(self->scoreDispatchGroup);
        });
    }];
}

-(void)loadGamesForDate:(NSDate *)date {
    currentDate = date;
    self.scoreboard = [NSMutableArray array];
    self.noGamesLabel.alphaValue = 0.0;
    self.tableView.alphaValue = 0.0;
    [self.spinner startAnimation:nil];
    NSString *dateString = [date formattedDateWithFormat:@"YYYYMMdd"];
    [self.currentDateButton setTitle:[date formattedDateWithFormat:@"MMM d, YYYY"]];
    
    NSArray<NSNumber *> *queryLeagues = @[@(MatchLeagueMLS), @(MatchLeagueCCL),@(MatchLeagueNWSL), @(MatchLeagueUSL), @(MatchLeagueNWSLChallengeCup)];
    for (NSNumber *league in queryLeagues) {
        [self _loadLeague:[league integerValue] forDate:dateString];
    }
    dispatch_group_notify(scoreDispatchGroup, dispatch_get_main_queue(), ^{
        [self handleToggledTeamLogos:nil];
        [self.spinner stopAnimation:nil];
        NSLog(@"COUNT: %lu", self.scoreboard.count);
        if (self.scoreboard.count > 0) {
            self.noGamesLabel.alphaValue = 0.0;
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.75;
                self.spinner.animator.alphaValue = 0;
                self.noGamesLabel.animator.alphaValue = 0.0;
                self.tableView.animator.alphaValue = 1;
            } completionHandler:^{
                self.spinner.animator.alphaValue = 0;
                self.noGamesLabel.animator.alphaValue = 0.0;
                self.tableView.animator.alphaValue = 1;
            }];
        } else {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.75;
                self.spinner.animator.alphaValue = 0;
                self.noGamesLabel.animator.alphaValue = 0.0;
            } completionHandler:^{
                self.spinner.animator.alphaValue = 0;
                self.noGamesLabel.animator.alphaValue = 1;
            }];
        }
    });
}

#pragma mark Table View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.scoreboard.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Game *item = self.scoreboard[row];
    ScoreView *cellView = [tableView makeViewWithIdentifier:@"ScoreView" owner:nil];
    if (cellView == nil) {
        NSRect cellFrame = [tableView bounds];
        cellFrame.size.height = 80;
        cellView = [[ScoreView alloc] initWithFrame:cellFrame];
        [cellView setIdentifier:@"ScoreView"];
    }
    [cellView.homeLabel setStringValue:item.homeCompetitor.team.location];
    [cellView.awayLabel setStringValue:item.awayCompetitor.team.location];
    
    if (showTeamLogos) {
        [cellView.homeTeamBgImageView sd_setImageWithURL:item.homeCompetitor.team.logoURL];
        [cellView.homeTeamBgImageView setAlphaValue:0.1];
        
        [cellView.awayTeamBgImageView sd_setImageWithURL:item.awayCompetitor.team.logoURL];
        [cellView.awayTeamBgImageView setAlphaValue:0.1];
    } else {
        [cellView.homeTeamBgImageView setImage:nil];
        [cellView.awayTeamBgImageView setImage:nil];
    }
    
    [cellView setAwayColor:item.awayCompetitor.team.color];
    [cellView setHomeColor:item.homeCompetitor.team.color];
    [cellView setNeedsDisplay:YES];
    
    if (item.awayCompetitor.records != nil && item.awayCompetitor.records[0][@"summary"] != nil) {
        NSString *awayPtsNoun = @"pts";
        if ([[item.awayCompetitor points] intValue] == 1) {
            awayPtsNoun = @"pt";
        }
        
        [cellView.awayRecordLabel setStringValue:[NSString stringWithFormat:@"%@ %@ (%@)", [item.awayCompetitor points], awayPtsNoun, item.awayCompetitor.records[0][@"summary"]]];
    } else {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentRight;
        [cellView.awayRecordLabel setAttributedStringValue:[SharedUtils formattedFormString:[NSString stringWithFormat:@"Form: %@", item.awayCompetitor.form] extraAttributes:@{NSParagraphStyleAttributeName : paragraphStyle}]];
    }

    if (item.homeCompetitor.records != nil && item.homeCompetitor.records[0][@"summary"] != nil) {
        NSString *homePtsNoun = @"pts";
        if ([[item.homeCompetitor points] intValue] == 1) {
            homePtsNoun = @"pt";
        }
        
        [cellView.homeRecordLabel setStringValue:[NSString stringWithFormat:@"%@ %@ (%@)", [item.homeCompetitor points], homePtsNoun, item.homeCompetitor.records[0][@"summary"]]];
    } else {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentLeft;
        [cellView.homeRecordLabel setAttributedStringValue:[SharedUtils formattedFormString:[NSString stringWithFormat:@"Form: %@", item.homeCompetitor.form] extraAttributes:@{NSParagraphStyleAttributeName : paragraphStyle}]];
    }
    
    
    NSColor *homeContrastColor = [SharedUtils contrastColorFor:item.homeCompetitor.team.color];
    [cellView.homeLabel setTextColor:homeContrastColor];
    [cellView.homeScoreLabel setTextColor:homeContrastColor];
    [cellView.homeRecordLabel setTextColor:homeContrastColor];
    [cellView.homeRecordLabel setAlphaValue:0.6];
    
    NSColor *awayContrastColor = [SharedUtils contrastColorFor:item.awayCompetitor.team.color];
    [cellView.awayLabel setTextColor:awayContrastColor];
    [cellView.awayScoreLabel setTextColor:awayContrastColor];
    [cellView.awayRecordLabel setTextColor:awayContrastColor];
    [cellView.awayRecordLabel setAlphaValue:0.6];
    
    if (item.status == GameStateScheduled) {
        [cellView.statusField setStringValue:[item.startDate formattedDateWithFormat:@"h:mm a"]];
    } else if (item.status == GameStateFinal && [item.statusDescription containsString:@"45"]) {
        [cellView.statusField setStringValue:@"HT"];
    } else if (item.status == GameStateFinal && [item.statusDescription containsString:@"9"]) {
        [cellView.statusField setStringValue:@"FT"];
    } else {
        [cellView.statusField setStringValue:item.statusDescription];
    }
    [cellView.statusField setBackgroundColor:[NSColor textBackgroundColor]];
    [cellView.statusField setTextColor:[NSColor labelColor]];
    [cellView.statusField sizeToFit];
    
    [cellView.competitionField setStringValue:item.league];
    [cellView.competitionField setBackgroundColor:[NSColor textBackgroundColor]];
    [cellView.competitionField setTextColor:[NSColor labelColor]];
    [cellView.statusField sizeToFit];
    
    if (item.status == GameStateScheduled || item.status == GameStatePostponed) {
        [cellView.homeScoreLabel setAlphaValue:0.0];
        [cellView.awayScoreLabel setAlphaValue:0.0];
    } else {
        [cellView.homeScoreLabel setAlphaValue:1.0];
        [cellView.awayScoreLabel setAlphaValue:1.0];
        
        [cellView.homeScoreLabel setStringValue:item.homeCompetitor.score];
        [cellView.awayScoreLabel setStringValue:item.awayCompetitor.score];
        if (item.homeCompetitor.winner) {
            cellView.awayScoreLabel.alphaValue = 0.5;
        } else if (item.awayCompetitor.winner) {
            cellView.homeScoreLabel.alphaValue = 0.5;
        } else {
            cellView.awayScoreLabel.alphaValue = 1.0;
            cellView.homeScoreLabel.alphaValue = 1.0;
        }
    }
    
    return cellView;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow != -1) {
        if (TEST_DATA_MODE == true) {
            [self.navigationController pushViewController:[MatchViewController freshMatchupView:nil] animated:YES];
        } else {
            Game *g = self.scoreboard[self.tableView.selectedRow];
            NSLog(@"GAMESTATE: %lu", g.status);
            if (g.status == GameStateScheduled || g.status == GameStateCancelled) {
                [self.navigationController pushViewController:[PregameViewController freshPregameView:g] animated:YES];
            } else if (g.status == GameStateFinal) {
                [self.navigationController pushViewController:[PostgameViewController freshPostgameView:g] animated:YES];
            } else {
                [self.navigationController pushViewController:[MatchViewController freshMatchupView:g] animated:YES];
            }
        }
    }
}


-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 80;
}

@end
