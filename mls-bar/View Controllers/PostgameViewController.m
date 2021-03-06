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
@property (assign) IBOutlet NSTextField *noUpdatesLabel;
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
    [self.noUpdatesLabel setAlphaValue:0.0];
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
    
    if ([self.selectedGame.statusDescription containsString:@"45"]) {
        [self.statusField setStringValue:[NSString stringWithFormat:@"Halftime - %@", [self.selectedGame.startDate formattedDateWithFormat:@"MMM d, YYYY"]]];
    } else {
        [self.statusField setStringValue:[NSString stringWithFormat:@"%@ - %@", self.selectedGame.statusDescription, [self.selectedGame.startDate formattedDateWithFormat:@"MMM d, YYYY"]]];
    }
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
            [self->keyEvents sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSDictionary *event1 = (NSDictionary *)obj1;
                NSDictionary *event2 = (NSDictionary *)obj2;
                
                NSString *event1TS = [event1[@"timestamp"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                NSNumber *event1Num = [NSNumber numberWithInt:0];
                
                NSString *event2TS = [event2[@"timestamp"] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                NSNumber *event2Num = [NSNumber numberWithInt:0];
                
                NSError *err;
                if ([event1TS containsString:@"+"]) {
                    NSRegularExpression *regexPlus = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)\\+(\\d+)" options:NSRegularExpressionCaseInsensitive error:&err];
                    if (err) {
                        return 0;
                    }
                    NSTextCheckingResult *event1match = [regexPlus firstMatchInString:event1TS options:0 range:NSMakeRange(0, event1TS.length)];
                    if (event1match != nil) {
                        NSString *minute = [event1TS substringWithRange:[event1match rangeAtIndex:1]];
                        NSString *addedTime = [event1TS substringWithRange:[event1match rangeAtIndex:2]];
                        event1Num = [NSNumber numberWithInt:minute.intValue + addedTime.intValue];
                    }
                } else {
                    event1Num = [NSNumber numberWithInt:event1TS.intValue];
                }
                
                if ([event2TS containsString:@"+"]) {
                    NSRegularExpression *regexPlus = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)\\+(\\d+)" options:NSRegularExpressionCaseInsensitive error:&err];
                    if (err) {
                        return 0;
                    }
                    NSTextCheckingResult *event2match = [regexPlus firstMatchInString:event2TS options:0 range:NSMakeRange(0, event2TS.length)];
                    if (event2match != nil) {
                        NSString *minute = [event2TS substringWithRange:[event2match rangeAtIndex:1]];
                        NSString *addedTime = [event2TS substringWithRange:[event2match rangeAtIndex:2]];
                        event2Num = [NSNumber numberWithInt:minute.intValue + addedTime.intValue];
                    }
                } else {
                    event2Num = [NSNumber numberWithInt:event2TS.intValue];
                }
                
                return [event1Num compare:event2Num];
            }];
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
                if (self->keyEvents.count > 0) {
                    self.eventsSpinner.animator.alphaValue = 0;
                    self.eventsTableView.animator.alphaValue = 1;
                    self.noUpdatesLabel.animator.alphaValue = 0.0;
                } else {
                    self.eventsSpinner.animator.alphaValue = 0;
                    self.eventsTableView.animator.alphaValue = 0;
                    self.noUpdatesLabel.animator.alphaValue = 1.0;
                }
            } completionHandler:^{
                self.spinner.alphaValue = 0;
                self.tableView.alphaValue = 1;
                if (self->keyEvents.count > 0) {
                    self.eventsSpinner.alphaValue = 0;
                    self.eventsTableView.alphaValue = 1;
                    self.noUpdatesLabel.animator.alphaValue = 0.0;
                } else {
                    self.eventsSpinner.alphaValue = 0;
                    self.eventsTableView.alphaValue = 0;
                    self.noUpdatesLabel.animator.alphaValue = 1.0;
                }
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
        [cellView.teamLabel setTextColor:([event[@"team"] isEqualToString:@"home"]) ? self.selectedGame.homeCompetitor.team.color : self.selectedGame.awayCompetitor.team.color];
        [cellView.eventLabel setStringValue:[NSString stringWithFormat:@"%@: %@ - %@", event[@"timestamp"], [self eventTitleForType:event[@"type"]], event[@"player"]]];
        [cellView.eventLabel sizeToFit];
        return cellView;
    }
}


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
