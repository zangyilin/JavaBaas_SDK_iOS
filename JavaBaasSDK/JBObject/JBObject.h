//
//  JBObject.h
//  
//
//  Created by zhaopeng on 15/9/28.
//  Copyright © 2015年 zhaopeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JBACL.h"
#import "JBConstants.h"

@interface JBObject : NSObject

@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) JBACL *acl;



- (instancetype)initWithDictionary:(NSDictionary *)dictionay;


+ (instancetype)objectWithoutDataWithClassName:(NSString *)className
                                      objectId:(NSString *)objectId;

+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId;


+ (instancetype)objectWithClassName:(NSString *)className;


#pragma mark -
#pragma mark Save,fetch,delete

- (BOOL)save:(NSError **)error;


/**
 *  保存数据到服务器
 *
 *  @param block 服务器返回结果
 */
- (void)saveInBackgroundWithBlock:(JBBooleanResultBlock)block;


- (JBObject *)fetch:(NSError **)error;

- (void)fetchInBackgroundWithBlock:(JBObjectResultBlock)block;

- (BOOL)delete:(NSError **)error;

- (void)deleteInBackgroundWithBlock:(JBBooleanResultBlock)block;

#pragma mark -
#pragma mark Get and set
- (NSArray *)allKeys;

- (id)objectForKey:(NSString *)key;

- (void)setObject:(id)object forKey:(NSString *)key;

- (void)setValue:(id)value forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllObjects;
//获取josn数据
- (NSMutableDictionary *)dictionaryForObject;

+ (JBObject *)object;


#pragma mark -
#pragma mark 原子操作
- (void)incrementKey: (NSString *)key;

- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount;

- (void)removeKey:(NSString *)key;

- (void)addArray:(NSArray *)objects forKey:(NSString *)key;

- (void)addUniqueArray:(NSArray *)objects forKey:(NSString *)key;

- (void)removeArray:(NSArray *)objects forKey:(NSString *)key;

- (void)multiply:(NSString *)key byAmount:(NSNumber *)amount;

@end
