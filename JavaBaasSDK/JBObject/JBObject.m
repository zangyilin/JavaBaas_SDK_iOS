//
//  JBObject.m
//  LeanCloud_Test
//
//  Created by zhaopeng on 15/9/28.
//  Copyright © 2015年 zhaopeng. All rights reserved.
//

#import "JBObject.h"
#import <objc/runtime.h>
#import "JBInterface.h"
#import "HttpRequestManager.h"
#import "JBInterface.h"
#import "JBUser.h"
#import "JBResponse.h"

@implementation JBObject {
    NSMutableDictionary *_dictionary;
    NSMutableDictionary *_pointerDictionary;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionay {
    self = [super init];
    if (self) {
        if (dictionay) {
            _dictionary = nil;
            _dictionary = [[NSMutableDictionary alloc] initWithDictionary:dictionay];
            _createdAt = [self getDateWithTime:[[dictionay objectForKey:@"createdAt"] longLongValue]];
            _updatedAt = [self getDateWithTime:[[dictionay objectForKey:@"updatedAt"] longLongValue]];
            _objectId = [dictionay objectForKey:@"_id"];
            _className = [dictionay objectForKey:@"className"];
            NSDictionary *aclDictionary = [dictionay objectForKey:@"acl"];
            _acl = [JBACL ACL];
            _acl.aclDictionary = [NSMutableDictionary dictionaryWithDictionary:aclDictionary];
        }
        
    }
    return self;
}

- (void)setAcl:(JBACL *)acl {
    [self setObject:acl.aclDictionary forKey:@"acl"];
}

- (NSDate *)getDateWithTime:(long long)time {
    NSTimeInterval tempMilli = time;
    NSTimeInterval seconds = tempMilli/1000.0;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    return date;
}

+ (JBObject *)object {
    return [[JBObject alloc] init];
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _dictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)objectWithClassName:(NSString *)className {
    if (className) {
        JBObject *object = [[JBObject alloc] init];
        [object setValue:@"Pointer" forKey:@"__type"];
        object.className = className;
        return object;
    }
    return nil;
}


+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId {
    if (objectId) {
        JBObject *object = [[JBObject alloc] init];
        [object setValue:@"Pointer" forKey:@"__type"];
        [object setValue:objectId forKey:@"_id"];
        object.objectId = objectId;
        return object;
    }
    return nil;
}


+ (instancetype)objectWithoutDataWithClassName:(NSString *)className objectId:(NSString *)objectId {
    JBObject *object = [[JBObject alloc] init];
    object.className = className;
    [object setValue:@"Pointer" forKey:@"__type"];
    if (className && objectId) {
        [object setValue:objectId forKey:@"_id"];
        object.objectId = objectId;
        return object;
    }else {
        return object;
    }
}

- (void)setClassName:(NSString *)className {
    _className = className;
    if (className) {
        [_dictionary setObject:className forKey:@"className"];
    }
}

- (void)setObjectId:(NSString *)objectId {
    _objectId = objectId;
    if (_objectId) {
        [_dictionary setObject:objectId forKey:@"_id"];
    }
}


- (void)removeObjectForKey:(NSString *)key {
    [_dictionary removeObjectForKey:key];
}

- (BOOL)isIntType:(NSNumber *)amount {
    NSArray *intArray = @[@"i",@"s",@"l",@"q",@"I",@"S",@"L",@"Q"];
    NSString *intType = [NSString stringWithFormat:@"%s", amount.objCType];
    if ([intArray containsObject:intType]) {
        return YES;
    }
    return NO;
}

#pragma mark - set, get



- (NSArray *)allKeys {
    return [_dictionary allKeys];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (![value isKindOfClass:[JBObject class]]) {
        if ([value isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)value;
            [_dictionary setValue:@(date.timeIntervalSince1970*1000) forKey:key];
        }else {
            [_dictionary setValue:value forKey:key];
        }
    }else {
        NSDictionary *dict = [NSMutableDictionary dictionary];
        if ([[value objectForKey:@"__type"] isEqualToString:@"File"]) {
            [dict setValue:@"File" forKey:@"__type"];
            [dict setValue:[value objectForKey:@"_id"] forKey:@"_id"];
            [dict setValue:[value objectForKey:@"url"] forKey:@"url"];
        }else if ([[value objectForKey:@"__type"] isEqualToString:@"Pointer"]) {
            [dict setValue:@"Pointer" forKey:@"__type"];
            [dict setValue:[value objectForKey:@"className"] forKey:@"className"];
            [dict setValue:[value objectForKey:@"_id"] forKey:@"_id"];
        }else {
            dict = [value dictionaryForObject];
        }
        [_dictionary setValue:dict forKey:key];
    }
}

- (void)setObject:(id)object forKey:(NSString *)key {
    if (![object isKindOfClass:[JBObject class]]) {
        if ([object isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)object;
            [_dictionary setValue:@(date.timeIntervalSince1970*1000) forKey:key];
        }else {
            [_dictionary setValue:object forKey:key];
        }
    }else {
        NSDictionary *dict = [NSMutableDictionary dictionary];
        NSString *_id = [object objectForKey:@"_id"];
        if (_id) {
            if ([[object objectForKey:@"__type"] isEqualToString:@"File"]) {
                [dict setValue:@"File" forKey:@"__type"];
                [dict setValue:[object objectForKey:@"_id"] forKey:@"_id"];
            }else if ([[object objectForKey:@"__type"] isEqualToString:@"Pointer"]) {
                [dict setValue:@"Pointer" forKey:@"__type"];
                [dict setValue:[object objectForKey:@"className"] forKey:@"className"];
                [dict setValue:[object objectForKey:@"_id"] forKey:@"_id"];
            }
            [_dictionary setValue:dict forKey:key];
        }
    }
}

#pragma mark -
#pragma mark 原子操作
- (void)incrementKey: (NSString *)key {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Increment] forKey:@"__op"];
    [dic setValue:[NSNumber numberWithInteger:1] forKey:@"amount"];
    [self setObject:dic forKey:key];
}

- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Increment] forKey:@"__op"];
    [dic setValue:amount forKey:@"amount"];
    [self setObject:dic forKey:key];
}

- (void)removeKey:(NSString *)key {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Delete] forKey:@"__op"];
    [self setObject:dic forKey:key];
}

- (void)addArray:(NSArray *)objects forKey:(NSString *)key {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Add] forKey:@"__op"];
    [dic setValue:objects forKey:@"objects"];
    [self setObject:dic forKey:key];
}

- (void)addUniqueArray:(NSArray *)objects forKey:(NSString *)key {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_AddUnique] forKey:@"__op"];
    [dic setValue:objects forKey:@"objects"];
    [self setObject:dic forKey:key];
}

- (void)removeArray:(NSArray *)objects forKey:(NSString *)key {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Remove] forKey:@"__op"];
    [dic setValue:objects forKey:@"objects"];
    [self setObject:dic forKey:key];
}

- (void)multiply:(NSString *)key byAmount:(NSNumber *)amount {
    NSDictionary *dic = [NSDictionary dictionary];
    [dic setValue:[self getOperatorString:JBOperatorType_Multiply] forKey:@"__op"];
    [dic setValue:amount forKey:@"amount"];
    [self setObject:dic forKey:key];
}

- (NSString *)getOperatorString:(JBOperatorType)type {
    NSString *operatorString;
    switch (type) {
        case JBOperatorType_Delete:
            operatorString = @"Delete";
            break;
        case JBOperatorType_Add:
            operatorString = @"Add";
            break;
        case JBOperatorType_AddUnique:
            operatorString = @"AddUnique";
            break;
        case JBOperatorType_Remove:
            operatorString = @"Remove";
            break;
        case JBOperatorType_Increment:
            operatorString = @"Increment";
            break;
        default:
            operatorString = @"Multiply";
            break;
    }
    return operatorString;
}


- (NSMutableDictionary *)dictionaryForObject {
    return _dictionary;
}

- (void)removeAllObjects {
    [_dictionary removeAllObjects];
}

- (id)objectForKey:(NSString *)key {
    return [_dictionary objectForKey:key];
}


#pragma mark - save,fetch, delete

- (BOOL)save:(NSError *__autoreleasing *)error {
    
    if (!_className) {
        if (error) {
            *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        }
        return NO;
    }
    NSString *urlPath;
    if (_objectId) {
        urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className,@"_id":_objectId}];
        id responseObject = [HttpRequestManager synchronousWithMethod:@"PUT" urlString:urlPath parameters:_dictionary error:error];
        if (error) {
            if (*error) {
                return NO;
            }
        }
        if (responseObject) {
            JBResponse *response = [JBResponse initWithDictionary:responseObject];
            if (response.code == 0) {
                if ([_className isEqualToString:@"_User"]) {
                    JBUser *user = (JBUser *)self;
                    [JBUser changeCurrentUser:user save:YES];
                }
                return YES;
            } else {
                if (error) {
                    *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
                }
            }
        }
        return NO;
    }else {
        urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className}];
        id responseObject = [HttpRequestManager synchronousWithMethod:@"POST" urlString:urlPath parameters:_dictionary error:error];
        if (error) {
            if (*error) {
                return NO;
            }
        }
        if (responseObject) {
            JBResponse *response = [JBResponse initWithDictionary:responseObject];
            if (response.code == 0) {
                NSDictionary *dictionary = response.data;
                if (dictionary) {
                    self.objectId = [dictionary objectForKey:@"_id"];
                }
                return YES;
            } else {
                if (error) {
                    *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
                }
            }
        }
        return NO;
    }
}

- (void)saveInBackgroundWithBlock:(JBBooleanResultBlock)block {
    if (!_className) {
        NSError *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        block(NO, error);
        return ;
    }
    NSString *urlPath;
    if (_objectId) {
        //更新
        urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className, @"_id":_objectId}];
        [HttpRequestManager updateObjectWithUrlPath:urlPath parameters:_dictionary success:^(NSURLSessionDataTask *task, id responseObject) {
            if ([_className isEqualToString:@"_User"]) {
                JBUser *user = (JBUser *)self;
                [JBUser changeCurrentUser:user save:YES];
            }
            block(YES, nil);
        } failure:^(JBResponse *jbResponse, NSError *error) {
            if (jbResponse) {
                NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
                block(NO, customError);
            }else {
                block(NO, error);
            }
        }];
    }else {
        urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className}];
        [HttpRequestManager postObjectWithoutDataWithUrlPath:urlPath parameters:_dictionary success:^(NSURLSessionDataTask *task, id responseObject) {
            JBResponse *response = [JBResponse initWithDictionary:responseObject];
            if (response.data != nil) {
                self.objectId = [response.data objectForKey:@"_id"];
            }
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
}

- (JBObject *)fetch:(NSError *__autoreleasing *)error {
    if (!_objectId) {
        if (error) {
            *error = [NSError errorWithDomain:@"without id" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without id"}];
        }
        return nil;
    }
    
    if (!_className) {
        if (error) {
            *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        }
        return nil;
    }
    NSString *urlPath = [NSString stringWithFormat:@"object/%@/%@", _className, _objectId];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"GET" urlString:urlPath parameters:_dictionary error:error];
    if (error) {
        if (*error) {
            return nil;
        }
    }
    if (responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        if (response.code) {
            return [[JBObject alloc] initWithDictionary:response.data];
        } else {
            if (error) {
                *error = [NSError errorWithDomain:response.message code:response.code userInfo:@{NSLocalizedDescriptionKey:response.message}];
            }
        }
    }
    return nil;
}

- (void)fetchInBackgroundWithBlock:(JBObjectResultBlock)block {
    if (!_objectId) {
        NSError *error = [NSError errorWithDomain:@"without id" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without id"}];
        block(nil, error);
        return;
    }
    if (!_className) {
        NSError *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        block(nil, error);
        return;
    }
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className, @"_id":_objectId}];
    [HttpRequestManager getObjectWithUrlPath:urlPath parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        JBResponse *response = [JBResponse initWithDictionary:responseObject];
        JBObject *object = [[JBObject alloc] initWithDictionary:response.data];
        block(object, nil);
    } failure:^(JBResponse *jbResponse, NSError *error) {
        if (jbResponse) {
            NSError *customError = [NSError errorWithDomain:jbResponse.message code:jbResponse.code userInfo:@{NSLocalizedDescriptionKey: jbResponse.message}];
            block(nil, customError);
        }else {
            block(nil, error);
        }
    }];
}

- (BOOL)delete:(NSError *__autoreleasing *)error {
    if (!_objectId) {
        if (error) {
            *error = [NSError errorWithDomain:@"without id" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without id"}];
        }
        
        return NO;
    }
    if (!_className) {
        if (error) {
            *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        }
        
        return NO;
    }
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className, @"_id":_objectId}];
    id responseObject = [HttpRequestManager synchronousWithMethod:@"DELETE" urlString:urlPath parameters:_dictionary error:error];
    if (error) {
        if (*error) {
            return NO;
        }
    }
    if (responseObject) {
        int code = [[responseObject objectForKey:@"code"] intValue];
        NSString *message = [responseObject objectForKey:@"message"];
        if (code != 0 && message) {
            if (error) {
                *error = [NSError errorWithDomain:message code:code userInfo:@{NSLocalizedDescriptionKey:message}];
            }
            return NO;
        }
        return YES;
    }else {
        return YES;
    }
}

- (void)deleteInBackgroundWithBlock:(JBBooleanResultBlock)block {
    if (!_objectId) {
        NSError *error = [NSError errorWithDomain:@"without id" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without id"}];
        block(NO, error);
        return;
    }
    
    if (!_className) {
        NSError *error = [NSError errorWithDomain:@"without className" code:JBError_NO_CLASSNAME userInfo:@{NSLocalizedDescriptionKey:@"without className"}];
        block(NO, error);
        return;
    }
    NSString *urlPath = [JBInterface getInterfaceWithParam:@{@"className":_className, @"_id":_objectId}];
    [HttpRequestManager deleteObjectWithUrlPath:urlPath queryParam:nil success:^(NSURLSessionDataTask *task, id responseObject) {
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
@end






