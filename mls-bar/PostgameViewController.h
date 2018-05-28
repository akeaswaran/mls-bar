//
//  PostgameViewController.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Game.h"

@interface PostgameViewController : NSViewController
+ (instancetype)freshPostgameView:(Game *)g;
@end
