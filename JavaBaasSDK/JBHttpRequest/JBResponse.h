//
//  JBResponse.h
//  Example
//
//  Created by test on 2017/10/26.
//  Copyright © 2017年 Buge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBResponse : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) int code;
@property (nonatomic, strong) id data;

+ (JBResponse*)initWithDictionary:(NSDictionary *)dictionay;

@end
