//
//  SharedUtils.m
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import "SharedUtils.h"
#import "MatchAPI.h"

@implementation SharedUtils

+ (NSDictionary<NSString *, NSString *> *)leagueNameMappings {
    static dispatch_once_t onceToken;
    static NSDictionary *leagues;
    dispatch_once(&onceToken, ^{
        leagues = @{
            @"CCL" : @"CONCACAF Champions League",
            @"MLS" : @"Major League Soccer",
            @"USLC" : @"USL Championship",
            @"NWSL" : @"NWSL",
            @"USOC" : @"US Open Cup",
        };
    });
    return leagues;
}

+ (NSComparisonResult)compareEvents:(id)obj1 obj2:(id)obj2 {
    NSDictionary *objA = (NSDictionary *)obj1;
    NSDictionary *objB = (NSDictionary *)obj2;
    
    return [[NSNumber numberWithInteger:[objA[@"id"] integerValue]] compare:[NSNumber numberWithInteger:[objB[@"id"] integerValue]]];
}

+ (NSAttributedString *)formattedFormString:(NSString *)formString {
    return [self formattedFormString:formString extraAttributes:@{}];
}

+ (NSAttributedString *)formattedFormString:(NSString *)formString extraAttributes:(NSDictionary *)attrs {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes addEntriesFromDictionary:@{NSParagraphStyleAttributeName : paragraphStyle}];
    [attributes addEntriesFromDictionary:attrs];
    
    NSMutableAttributedString *goodText = [[NSMutableAttributedString alloc] initWithString:formString attributes:attributes];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"W|L|D" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:formString options:0 range:NSMakeRange(0, formString.length)];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        if ([[formString substringWithRange:[match range]] isEqualToString:@"W"]) {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor systemGreenColor] range:match.range];
        } else if ([[formString substringWithRange:[match range]] isEqualToString:@"L"]) {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor systemRedColor] range:match.range];
        } else {
            [goodText addAttribute:NSForegroundColorAttributeName value:[NSColor secondaryLabelColor] range:match.range];
        }
    }
    
    if (goodText.length == 0) {
        goodText = [[NSMutableAttributedString alloc] initWithString:@"N/A" attributes:@{NSForegroundColorAttributeName : [NSColor secondaryLabelColor]}];
    }

    return goodText;
}


+ (NSInteger)retrieveCurrentUpdateInterval {
    NSInteger curUpdateInterval = [[NSUserDefaults standardUserDefaults] integerForKey:DNV_UPDATE_INTERVAL_KEY];
    if (curUpdateInterval <= 0) {
        return 60;
    } else {
        return curUpdateInterval;
    }
}

+ (NSColor *)contrastColorFor:(NSColor *)givenColor {
    return ([SharedUtils calculateL:givenColor] > 0.179) ? [NSColor blackColor] : [NSColor whiteColor];
}

+ (float)calculateL:(NSColor *)color {
    CGFloat red = color.redComponent;
    CGFloat green = color.greenComponent;
    CGFloat blue = color.blueComponent;
    
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
    return L;
}

+ (float)calculatePerspectiveLuminance:(NSColor *)color {
    double a = 1 - ( 0.299 * color.redComponent + 0.587 * color.greenComponent + 0.114 * color.blueComponent)/255;
    return a;
}

+ (NSColor *)pickColorBasedOnContrastWithBackground:(NSColor *)backgroundColor color1:(NSColor *)color1 color2:(NSColor *)color2 {
    float clr1PL = [SharedUtils calculatePerspectiveLuminance:color1];
    float clr2PL = [SharedUtils calculatePerspectiveLuminance:color2];
    
    if ([backgroundColor isEqual:[NSColor blackColor]]) { // want the least bright
        if (clr1PL < clr2PL) {
            return color1;
        } else {
            return color2;
        }
    } else if ([backgroundColor isEqual:[NSColor whiteColor]]) { // want the most bright
        if (clr1PL > clr2PL) {
            return color1;
        } else {
            return color2;
        }
    } else {
        return color1; // want default
    }
}
@end
