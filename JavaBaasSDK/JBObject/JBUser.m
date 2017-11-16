//
//  JBUser.m
//  LeanCloud_Test
//
//  Created by zhaopeng on 15/9/29.
//  Copyright © 2015年 zhaopeng. All rights reserved.
//

#import "JBUser.h"
#import "JBInterface.h"
#import "HttpRequestManager.h"
#import "JBCacheManager.h"
#import "JBResponse.h"
#import "JBOSCloud.h"

@implementation JBUser

static JBUser  *_user;

+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId {
    JBUser *object = [[JBUser alloc] init];
    object.objectId = objectId;
    [object setValue:@"Pointer" forKey:@"__type"];
    [object setValue:objectId forKey:@"_id"];
    object.className = @"_User";
    return object;
}


- (void)setSessionToken:(NSString *)sessionToken {
    _sessionToken = sessionToken;
    if (sessionToken) {
        [self setObject:sessionToken forKey:@"sessionToken"];
    }
}


- (void)setUsername:(NSString *)username {
    _username = username;
    if (username) {
        [self setObject:username forKey:@"username"];
    }
}

- (void)setPassword:(NSString *)password {
    _password = password;
    if (password) {
        [self setObject:password forKey:@"password"];
    }
}

- (void)setPhone:(NSString *)phone {
    _phone = phone;
    if (phone) {
        [self setObject:phone forKey:@"phone"];
    }
}


- (void)setEmail:(NSString *)email {
    _email = email;
    if (email) {
        [self setObject:email forKey:@"email"];
    }
}

- (void)setAuth:(NSDictionary *)auth {
    _auth = auth;
    if (auth) {
        [self setObject:auth forKey:@"auth"];
    }
}

+ (JBUser *)user {
    JBUser *user = [[JBUser alloc] init];
    user.className = @"_User";
    return user;
}

//注册
- (BOOL)signUp:(NSError *__autoreleasing *)error {
    NSString *urlString = [JBInterface getInterfaceWithParam:@{@"className":@"_User"}];
    NSDictionary *parameters = [self dictionaryForObject];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"POST" urlString:urlString parameters:parameters error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            [self setValue:[response.data objectForKey:@"sessionToken"] forKey:@"sessionToken"];
            [self setValue:[response.data objectForKey:@"_id"] forKey:@"_id"];
            [self setValue:[response.data objectForKey:@"createdAt"] forKey:@"createdAt"];
            
            [JBUser changeCurrentUser:self save:YES];
            return YES;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return NO;
}

- (void)signUpInBackgroundWithBlock:(JBBooleanResultBlock)block {
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"className":@"_User"}];
    NSDictionary *parameters = [self dictionaryForObject];
    [HttpRequestManager postObjectWithoutDataWithUrlPath:urlPath parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        [self setValue:[response.data objectForKey:@"sessionToken"] forKey:@"sessionToken"];
        [self setValue:[response.data objectForKey:@"_id"] forKey:@"_id"];
        [self setValue:[response.data objectForKey:@"createdAt"] forKey:@"createdAt"];
        [JBUser changeCurrentUser:self save:YES];
        block(YES, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            int code = jbResponse.code;
            if (code == 2010) {
                code = JBError_NICKNAME_ALREADY_EXIST;
            }
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(NO, customError);
        }else {
            block(NO, error);
        }
    }];
}

//修改密码
- (BOOL)updatePassword:(NSString *)password newPassword:(NSString *)newPassword error:(NSError *__autoreleasing *)error {
    if (!self.objectId) {
        if (error) {
            *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        }
        return NO;
    }
    NSString *urlString = [NSString stringWithFormat:@"user/%@/updatePassword", self.objectId];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:newPassword forKey:@"newPassword"];
    [parameters setObject:password forKey:@"oldPassword"];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"PUT" urlString:urlString parameters:parameters error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            NSString *sessionToken = [response.data objectForKey:@"sessionToken"];
            [self setObject:sessionToken forKey:@"sessionToken"];
            [JBUser changeCurrentUser:self save:YES];
            return YES;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey: response.message}];
            }
        }
    }
    return NO;
}

- (void)updatePassword:(NSString *)password newPassword:(NSString *)newPassword block:(JBBooleanResultBlock)block {
    if (!self.objectId) {
        NSError *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        block(NO, error);
        return ;
    }
    NSString *urlString = [NSString stringWithFormat:@"user/%@/updatePassword", self.objectId];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:newPassword forKey:@"newPassword"];
    [parameters setObject:password forKey:@"oldPassword"];

    [HttpRequestManager updateObjectWithUrlPath:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        NSString *sessionToken = [response.data objectForKey:@"sessionToken"];
        [self setObject:sessionToken forKey:@"sessionToken"];
        [JBUser changeCurrentUser:self save:YES];
        block(YES, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            int code = jbResponse.code;
            if (code == 2010) {
                code = JBError_NICKNAME_ALREADY_EXIST;
            }
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(NO, customError);
        }else {
            block(NO, error);
        }
    }];
}

//登录:(用户名和密码)
+ (id)loginWithUsername:(NSString *)username password:(NSString *)password error:(NSError *__autoreleasing *)error {
    NSString *urlString = [NSString stringWithFormat:@"user/login?username=%@&password=%@",username, password];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"GET" urlString:urlString parameters:nil error:error];
    if (error) {
        if (*error) {
            return nil;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            JBUser *user = [[JBUser alloc] initWithDictionary:response.data];
            [JBUser changeCurrentUser:user save:YES];
            return user;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey: response.message}];
            }
        }
    }
    return nil;
}


+ (void)loginWithUsernameInBackground:(NSString *)username password:(NSString *)password block:(JBUserResultBlock)block {
    NSString *baseUrl = [JBOSCloud getBaseUrlString];
    NSString *urlString = [NSString stringWithFormat:@"%@/api/user/login?username=%@&password=%@",baseUrl,username, password];
    [HttpRequestManager getObjectWithUrlString:urlString success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        JBUser *user = [[JBUser alloc] initWithDictionary: response.data];
        [JBUser changeCurrentUser:user save:YES];
        block(user, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        } else {
            block(nil, error);
        }
    }];
}

+ (id)loginWithPhone:(NSString *)phone code:(NSString *)code error:(NSError **)error {
    NSString *urlString = @"user/loginWithPhone";
    id responseObject = [HttpRequestManager synchronousWithMethod:@"POST" urlString:urlString parameters:@{@"phone": phone, @"code": code} error:error];
    if (error) {
        if (*error) {
            return nil;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            JBUser *user = [[JBUser alloc] initWithDictionary:response.data];
            return user;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return nil;
}

+ (void)loginWithPhoneInBackground:(NSString *)phone code:(NSString *)code block:(JBUserResultBlock)block {
    NSString *urlString = @"user/loginWithPhone";
    [HttpRequestManager postObjectWithoutDataWithUrlPath:urlString parameters:@{@"phone": phone, @"code": code} success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        JBUser *user = [[JBUser alloc] initWithDictionary:response.data];
        [JBUser changeCurrentUser:user save:YES];
        block(user, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        } else {
            block(nil, error);
        }
    }];
}

+ (BOOL)getSmsCode:(NSString *)phone error:(NSError **)error {
    NSString *urlString = [NSString stringWithFormat:@"user/getSmsCode/%@", phone];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"GET" urlString:urlString parameters:nil error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            return YES;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey: response.message}];
            }
        }
    }
    return NO;
}

+ (void)getSmsCodeInBackground:(NSString *)phone block:(JBBooleanResultBlock)block {
    NSString *urlString = [NSString stringWithFormat:@"user/getSmsCode/%@", phone];
    [HttpRequestManager getObjectWithUrlString:urlString success:^(NSURLSessionDataTask *task, id responseObject) {
        block(YES, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(NO, customError);
        }else {
            block(NO, error);
        }
    }];
}

//第三方登录
+ (id)loginWithAuthData:(NSDictionary *)auth authType:(JBPlatform)platform error:(NSError *__autoreleasing *)error {
    int plat = [self getPlatform:platform];
    NSString *urlString = [NSString stringWithFormat:@"user/loginWithSns/%d" ,plat];
    NSString *token = [auth objectForKey:@"accessToken"];
    NSString *uid = [auth objectForKey:@"uid"];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"POST" urlString:urlString parameters:@{@"accessToken":token, @"uid":uid} error:error];
    if (error) {
        if (*error) {
            return nil;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            JBUser *user = [[JBUser alloc] initWithDictionary:response.data];
            return user;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return nil;
}


+ (void)loginWithAuthDataInBackground:(NSDictionary *)auth authType:(JBPlatform)platform block:(JBUserResultBlock)block {
    int plat = [self getPlatform:platform];
    NSString *path = [NSString stringWithFormat:@"user/loginWithSns/%d" ,plat];
  
    [HttpRequestManager postObjectWithoutDataWithUrlPath:path parameters:auth success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        JBUser *user = [[JBUser alloc] initWithDictionary:response.data];
        [JBUser changeCurrentUser:user save:YES];
        block(user, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        }else {
            block(nil, error);
        }
    }];
}


//绑定
- (BOOL)addAuthData:(NSDictionary *)auth platform:(JBPlatform)platform error:(NSError *__autoreleasing *)error {
    if (!self.objectId) {
        if (error) {
            *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        }
        return NO;
    }
    int plat = [self getPlatform:platform];
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"authType":@"binding", @"_id":self.objectId,@"platform":[NSNumber numberWithInt:plat]}];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"POST" urlString:urlPath parameters:auth error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            NSMutableDictionary *authDict ;
            NSDictionary *dict = [self objectForKey:@"auth"];
            if (dict) {
                authDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            }else {
                authDict = [NSMutableDictionary dictionary];
            }
            NSString *plat = [self getPlatformString:platform];
            
            [authDict setValue:auth forKey:plat];
            [self setObject:authDict forKey:@"auth"];
            
            [JBUser changeCurrentUser:self save:YES];
            return YES;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return NO;
}

- (void)addAuthDataInBackground:(NSDictionary *)auth platform:(JBPlatform)platform block:(JBIdResultBlock)block {
    if (!self.objectId) {
        NSError *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        block(nil, error);
        return ;
    }
    int plat = [self getPlatform:platform];
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"authType":@"binding", @"_id":self.objectId,@"platform":[NSNumber numberWithInt:plat]}];
    
    [HttpRequestManager postObjectWithUrlString:urlPath parameters:auth success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableDictionary *authDict ;
        NSDictionary *dict = [self objectForKey:@"auth"];
        if (dict) {
            authDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        }else {
            authDict = [NSMutableDictionary dictionary];
        }
        NSString *plat = [self getPlatformString:platform];
        
        [authDict setValue:auth forKey:plat];
        [self setObject:authDict forKey:@"auth"];
        
        [JBUser changeCurrentUser:self save:YES];
        block(responseObject, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        }else {
            block(nil, error);
        }
    }];
}

//解绑
- (BOOL)deleteAuthDataForPlatform:(JBPlatform)platform error:(NSError *__autoreleasing *)error {
    if (!self.objectId) {
        if (error) {
            *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        }
        return NO;
    }
    int plat = [self getPlatform:platform];
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"authType":@"release", @"_id":self.objectId,@"platform":[NSNumber numberWithInt:plat]}];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"DELETE" urlString:urlPath parameters:nil error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code == 0) {
            NSMutableDictionary *authDict ;
            NSDictionary *dict = [self objectForKey:@"auth"];
            if (dict) {
                authDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            }else {
                authDict = [NSMutableDictionary dictionary];
            }
            NSString *plat = [self getPlatformString:platform];
            
            [authDict removeObjectForKey:plat];
            [self setObject:authDict forKey:@"auth"];
            [JBUser changeCurrentUser:self save:YES];
            return YES;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return NO;
}

- (void)deleteAuthDataForPlatformInBackground:(JBPlatform)platform block:(JBBooleanResultBlock)block {
    if (!self.objectId) {
        NSError *error = [NSError errorWithDomain:@"without user id" code:JBError_NO_USER userInfo:@{NSLocalizedDescriptionKey:@"without user id"}];
        block(NO, error);
        return ;
    }
    int plat = [self getPlatform:platform];
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"authType":@"release", @"_id":self.objectId,@"platform":[NSNumber numberWithInt:plat]}];
    [HttpRequestManager deleteObjectWithUrlPath:urlPath queryParam:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSMutableDictionary *authDict ;
        NSDictionary *dict = [self objectForKey:@"auth"];
        if (dict) {
            authDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        }else {
            authDict = [NSMutableDictionary dictionary];
        }
        NSString *plat = [self getPlatformString:platform];
        
        [authDict removeObjectForKey:plat];
        [self setObject:authDict forKey:@"auth"];
        
        
        [JBUser changeCurrentUser:self save:YES];
        block(YES, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        }else {
            block(nil, error);
        }
    }];
}


+ (BOOL)logout {
    _user = nil;
    return [[JBCacheManager sharedJBCacheManager] clearJBUserCacheFile];
}


+ (void)changeCurrentUser:(JBUser *)newUser save:(BOOL)save {
    if (save && newUser) {
        [[JBCacheManager sharedJBCacheManager] writeJBUserCacheFile:[newUser dictionaryForObject]];
        newUser.objectId = [newUser objectForKey:@"_id"];
        newUser.sessionToken = [newUser objectForKey:@"sessionToken"];
        newUser.password = [newUser objectForKey:@"password"];
        newUser.phone = [newUser objectForKey:@"phone"];
        newUser.email = [newUser objectForKey:@"email"];
        if ([newUser objectForKey:@"auth"]) {
            newUser.auth = [newUser objectForKey:@"auth"];
        }
        _user = newUser;
    }else if (save && newUser == nil) {
        [[JBCacheManager sharedJBCacheManager] clearJBUserCacheFile];
    }
}

+ (JBUser *)currentUser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _user = [[JBCacheManager sharedJBCacheManager] readJBUserCacheFile];
    });
    if (_user) {
        _user.className = @"_User";
    }
    return _user;
}

+ (int)getPlatform:(JBPlatform)platform {
    int plat;
    if (platform == JBPlatformSinaWeibo) {
        plat = 1;
    } else if (platform == JBPlatformQQ) {
        plat =2;
    }else if (platform == JBPlatformWeixin) {
        plat = 3;
    } else {
        plat = 0;
    }
    return  plat;
}

- (int)getPlatform:(JBPlatform)platform {
    int plat;
    if (platform == JBPlatformSinaWeibo) {
        plat = 1;
    } else if (platform == JBPlatformQQ) {
        plat =2;
    }else if (platform == JBPlatformWeixin) {
        plat = 3;
    } else {
        plat = 0;
    }
    return  plat;
}

- (NSString *)getPlatformString:(JBPlatform)platform {
    NSString *plat;
    if (platform == JBPlatformSinaWeibo) {
        plat = @"weibo";
    } else if (platform == JBPlatformQQ) {
        plat = @"qq";
    }else if (platform == JBPlatformWeixin) {
        plat = @"weixin";
    }
    return  plat;
}

@end
