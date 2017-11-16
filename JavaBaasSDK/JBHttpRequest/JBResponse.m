//
//  JBResponse.m
//  Example
//
//  Created by test on 2017/10/26.
//  Copyright © 2017年 Buge. All rights reserved.
//

#import "JBResponse.h"

@implementation JBResponse

+ (JBResponse *)initWithDictionary:(NSDictionary *)dictionay {
    if (dictionay) {
        JBResponse *response = [JBResponse alloc];
        if ([dictionay objectForKey:@"message"]) {
            response.message = [dictionay objectForKey:@"message"];
        }
        if ([dictionay objectForKey:@"code"]) {
            response.code = [[dictionay objectForKey:@"code"] intValue];
        }
        if ([dictionay objectForKey:@"data"] && [[dictionay objectForKey:@"data"] objectForKey:@"result"]) {
            response.data = [[dictionay objectForKey:@"data"] objectForKey:@"result"];
        }
        return response;
    } else {
        return nil;
    }
}

@end
