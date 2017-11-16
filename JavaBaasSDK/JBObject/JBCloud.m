//
//  JBCloud.m
//  bugeiOS
//
//  Created by zhaopeng on 15/10/15.
//  Copyright © 2015年 buge. All rights reserved.
//

#import "JBCloud.h"
#import "HttpRequestManager.h"

@implementation JBCloud

//云方法调用（同步）
+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error {
    
    id responseObject = [HttpRequestManager cloudWithFunName:function parameters:parameters error:error];
    if (error) {
        if (*error) {
            return nil;
        }
    }
    return responseObject;
}


//云方法调用（异步）
+ (void)callFunctionInBackground:(NSString *)function withParameters:(NSDictionary *)parameters block:(JBIdResultBlock)block {
    [HttpRequestManager cloudWithFunName:function parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        @try {
            if (responseObject) {
                int code = [[responseObject objectForKey:@"code"] intValue];
                if (code == 0) {
                    block(responseObject, nil);
                }else {
                    NSError *customError = [NSError errorWithDomain:[responseObject objectForKey:@"message"] code:code userInfo:responseObject];
                    block(responseObject, customError);
                }
            } else {
                block(responseObject, nil);
            }
        }
        @catch (NSException *exception) {

        }
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        }else {
            block(nil, error);
        }
    }];
}




@end
