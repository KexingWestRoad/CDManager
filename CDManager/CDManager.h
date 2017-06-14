//
//  CDManager.h
//  CDManager
//
//  Created by 廖登科 on 17/6/13.
//  Copyright © 2017年 dengkel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDManager : NSObject

+ (void)initCDManagerWithModelName:(nonnull NSString *)modelName fileName:(nonnull NSString *)fileName;
+ (BOOL)addObject:(NSManagedObject *)object error:(NSError **)error;
+ (BOOL)saveObject:(NSError **)error;
+ (BOOL)deleteObject:(NSManagedObject *)object;
+ (BOOL)updateObject:(NSManagedObject *)object;
+ (nullable __kindof NSManagedObject *)searchObjectWithID:(NSManagedObjectID *)objectID;

+ (void)backgroundObjectSave;

//search
+ (NSMutableArray<NSManagedObject *> *)fetchAllRecordsWithModelClass:(Class)modelClass;

@end

@interface NSManagedObject (convert)
+ (nonnull __kindof NSManagedObject *)ConvertedObject;
@end

NS_ASSUME_NONNULL_END
