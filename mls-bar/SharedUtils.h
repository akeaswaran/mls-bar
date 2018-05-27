//
//  SharedUtils.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Cocoa;

@interface SharedUtils : NSObject
+ (NSColor *)contrastColorFor:(NSColor *)givenColor;
@end
