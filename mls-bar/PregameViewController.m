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

@interface PregameViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSArray *stats;
    NSArray *h2h;
    NSDictionary *form;
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
    
    [self.gameTitleField setStringValue:[NSString stringWithFormat:@"%@ vs %@", self.selectedGame.homeCompetitor.team.location, self.selectedGame.awayCompetitor.team.location]];
    
    stats = [NSArray array];
    h2h = [NSArray array];
    form = [NSDictionary dictionary];
    
    [MatchAPI loadMatchStats:self.selectedGame.gameId completionHandler:^(NSDictionary *json, NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
        } else {
//            NSLog(@"RESPONSE: %@", json);
            self->stats = json[@"team-statistics"];
            self->h2h = json[@"head-to-head"];
            self->form = json[@"form"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.spinner stopAnimation:nil];
                [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                    context.duration = 1.0;
                    self.spinner.animator.alphaValue = 0;
                    self.tableView.animator.alphaValue = 1;
                } completionHandler:^{
                    self.spinner.alphaValue = 0;
                    self.tableView.alphaValue = 1;
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
    return stats.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    PregameStatCellView *cellView = [tableView makeViewWithIdentifier:@"PregameStatCellView" owner:nil];
    NSDictionary *stat = stats[row];
    [cellView.homeStatLabel setStringValue:[NSString stringWithFormat:@"%@ (%@)", stat[@"homeTeam"][@"value"], stat[@"homeTeam"][@"rank"]]];
    [cellView.awayStatLabel setStringValue:[NSString stringWithFormat:@"%@ (%@)", stat[@"awayTeam"][@"value"], stat[@"awayTeam"][@"rank"]]];
    [cellView.statTitleLabel setStringValue:stat[@"name"]];
    
    if ([stat[@"homeTeam"][@"value"] intValue] > [stat[@"awayTeam"][@"value"] intValue]) {
        //[cellView.homeStatLabel setTextColor:self.selectedGame.homeCompetitor.team.alternateColor];
        [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
        [cellView.awayStatLabel setAlphaValue:0.5];
    } else if ([stat[@"awayTeam"][@"value"] intValue] > [stat[@"homeTeam"][@"value"] intValue]) {
        //[cellView.awayStatLabel setTextColor:self.selectedGame.awayCompetitor.team.alternateColor];
        [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
        [cellView.homeStatLabel setAlphaValue:0.5];
    } else {
        [cellView.homeStatLabel setTextColor:[NSColor labelColor]];
        [cellView.homeStatLabel setAlphaValue:1.0];
        [cellView.awayStatLabel setTextColor:[NSColor labelColor]];
        [cellView.awayStatLabel setAlphaValue:1.0];
    }
    
    return cellView;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
