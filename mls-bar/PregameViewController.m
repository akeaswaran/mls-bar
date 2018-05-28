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
    NSMutableArray *stats;
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
    
    stats = [NSMutableArray array];
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
            [self->stats insertObject:@{@"name" : @"Record", @"homeTeam" : @{
                                                @"value" : self.selectedGame.homeCompetitor.records[0][@"summary"],
                                                @"rank" : @""
                                                },
                                        @"awayTeam" : @{
                                                @"value" : self.selectedGame.awayCompetitor.records[0][@"summary"],
                                                @"rank" : @""
                                                }} atIndex:0];
            [self->stats insertObject:@{
                                        @"name" : @"Recent Form",
                                        @"homeTeam" : @{
                                                @"value" : self->form[@"homeTeam"],
                                                @"rank" : @""
                                                },
                                        @"awayTeam" : @{
                                                @"value" : self->form[@"awayTeam"],
                                                @"rank" : @""
                                                }
                                        } atIndex:1];
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
        [cellView.homeStatLabel setAttributedStringValue:[self formattedFormString:stat[@"homeTeam"][@"value"]]];
        [cellView.awayStatLabel setAttributedStringValue:[self formattedFormString:stat[@"awayTeam"][@"value"]]];
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
}

-(NSAttributedString *)formattedFormString:(NSString *)formString {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName : paragraphStyle};
    NSMutableAttributedString *goodText = [[NSMutableAttributedString alloc] initWithString:formString attributes:attributes];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"W|L|D" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:formString options:0 range:NSMakeRange(0, formString.length)];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        if ([[formString substringWithRange:[match range]] isEqualToString:@"W"]) {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:match.range];
        } else if ([[formString substringWithRange:[match range]] isEqualToString:@"L"]) {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:match.range];
        } else {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:match.range];
        }
    }

    return goodText;
}

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

@end
