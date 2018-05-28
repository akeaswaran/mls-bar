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

#import "ScoreView.h"
#import "MatchViewController.h"
#import "PregameViewController.h"
#import "PostgameViewController.h"
#import "SharedUtils.h"
#import "AppDelegate.h"

#import "Game.h"
#import "Team.h"

@interface ScoresViewController () <NSTableViewDelegate, NSTableViewDataSource>
    {
        NSDate *currentDate;
    }
@property (strong) NSMutableArray *scoreboard;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSTextField *noGamesLabel;
@property (weak) IBOutlet NSTextField *currentDateLabel;
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
    [NSApp terminate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;

    currentDate = [NSDate date];
    [self loadGamesForDate:currentDate];
    
}
    
-(IBAction)showNextDay:(id)sender {
    [self loadGamesForDate:[currentDate dateByAddingDays:1]];
}
    
-(IBAction)showPrevDay:(id)sender {
    [self loadGamesForDate:[currentDate dateBySubtractingDays:1]];
}
    
-(void)loadGamesForDate:(NSDate *)date {
    currentDate = date;
    self.noGamesLabel.alphaValue = 0.0;
    self.tableView.alphaValue = 0.0;
    [self.spinner startAnimation:nil];
    NSString *dateString = [date formattedDateWithFormat:@"YYYYMMdd"];
    [self.currentDateLabel setStringValue:[date formattedDateWithFormat:@"MMM d, YYYY"]];
    
    [self loadGames:dateString completion:^(NSDictionary *json, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"ERROR: %@", error);
                self.scoreboard = [NSMutableArray array];
            } else {
                self.scoreboard = [NSMutableArray arrayWithArray:json[@"games"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.spinner stopAnimation:nil];
                    NSLog(@"COUNT: %lu", self.scoreboard.count);
                    if (self.scoreboard.count > 0) {
                        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                            context.duration = 0.75;
                            self.noGamesLabel.alphaValue = 0.0;
                            self.spinner.animator.alphaValue = 0;
                            self.tableView.animator.alphaValue = 1;
                        } completionHandler:^{
                            self.spinner.alphaValue = 0;
                            self.tableView.alphaValue = 1;
                            self.noGamesLabel.alphaValue = 0;
                        }];
                    } else {
                        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                            context.duration = 0.75;
                            self.spinner.animator.alphaValue = 0;
                            self.noGamesLabel.animator.alphaValue = 1;
                        } completionHandler:^{
                            self.spinner.alphaValue = 0;
                            self.noGamesLabel.alphaValue = 1;
                        }];
                    }
                });
            }
        });
    }];
}

-(void)loadGames:(NSString *)dateString completion:(void (^)(NSDictionary *json, NSError *error))callback {
    NSLog(@"datestring : %@", dateString);
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard?dates=%@",dateString]];
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
    [cellView setAwayColor:item.awayCompetitor.team.color];
    [cellView setHomeColor:item.homeCompetitor.team.color];
    [cellView setNeedsDisplay:YES];
    
    [cellView.homeRecordLabel setStringValue:item.homeCompetitor.records[0][@"summary"]];
    [cellView.homeRecordLabel setTextColor:item.homeCompetitor.team.alternateColor];
    [cellView.awayRecordLabel setStringValue:item.awayCompetitor.records[0][@"summary"]];
    [cellView.awayRecordLabel setTextColor:item.awayCompetitor.team.alternateColor];
    
    NSColor *homeContrastColor = [SharedUtils contrastColorFor:item.homeCompetitor.team.color];
    [cellView.homeLabel setTextColor:homeContrastColor];
    [cellView.homeScoreLabel setTextColor:homeContrastColor];
    
    NSColor *awayContrastColor = [SharedUtils contrastColorFor:item.awayCompetitor.team.color];
    [cellView.awayLabel setTextColor:awayContrastColor];
    [cellView.awayScoreLabel setTextColor:awayContrastColor];
    
    [cellView.statusField setStringValue:item.statusDescription];
    [cellView.statusField setBackgroundColor:[NSColor whiteColor]];
    [cellView.statusField setTextColor:[NSColor blackColor]];
    
    [cellView.statusField sizeToFit];
    
    
    if (item.status == GameStateScheduled) {
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
        Game *g = self.scoreboard[self.tableView.selectedRow];
        if (g.status == GameStateScheduled || g.status == GameStateCancelled) {
            [self.navigationController pushViewController:[PregameViewController freshPregameView:g] animated:YES];
        } else if (g.status == GameStateFinal) {
            [self.navigationController pushViewController:[PostgameViewController freshPostgameView:g] animated:YES];
        } else {
            [self.navigationController pushViewController:[MatchViewController freshMatchupView:g] animated:YES];
        }
        
    }
}


-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 80;
}

@end
