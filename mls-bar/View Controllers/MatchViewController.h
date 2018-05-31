//
//  MatchViewController.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Game;

@interface MatchViewController : NSViewController
@property (assign) IBOutlet NSView *homeBackground;
@property (assign) IBOutlet NSView *awayBackground;
@property (assign) NSColor *awayColor;
@property (assign) NSColor *homeColor;
@property (assign) IBOutlet NSTextField *statusField;
@property (assign) IBOutlet NSTextField *awayScoreLabel;
@property (assign) IBOutlet NSTextField *homeScoreLabel;
@property (assign) IBOutlet NSImageView *awayTeamImgView;
@property (assign) IBOutlet NSImageView *homeTeamImgView;
@property (assign) IBOutlet NSTextView *commentaryView;
@property (assign) IBOutlet NSTableView *matchEventsView;
@property (assign) IBOutlet NSProgressIndicator *matchSpinner;
+ (instancetype)freshMatchupView:(Game *)g;
@end
