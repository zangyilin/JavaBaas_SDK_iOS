//
//  HttpRequestManager.m
//  LeanCloud_Test
//
//  Created by zhaopeng on 15/9/23.
//  Copyright © 2015年 zhaopeng. All rights reserved.
//

#import "HttpRequestManager.h"
#import "JBCacheManager.h" 
#import "JBOSCloud.h"
#import "NSString+MD5Digest.h"
#import "JBUser.h"

@implementation HttpRequestManager


+ (void)postObjectWithoutDataWithUrlPath:(NSString *)urlPath parameters:(NSDictionary *)parameters
                                   success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                   failure:(void (^)(JBResponse *jbResponse, NSError *error))failure {
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    //    unix时间戳  精确到毫秒
    NSString *urlString = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlPath];
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    //发送请求
    [manager POST:string parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
        [self checkSessionToken:resp];
        failure(resp, error);
    }];
}


+ (void)getObjectWithUrlPath:(NSString *)urlPath parameters:(NSMutableDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(JBResponse *jbResponse, NSError *error))failure {
    
    kJBCachePolicyCache cachePolicy = [[parameters objectForKey:@"JBCachePolicy"] intValue];
    [parameters removeObjectForKey:@"JBCachePolicy"];
    
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keyArray = [parameters allKeys];
    for (int i=0; i<keyArray.count; i++) {
        NSString *keyString = [keyArray objectAtIndex:i];
        NSString *valueString = [parameters objectForKey:keyString];
        [paramString appendString:[NSString stringWithFormat:@"%@=%@",keyString,valueString]];
        if (i != keyArray.count-1) {
            [paramString appendString:@"&"];
        }
    }
    
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    
    NSString *urlString;
    
    if (paramString.length) {
        urlString = [NSString stringWithFormat:@"%@/api/%@?%@", baseUrl, urlPath, paramString];
    }else {
        urlString = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlPath];
    }
    
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];;
    
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    
    if (cachePolicy == kJBCachePolicyIgnoreCache) {
        [manager GET:string parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure([JBResponse initWithDictionary:[self getErrorResponse:error]], error);
        }];
    }else if (cachePolicy == kJBCachePolicyCacheOnly) {
        [[JBCacheManager sharedJBCacheManager] readCacheFileAtPath:urlString block:^(NSArray *objects, NSError *error) {
            success(nil, objects);
        }];
    }else if (cachePolicy == kJBCachePolicyCacheThenNetwork) {
        [[JBCacheManager sharedJBCacheManager] readCacheFileAtPath:urlString block:^(NSArray *objects, NSError *error) {
            success(nil, objects);
            [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                success(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                failure([JBResponse initWithDictionary:[self getErrorResponse:error]], error);
            }];
        }];
    }else {
        [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure([JBResponse initWithDictionary:[self getErrorResponse:error]], error);
        }];
    }
}

//put方法 更新对象
+ (void)updateObjectWithUrlPath:(NSString *)urlPath parameters:(NSDictionary *)dict
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(JBResponse *jbResponse, NSError *error))failure {
    
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlPath];
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    [manager PUT:string parameters:dict success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
        [self checkSessionToken:resp];
        failure(resp, error);
    }];
}




//get方法 获取类对象
+ (void)queryObjectWithUrlPath:(NSString *)urlPath queryParam:(NSMutableDictionary *)queryDict
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(JBResponse *jbResponse, NSError *error))failure{
    
    kJBCachePolicyCache cachePolicy = [[queryDict objectForKey:@"JBCachePolicy"] intValue];
    [queryDict removeObjectForKey:@"JBCachePolicy"];
    
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keyArray = [queryDict allKeys];
    for (int i=0; i<keyArray.count; i++) {
        NSString *keyString = [keyArray objectAtIndex:i];
        NSString *valueString = [queryDict objectForKey:keyString];
        [paramString appendString:[NSString stringWithFormat:@"%@=%@",keyString,valueString]];
        if (i != keyArray.count-1) {
            [paramString appendString:@"&"];
        }
    }

    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString;
    
    if (paramString.length) {
        urlString = [NSString stringWithFormat:@"%@/api/%@?%@", baseUrl, urlPath, paramString];
    }else {
        urlString = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlPath];
    }
    
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    if (cachePolicy == kJBCachePolicyIgnoreCache) {
        [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
            [self checkSessionToken:resp];
            failure(resp, error);
        }];
        
    } else if (cachePolicy == kJBCachePolicyCacheOnly) {
        [[JBCacheManager sharedJBCacheManager] readCacheFileAtPath:urlString block:^(NSArray *objects, NSError *error) {
            if (objects.count) {
                success(nil, objects);
            }else {
                success(nil, nil);
            }
        }];
    }else if (cachePolicy == kJBCachePolicyCacheThenNetwork) {
        [[JBCacheManager sharedJBCacheManager] readCacheFileAtPath:urlString block:^(NSArray *objects, NSError *error) {
            success(nil, objects);
            [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                success(task, responseObject);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
                [self checkSessionToken:resp];
                failure(resp, error);
            }];
        }];
    }else {
        [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(task, responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
            [self checkSessionToken:resp];
            failure(resp, error);
        }];
    }
}


+ (void)deleteObjectWithUrlPath:(NSString *)urlPath queryParam:(NSMutableDictionary *)queryDict
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(JBResponse *jbResponse, NSError *error))failure{
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keyArray = [queryDict allKeys];
    for (int i=0; i<keyArray.count; i++) {
        NSString *keyString = [keyArray objectAtIndex:i];
        NSString *valueString = [queryDict objectForKey:keyString];
        [paramString appendString:[NSString stringWithFormat:@"%@=%@",keyString,valueString]];
        if (i != keyArray.count-1) {
            [paramString appendString:@"&"];
        }
    }
    
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString;
    
    if (paramString.length) {
        urlString = [NSString stringWithFormat:@"%@/api/%@?%@", baseUrl, urlPath, paramString];
    }else {
        urlString = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlPath];
    }
    
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    [manager DELETE:string parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
        [self checkSessionToken:resp];
        failure(resp, error);
    }];
}


//post方法 创建一个对象

+ (void)postObjectWithUrlString:(NSString *)urlString parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(JBResponse *jbResponse, NSError *error))failure {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //发送请求
    [manager POST:string parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure([JBResponse initWithDictionary:[self getErrorResponse:error]], error);
    }];
}



+ (void)getObjectWithUrlString:(NSString *)urlString
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(JBResponse *jbResponse, NSError *error))failure {
    //    unix时间戳  精确到毫秒
    
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    //发送请求
    [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
        [self checkSessionToken:resp];
        failure(resp, error);
    }];
}


+ (void)cloudWithFunName:(NSString *)funName parameters:(NSDictionary *)parameters success:(void (^)(NSURLSessionDataTask *task, id))success failure:(void (^)(JBResponse *, NSError *error))failure {
    
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keyArray = [parameters allKeys];
    for (int i=0; i<keyArray.count; i++) {
        NSString *keyString = [keyArray objectAtIndex:i];
        NSString *valueString = [parameters objectForKey:keyString];
        [paramString appendString:[NSString stringWithFormat:@"%@=%@",keyString,valueString]];
        if (i != keyArray.count-1) {
            [paramString appendString:@"&"];
        }
    }
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/cloud/%@?%@",baseUrl,funName,paramString];
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [self setHttpHearderWithHttpRequestOperationManager:manager];
    
    //发送请求
    [manager GET:string parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        JBResponse *resp = [JBResponse initWithDictionary:[self getErrorResponse:error]];
        [self checkSessionToken:resp];
        failure(resp, error);
    }];
}


+ (id)cloudWithFunName:(NSString *)funName parameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error {
    NSMutableString *paramString = [NSMutableString string];
    NSArray *keyArray = [parameters allKeys];
    for (int i=0; i<keyArray.count; i++) {
        NSString *keyString = [keyArray objectAtIndex:i];
        NSString *valueString = [parameters objectForKey:keyString];
        [paramString appendString:[NSString stringWithFormat:@"%@=%@",keyString,valueString]];
        if (i != keyArray.count-1) {
            [paramString appendString:@"&"];
        }
    }
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/cloud/%@?%@",baseUrl,funName,paramString];
    NSString *string = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [self synchronousWithMethod:@"GET" urlString:string parameters:nil error:error];
}



//同步方法
+ (id)synchronousWithMethod:(NSString *)method urlString:(NSString *)urlString parameters:(NSDictionary *)parameters error:(NSError **)error {
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *url = [NSString stringWithFormat:@"%@/api/%@", baseUrl, urlString];
    NSString *string = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
    
    //使用https
    AFSecurityPolicy *security = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    //不检验证书
    security.allowInvalidCertificates = YES;
    //不信任主机
    security.validatesDomainName = NO;
    manager.securityPolicy = security;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    NSString *appId = [JBOSCloud getApplicationId];
    NSString *clientKey = [JBOSCloud getClientKey];
    NSString *tempTime = [self getUnixDate];
    NSString *nonce = [[NSUUID UUID] UUIDString];
    NSString *source = [NSString stringWithFormat:@"%@:%@:%@",clientKey, tempTime, nonce];
    NSString *md5String = [source MD5HexDigest];
    [request setValue:tempTime forHTTPHeaderField:@"JB-Timestamp"];
    [request setValue:appId forHTTPHeaderField:@"JB-AppId"];
    [request setValue:md5String forHTTPHeaderField:@"JB-Sign"];
    [request setValue:nonce forHTTPHeaderField:@"JB-Nonce"];
    [request setValue:@"ios" forHTTPHeaderField:@"JB-Plat"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    JBUser *currentUser = [JBUser currentUser];
    if (currentUser.sessionToken && ![currentUser.sessionToken isEqualToString:@""]) {
        [request setValue:currentUser.sessionToken forHTTPHeaderField:@"JB-SessionToken"];
    }
    NSURLSession *session = [NSURLSession sharedSession];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block NSDictionary * dict;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable taskData, NSURLResponse * _Nullable response, NSError * _Nullable taskError) {
        if (taskError) {
            *error = [NSError errorWithDomain:@"网络链接失败" code:JBError_INTERNET_ERROR userInfo:@{NSLocalizedDescriptionKey:@"网络链接失败"}];
        } else {
            dict = [NSJSONSerialization JSONObjectWithData:taskData options:(NSJSONReadingMutableLeaves) error:nil];
            dispatch_semaphore_signal(sem);
        }
    }];
    [task resume];
    dispatch_semaphore_wait(sem,DISPATCH_TIME_FOREVER);
    return dict;
}


+ (void)setHttpHearderWithHttpRequestOperationManager:(AFHTTPSessionManager *)manager {
    //使用https
    AFSecurityPolicy *security = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    //不检验证书
    security.allowInvalidCertificates = YES;
    //不信任主机
    security.validatesDomainName = NO;
    manager.securityPolicy = security;
    
    //申明返回的结果是json类型
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    //申明请求的数据是json类型
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *appId = [JBOSCloud getApplicationId];
    NSString *clientKey = [JBOSCloud getClientKey];
    NSString *tempTime = [self getUnixDate];
    NSString *nonce = [[NSUUID UUID] UUIDString];
    NSString *source = [NSString stringWithFormat:@"%@:%@:%@",clientKey, tempTime, nonce];
    NSString *md5String = [source MD5HexDigest];
    [ manager.requestSerializer setValue:tempTime forHTTPHeaderField:@"JB-Timestamp"];
    [ manager.requestSerializer setValue:appId forHTTPHeaderField:@"JB-AppId"];
    [ manager.requestSerializer setValue:md5String forHTTPHeaderField:@"JB-Sign"];
    [ manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"JB-Plat"];
    [ manager.requestSerializer setValue:nonce forHTTPHeaderField:@"JB-Nonce"];
    [ manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    JBUser *currentUser = [JBUser currentUser];
    if (currentUser.sessionToken && ![currentUser.sessionToken isEqualToString:@""]) {
        [manager.requestSerializer setValue:currentUser.sessionToken forHTTPHeaderField:@"JB-SessionToken"];
    }
}

+ (void)checkSessionToken:(JBResponse *)response {
    if (response && response.code == 1310) {
        [JBUser logout];
    }
}


//HTTPS
+ (AFSecurityPolicy*)customSecurityPolicy {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    [securityPolicy setAllowInvalidCertificates:YES];
    return securityPolicy;
}

+ (NSDictionary *)getErrorResponse:(NSError *)error {
    NSString *jsonString = nil;
    NSDictionary *userinfo = [[NSDictionary alloc] initWithDictionary:error.userInfo];
    if(userinfo) {
        NSError *innerError = [userinfo valueForKey:@"NSUnderlyingError"];
        if(innerError) {
            NSDictionary *innerUserInfo = [[NSDictionary alloc] initWithDictionary:innerError.userInfo];
            if (innerUserInfo) {
                if([innerUserInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey]) {
                    jsonString = [[NSString alloc] initWithData:[innerUserInfo objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                }
            }
        } else {
            jsonString = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];

        }
    }
    
    if (jsonString != nil && ![jsonString isEqualToString:@""]) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&err];
        return dic;
    } else {
        return nil;
    }
}

/**
 *  时间戳校验
 *
 *  @return 相对服务器的时间戳
 */
+ (NSString *)getUnixDate {
    NSTimeInterval time=[[NSDate date] timeIntervalSince1970];
    time *= 1000;
    NSString *serverTime = [JBCacheManager readJBServerTime];
    long long dValue = 0;
    if (serverTime) {
        dValue = serverTime.longLongValue;
    }
    long long int currentTime=(long long int)time+dValue;
    NSString *tempTime = [NSString stringWithFormat:@"%lld",currentTime];
    return tempTime;
}


@end



























