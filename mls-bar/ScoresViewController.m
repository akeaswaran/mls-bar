//
//  ScoresViewController.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "ScoresViewController.h"
@import CCNNavigationController;
#import <Mantle/Mantle.h>
#import "HexColors.h"

#import "ScoreView.h"
#import "MatchViewController.h"
#import "SharedUtils.h"
#import "AppDelegate.h"

#import "Game.h"
#import "Team.h"

@interface ScoresViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (strong) NSMutableArray *scoreboard;
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
    
//    self.tableView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(NSHeight(self.view.window.frame)+50.0, 0, 0, 0);
//    NSRect bounds = self.tableView.enclosingScrollView.contentView.bounds;
//    bounds.origin.y -= 50.0;
//    self.tableView.enclosingScrollView.contentView.bounds = bounds;
//
    
    [self loadGames:^(NSDictionary *json, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"ERROR: %@", error);
                self.scoreboard = [NSMutableArray array];
            } else {
                //NSLog(@"GAMES: %@", json);
                self.scoreboard = [NSMutableArray arrayWithArray:json[@"games"]];
                [self.tableView reloadData];
            }
        });
    }];
}

-(void)loadGames:(void (^)(NSDictionary *json, NSError *error))callback {
    NSURL *URL = [NSURL URLWithString:@"http://site.api.espn.com/apis/site/v2/sports/soccer/usa.1/scoreboard"];
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
    [cellView.homeLabel setStringValue:item.homeCompetitor.team.location];
    [cellView.awayLabel setStringValue:item.awayCompetitor.team.location];
    [cellView setAwayColor:item.awayCompetitor.team.color];
    [cellView setHomeColor:item.homeCompetitor.team.color];
    
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
        //NSLog(@"%lu", self.tableView.selectedRow);
        //NSLog(@"GAMEID: %@", self.scoreboard[self.tableView.selectedRow]);
        [self.navigationController pushViewController:[MatchViewController freshMatchupView:self.scoreboard[self.tableView.selectedRow]] animated:YES];
    }
}


-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 80;
}

@end
