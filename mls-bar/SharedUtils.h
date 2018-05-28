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
+ (NSColor *)pickColorBasedOnContrastWithBackground:(NSColor *)backgroundColor color1:(NSColor *)color1 color2:(NSColor *)color2;
@end
