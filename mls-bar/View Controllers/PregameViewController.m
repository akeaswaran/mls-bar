//
//  PregameViewController.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "PregameViewController.h"
#import "ScoresViewController.h"
@import CCNNavigationController;
@import SDWebImage;
@import Cocoa;
@import DateTools;

#import "Game.h"
#import "SharedUtils.h"
#import "MatchAPI.h"

@interface PregameStatCellView : NSTableCellView
@property (assign) IBOutlet NSTextField *statTitleLabel;
@property (assign) IBOutlet NSTextField *homeStatLabel;
@property (assign) IBOutlet NSTextField *awayStatLabel;
@end

@implementation PregameStatCellView
@end

@interface MatchupCellView : NSTableCellView
@property (assign) IBOutlet NSTextField *dateLabel;
@property (assign) IBOutlet NSTextField *homeScoreLabel;
@property (assign) IBOutlet NSTextField *awayScoreLabel;
@end

@implementation MatchupCellView
@end

@interface PregameViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSMutableArray *stats;
    NSArray *h2h;
    NSDictionary *form;
    IBOutlet NSTextField *teamsNoPreviousLabel;
}
@property (strong) Game *selectedGame;
@property (assign) IBOutlet NSView *homeBackground;
@property (assign) IBOutlet NSView *awayBackground;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) NSColor *awayColor;
@property (assign) NSColor *homeColor;
@property (assign) IBOutlet NSTextField *statusField;
@property (assign) IBOutlet NSTextField *gameTitleField;
@property (assign) IBOutlet NSImageView *awayTeamImgView;
@property (assign) IBOutlet NSImageView *homeTeamImgView;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTableView *matchupTableView;
@property (assign) IBOutlet NSProgressIndicator *matchupSpinner;
@end

@implementation PregameViewController


+ (instancetype)freshPregameView:(Game *)g {
    PregameViewController *vc = [[PregameViewController alloc] initWithNibName:@"PregameViewController" bundle:nil];
    vc.selectedGame = g;
    return vc;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self.awayBackground setWantsLayer:YES];
    [self.homeBackground setWantsLayer:YES];
}

-(IBAction)popToRoot:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [((ScoresViewController *)self.navigationController.viewControllers[0]).tableView deselectRow:((ScoresViewController *)self.navigationController.viewControllers[0]).tableView.selectedRow];
}

-(IBAction)openESPN:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/matchstats?gameId=%@",self.selectedGame.gameId]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.spinner startAnimation:nil];
    [self.tableView setAlphaValue:0.0];
    [self.matchupSpinner startAnimation:nil];
    [self.matchupTableView setAlphaValue:0.0];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    NSLog(@"%@",self.selectedGame.startDate);
    [self.statusField setStringValue:[self.selectedGame.startDate formattedDateWithFormat:@"h:mm a z - MMM d, YYYY"]];
    [self setAwayColor:self.selectedGame.awayCompetitor.team.color];
    [self setHomeColor:self.selectedGame.homeCompetitor.team.color];
    
    [self.awayBackground wantsUpdateLayer];
    self.awayBackground.layer.backgroundColor = self.awayColor.CGColor;
    [self.homeBackground wantsUpdateLayer];
    self.homeBackground.layer.backgroundColor = self.homeColor.CGColor;
    
    [self.homeTeamImgView sd_setImageWithURL:self.selectedGame.homeCompetitor.team.logoURL];
    [self.awayTeamImgView sd_setImageWithURL:self.selectedGame.awayCompetitor.team.logoURL];
    
    [self.gameTitleField setStringValue:[NSString stringWithFormat:@"%@ vs %@", self.selectedGame.homeCompetitor.team.location, self.selectedGame.awayCompetitor.team.location]];
    
    stats = [NSMutableArray array];
    h2h = [NSArray array];
    form = [NSDictionary dictionary];
    
    [MatchAPI loadMatchStats:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
        } else {
            self->stats = json[@"team-statistics"];
            self->h2h = json[@"head-to-head"];
            self->form = json[@"form"];
            [self->stats insertObject:@{@"name" : @"Points", @"homeTeam" : @{
                    @"value" : [self.selectedGame.homeCompetitor points],
                    @"rank" : @""
                    },
            @"awayTeam" : @{
                    @"value" : [self.selectedGame.awayCompetitor points],
                    @"rank" : @""
                    }} atIndex:0];
            [self->stats insertObject:@{@"name" : @"Record", @"homeTeam" : @{
                                             @"value" : self.selectedGame.homeCompetitor.records[0][@"summary"] != nil ? self.selectedGame.homeCompetitor.records[0][@"summary"] : @"N/A",
                    @"rank" : @""
                    },
            @"awayTeam" : @{
                    @"value" : self.selectedGame.awayCompetitor.records[0][@"summary"] != nil ? self.selectedGame.awayCompetitor.records[0][@"summary"] : @"N/A",
                    @"rank" : @""
                    }} atIndex:1];
            [self->stats insertObject:@{
            @"name" : @"Recent Form",
            @"homeTeam" : @{
                    @"value" : (self->form[@"homeTeam"] != nil && [self->form[@"homeTeam"] length] > 0) ? self->form[@"homeTeam"] : self.selectedGame.homeCompetitor.form,
                    @"rank" : @""
                    },
            @"awayTeam" : @{
                    @"value" : (self->form[@"awayTeam"] != nil && [self->form[@"awayTeam"] length] > 0) ? self->form[@"awayTeam"] : self.selectedGame.awayCompetitor.form,
                    @"rank" : @""
                    }
            } atIndex:2];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.matchupTableView reloadData];
                [self.spinner stopAnimation:nil];
                [self.matchupSpinner stopAnimation:nil];
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = 0.75;
                    self.spinner.animator.alphaValue = 0;
                    self.tableView.animator.alphaValue = 1;
                    self.matchupSpinner.animator.alphaValue = 0;
                    self.matchupTableView.animator.alphaValue = 1;
                } completionHandler:^{
                    self.spinner.alphaValue = 0;
                    self.tableView.alphaValue = 1;
                    self.matchupSpinner.alphaValue = 0;
                    self.matchupTableView.alphaValue = 1;
                }];
            });
        }
    }];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}

#pragma mark Table View

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if ([tableView isEqual:self.tableView]) {
        return stats.count;
    } else {
        return h2h.count;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableView isEqual:self.tableView]) {
        PregameStatCellView *cellView = [tableView makeViewWithIdentifier:@"PregameStatCellView" owner:nil];
        NSDictionary *stat = stats[row];
        if ([stat[@"homeTeam"][@"rank"] length] > 0) {
            [cellView.homeStatLabel setStringValue:[NSString stringWithFormat:@"%@ (%@)", stat[@"homeTeam"][@"value"], stat[@"homeTeam"][@"rank"]]];
        } else {
            [cellView.homeStatLabel setStringValue:[NSString stringWithFormat:@"%@", stat[@"homeTeam"][@"value"]]];
        }
        if ([stat[@"awayTeam"][@"rank"] length] > 0) {
            [cellView.awayStatLabel setStringValue:[NSString stringWithFormat:@"%@ (%@)", stat[@"awayTeam"][@"value"], stat[@"awayTeam"][@"rank"]]];
        } else {
            [cellView.awayStatLabel setStringValue:[NSString stringWithFormat:@"%@", stat[@"awayTeam"][@"value"]]];
        }
        
        [cellView.statTitleLabel setStringValue:stat[@"name"]];
        
        if ([stat[@"name"] isEqualToString:@"Record"]) {
            [cellView.statTitleLabel setStringValue:@"Record (W-D-L)"];
            [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
            [cellView.homeStatLabel setAlphaValue:1.0];
            [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
            [cellView.awayStatLabel setAlphaValue:1.0];
        } else if ([stat[@"name"] isEqualToString:@"Recent Form"]) {
            [cellView.homeStatLabel setAlphaValue:1.0];
            [cellView.awayStatLabel setAlphaValue:1.0];
            [cellView.homeStatLabel setAttributedStringValue:[SharedUtils formattedFormString:stat[@"homeTeam"][@"value"]]];
            [cellView.awayStatLabel setAttributedStringValue:[SharedUtils formattedFormString:stat[@"awayTeam"][@"value"]]];
        } else {
            if ([stat[@"homeTeam"][@"value"] intValue] > [stat[@"awayTeam"][@"value"] intValue]) {
                [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
                [cellView.awayStatLabel setAlphaValue:0.5];
            } else if ([stat[@"awayTeam"][@"value"] intValue] > [stat[@"homeTeam"][@"value"] intValue]) {
                [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
                [cellView.homeStatLabel setAlphaValue:0.5];
            } else {
                [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
                [cellView.homeStatLabel setAlphaValue:1.0];
                [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
                [cellView.awayStatLabel setAlphaValue:1.0];
            }
        }
        
        return cellView;
    } else {
        MatchupCellView *cellView = [tableView makeViewWithIdentifier:@"MatchupCellView" owner:nil];
        if (h2h.count > 0) {
            teamsNoPreviousLabel.alphaValue = 0.0;
            cellView.alphaValue = 1.0;
            NSDictionary *matchup = h2h[row];
            [cellView.dateLabel setStringValue:matchup[@"date"]];
            if ([matchup[@"homeTeam"] isEqualToString:self.selectedGame.homeCompetitor.team.abbreviation]) {
                [cellView.homeScoreLabel setStringValue:matchup[@"homeScore"]];
                [cellView.awayScoreLabel setStringValue:matchup[@"awayScore"]];
                if ([matchup[@"homeScore"] intValue] > [matchup[@"awayScore"] intValue]) {
                    [cellView.awayScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.awayScoreLabel setAlphaValue:0.5];
                } else if ([matchup[@"awayScore"] intValue] > [matchup[@"homeScore"] intValue]) {
                    [cellView.homeScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.homeScoreLabel setAlphaValue:0.5];
                } else {
                    [cellView.homeScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.homeScoreLabel setAlphaValue:1.0];
                    [cellView.awayScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.awayScoreLabel setAlphaValue:1.0];
                }
            } else {
                [cellView.homeScoreLabel setStringValue:matchup[@"awayScore"]];
                [cellView.awayScoreLabel setStringValue:matchup[@"homeScore"]];
                if ([matchup[@"homeScore"] intValue] > [matchup[@"awayScore"] intValue]) {
                    [cellView.homeScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.homeScoreLabel setAlphaValue:0.5];
                } else if ([matchup[@"awayScore"] intValue] > [matchup[@"homeScore"] intValue]) {
                    [cellView.awayScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.awayScoreLabel setAlphaValue:0.5];
                } else {
                    [cellView.homeScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.homeScoreLabel setAlphaValue:1.0];
                    [cellView.awayScoreLabel setTextColor:[NSColor labelColor]];
                    [cellView.awayScoreLabel setAlphaValue:1.0];
                }
            }
        } else {
            cellView.alphaValue = 0.0;
            teamsNoPreviousLabel.alphaValue = 1.0;
        }
        return cellView;
    }
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
