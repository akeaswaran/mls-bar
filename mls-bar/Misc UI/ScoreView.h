//
//  ScoreView.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/26/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ScoreView : NSTableCellView
@property (assign) IBOutlet NSView *awayBackground;
@property (assign) IBOutlet NSView *homeBackground;
@property (assign) IBOutlet NSImageView *homeTeamBgImageView;
@property (assign) IBOutlet NSImageView *awayTeamBgImageView;
@property (assign) NSColor *awayColor;
@property (assign) NSColor *homeColor;
@property (assign) IBOutlet NSTextField *competitionField;
@property (assign) IBOutlet NSTextField *statusField;
@property (assign) IBOutlet NSTextField *awayLabel;
@property (assign) IBOutlet NSTextField *homeLabel;
@property (assign) IBOutlet NSTextField *awayScoreLabel;
@property (assign) IBOutlet NSTextField *homeScoreLabel;
@property (assign) IBOutlet NSTextField *awayRecordLabel;
@property (assign) IBOutlet NSTextField *homeRecordLabel;
@end
