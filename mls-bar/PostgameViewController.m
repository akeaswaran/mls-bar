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
@import DateTools;

#import "Game.h"
#import "SharedUtils.h"
#import "MatchAPI.h"

@interface KeyEventCellView : NSTableCellView
@property (assign) IBOutlet NSTextField *teamLabel;
@property (assign) IBOutlet NSTextField *eventLabel;
@end

@implementation KeyEventCellView
@end

@interface PostgameStatCellView : NSTableCellView
@property (assign) IBOutlet NSTextField *statTitleLabel;
@property (assign) IBOutlet NSTextField *homeStatLabel;
@property (assign) IBOutlet NSTextField *awayStatLabel;
@end

@implementation PostgameStatCellView
@end

@interface PostgameViewController () <NSTableViewDelegate, NSTableViewDataSource> {
    NSMutableArray *stats;
    NSMutableArray *keyEvents;
    NSColor *backgroundColor;
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
@property (assign) IBOutlet NSTableView *eventsTableView;
@property (assign) IBOutlet NSProgressIndicator *eventsSpinner;
@end

@implementation PostgameViewController

- (NSDictionary *)eventTypesMap {
    static dispatch_once_t onceToken;
    static NSDictionary *typesMap;
    dispatch_once(&onceToken, ^{
        typesMap = @{
                     @"redCard" : @"Red Card",
                     @"yellowCard" : @"Yellow Card",
                     @"goal" : @"Goal"
                     };
    });
    return typesMap;
}

-(NSString *)eventTitleForType:(NSString *)type {
    return [self eventTypesMap][type];
}

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

-(IBAction)openESPN:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.espn.com/soccer/matchstats?gameId=%@",self.selectedGame.gameId]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.spinner startAnimation:nil];
    [self.tableView setAlphaValue:0.0];
    [self.eventsSpinner startAnimation:nil];
    [self.eventsTableView setAlphaValue:0.0];
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if (osxMode != nil && [osxMode isEqualToString:@"Dark"]) {
        backgroundColor = [NSColor blackColor];
    } else {
        backgroundColor = [NSColor whiteColor];
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    
    [self.statusField setStringValue:[NSString stringWithFormat:@"%@ - %@", self.selectedGame.statusDescription, [self.selectedGame.startDate formattedDateWithFormat:@"MMM d, YYYY"]]];
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
    keyEvents = [NSMutableArray array];
    
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
            [self.eventsTableView reloadData];
            [self.spinner stopAnimation:nil];
            [self.eventsSpinner stopAnimation:nil];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.75;
                self.spinner.animator.alphaValue = 0;
                self.tableView.animator.alphaValue = 1;
                self.eventsSpinner.animator.alphaValue = 0;
                self.eventsTableView.animator.alphaValue = 1;
            } completionHandler:^{
                self.spinner.alphaValue = 0;
                self.tableView.alphaValue = 1;
                self.eventsSpinner.alphaValue = 0;
                self.eventsTableView.alphaValue = 1;
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
    if ([tableView isEqual:self.tableView]) {
        return stats.count;
    } else {
        return keyEvents.count;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableView isEqual:self.tableView]) {
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
    } else {
        KeyEventCellView *cellView = [tableView makeViewWithIdentifier:@"KeyEventCellView" owner:nil];
        NSDictionary *event = keyEvents[row];
        [cellView.teamLabel setStringValue:([event[@"team"] isEqualToString:@"home"]) ? self.selectedGame.homeCompetitor.team.abbreviation : self.selectedGame.awayCompetitor.team.abbreviation];
        //[cellView.teamLabel setTextColor:([event[@"team"] isEqualToString:@"home"]) ? self.selectedGame.homeCompetitor.team.color : self.selectedGame.awayCompetitor.team.color];
        [cellView.teamLabel setTextColor:[SharedUtils pickColorBasedOnContrastWithBackground:backgroundColor color1:([event[@"team"] isEqualToString:@"home"]) ? self.selectedGame.homeCompetitor.team.color : self.selectedGame.awayCompetitor.team.color color2:([event[@"team"] isEqualToString:@"home"]) ? self.selectedGame.homeCompetitor.team.alternateColor : self.selectedGame.awayCompetitor.team.alternateColor]];
        [cellView.eventLabel setStringValue:[NSString stringWithFormat:@"%@: %@ - %@", event[@"timestamp"], [self eventTitleForType:event[@"type"]], event[@"player"]]];
        [cellView.eventLabel sizeToFit];
        return cellView;
    }
}


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
