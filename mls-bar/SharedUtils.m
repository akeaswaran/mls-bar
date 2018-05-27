//
//  SharedUtils.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "SharedUtils.h"

@implementation SharedUtils

+ (NSColor *)contrastColorFor:(NSColor *)givenColor {
    CGFloat red = givenColor.redComponent;
    CGFloat green = givenColor.greenComponent;
    CGFloat blue = givenColor.blueComponent;
    
    NSArray *colors = @[@(red), @(green), @(blue)];
    NSMutableArray<NSNumber *> *mappedCols = [NSMutableArray array];
    for (NSNumber *n in colors) {
        if (n.floatValue <= 0.03928) {
            [mappedCols addObject:@(n.floatValue / 12.92)];
        } else {
            [mappedCols addObject:@(pow((n.floatValue + 0.055) / 1.055, 2.4))];
        }
    }
    
    float L = (0.2126 * mappedCols[0].floatValue) + (0.7152 * mappedCols[1].floatValue) + (0.0722 * mappedCols[2].floatValue);
    return (L > 0.179) ? [NSColor blackColor] : [NSColor whiteColor];
}
@end
