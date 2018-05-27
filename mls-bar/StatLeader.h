//
//  StatLeader.h
//  cfb
//
//  Created by Akshay Easwaran on 12/3/17.
//  Copyright © 2017 Akshay Easwaran. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface StatLeader : MTLModel <MTLJSONSerializing>
@property (nonatomic, copy) NSString *jerseyNumber;
@property (nonatomic, copy) NSString *position;
@property (nonatomic, copy) NSString *teamId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *displayValue;
@end
