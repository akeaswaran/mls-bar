//
//  PostgameViewController.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "PostgameViewController.h"
#import "ScoresViewController.h"
@import CCNNavigationController;
@import SDWebImage;
@import Cocoa;

#import "Game.h"
#import "SharedUtils.h"
#import "MatchAPI.h"

@interface PostgameStatCellView : NSTableCellView
    @property (assign) IBOutlet NSTextField *statTitleLabel;
    @property (assign) IBOutlet NSTextField *homeStatLabel;
    @property (assign) IBOutlet NSTextField *awayStatLabel;
    @end

@implementation PostgameStatCellView
    @end

@interface PostgameViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSMutableArray *stats;
    NSDictionary *keyEvents;
}
@property (strong) Game *selectedGame;
@property (assign) IBOutlet NSView *homeBackground;
@property (assign) IBOutlet NSView *awayBackground;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) NSColor *awayColor;
@property (assign) NSColor *homeColor;
@property (assign) IBOutlet NSTextField *awayScoreLabel;
@property (assign) IBOutlet NSTextField *homeScoreLabel;
@property (assign) IBOutlet NSTextField *statusField;
@property (assign) IBOutlet NSTextField *gameTitleField;
@property (assign) IBOutlet NSImageView *awayTeamImgView;
@property (assign) IBOutlet NSImageView *homeTeamImgView;
@property (assign) IBOutlet NSTableView *tableView;
@end

@implementation PostgameViewController
    
    
+ (instancetype)freshPostgameView:(Game *)g {
    PostgameViewController *vc = [[PostgameViewController alloc] initWithNibName:@"PostgameViewController" bundle:nil];
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
    
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.spinner startAnimation:nil];
    [self.tableView setAlphaValue:0.0];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    
    [self.statusField setStringValue:self.selectedGame.statusDescription];
    [self setAwayColor:self.selectedGame.awayCompetitor.team.color];
    [self setHomeColor:self.selectedGame.homeCompetitor.team.color];
    
    [self.awayBackground wantsUpdateLayer];
    self.awayBackground.layer.backgroundColor = self.awayColor.CGColor;
    [self.homeBackground wantsUpdateLayer];
    self.homeBackground.layer.backgroundColor = self.homeColor.CGColor;
    
    [self.homeTeamImgView sd_setImageWithURL:self.selectedGame.homeCompetitor.team.logoURL];
    [self.awayTeamImgView sd_setImageWithURL:self.selectedGame.awayCompetitor.team.logoURL];
    
    NSColor *homeContrastColor = [SharedUtils contrastColorFor:self.selectedGame.homeCompetitor.team.color];
    [self.homeScoreLabel setTextColor:homeContrastColor];
    [self.homeScoreLabel setStringValue:self.selectedGame.homeCompetitor.score];
    
    NSColor *awayContrastColor = [SharedUtils contrastColorFor:self.selectedGame.awayCompetitor.team.color];
    [self.awayScoreLabel setTextColor:awayContrastColor];
    [self.awayScoreLabel setStringValue:self.selectedGame.awayCompetitor.score];
    
    if (self.selectedGame.homeCompetitor.winner) {
        self.awayScoreLabel.alphaValue = 0.5;
    } else if (self.selectedGame.awayCompetitor.winner) {
        self.homeScoreLabel.alphaValue = 0.5;
    } else {
        self.awayScoreLabel.alphaValue = 1.0;
        self.homeScoreLabel.alphaValue = 1.0;
    }
    
    [self.gameTitleField setStringValue:[NSString stringWithFormat:@"%@ vs %@", self.selectedGame.homeCompetitor.team.location, self.selectedGame.awayCompetitor.team.location]];
    
    stats = [NSMutableArray array];
    keyEvents = [NSDictionary dictionary];
    
    [MatchAPI loadESPNPostGameSummaryForGame:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
        //NSLog(@"%@",json); //keyevents = team : {type : info}, stats = [{awayValue, homevalue, name}]
        if (error) {
            NSLog(@"ERROR: %@", error);
        } else {
            self->stats = json[@"stats"];
            self->keyEvents = json[@"keyEvents"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.spinner stopAnimation:nil];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.75;
                self.spinner.animator.alphaValue = 0;
                self.tableView.animator.alphaValue = 1;
            } completionHandler:^{
                self.spinner.alphaValue = 0;
                self.tableView.alphaValue = 1;
            }];
        });
        
    }];
}
    
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}
    
#pragma mark Table View
    
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
    {
        return stats.count;
    }
    
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
    {
        PostgameStatCellView *cellView = [tableView makeViewWithIdentifier:@"PostgameStatCellView" owner:nil];
        NSDictionary *stat = stats[row];
        [cellView.homeStatLabel setStringValue:[NSString stringWithFormat:@"%@", stat[@"homeValue"]]];
        [cellView.awayStatLabel setStringValue:[NSString stringWithFormat:@"%@", stat[@"awayValue"]]];
        
        [cellView.statTitleLabel setStringValue:stat[@"name"]];
        
        if ([stat[@"name"] isEqualToString:@"Shots"]) {
            NSString *actualHomeValue = [stat[@"homeValue"] componentsSeparatedByString:@" "][0];
            NSString *actualAwayValue = [stat[@"awayValue"] componentsSeparatedByString:@" "][0];
            if ([actualHomeValue intValue] > [actualAwayValue intValue]) {
                [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
                [cellView.awayStatLabel setAlphaValue:0.5];
            } else if ([actualAwayValue intValue] > [actualHomeValue intValue]) {
                [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
                [cellView.homeStatLabel setAlphaValue:0.5];
            } else {
                [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
                [cellView.homeStatLabel setAlphaValue:1.0];
                [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
                [cellView.awayStatLabel setAlphaValue:1.0];
            }
        } else {
            if ([[stat[@"homeValue"] stringByReplacingOccurrencesOfString:@"%%" withString:@""] intValue] > [[stat[@"awayValue"] stringByReplacingOccurrencesOfString:@"%%" withString:@""] intValue]) {
                [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
                [cellView.awayStatLabel setAlphaValue:0.5];
            } else if ([[stat[@"awayValue"] stringByReplacingOccurrencesOfString:@"%%" withString:@""] intValue] > [[stat[@"homeValue"] stringByReplacingOccurrencesOfString:@"%%" withString:@""] intValue]) {
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
    }

    
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}
    
    @end
