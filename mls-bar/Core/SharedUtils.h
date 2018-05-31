//
//  SharedUtils.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Cocoa;

#define TEST_DATA_MODE false // set to true or false to enable/disable a sample json feed when clicking on any score cell

@interface SharedUtils : NSObject
+ (NSColor *)contrastColorFor:(NSColor *)givenColor;
+ (NSColor *)pickColorBasedOnContrastWithBackground:(NSColor *)backgroundColor color1:(NSColor *)color1 color2:(NSColor *)color2;
+ (NSComparisonResult)compareEvents:(id)obj1 obj2:(id)obj2;
@end
