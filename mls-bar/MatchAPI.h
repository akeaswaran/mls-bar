//
//  MatchAPI.h
//  mls-bar
//
//  Created by Akshay Easwaran on 5/27/18.
//  Copyright © 2018 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^GeneralLoadHandler)(NSDictionary *json, NSError *error);
typedef void (^ResponseHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface MatchAPI : NSObject
+ (void)loadInititalCommentaryEventsForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback;
+ (void)continuousLoadCommentaryEventsForGame:(NSString *)gameId lastEventId:(NSString *)lastId completionHandler:(GeneralLoadHandler)callback;
+ (void)loadMatchStats:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback;
+ (void)loadESPNPostGameSummaryForGame:(NSString *)gameId completionHandler:(GeneralLoadHandler)callback;
@end
