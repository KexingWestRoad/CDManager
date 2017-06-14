//
//  CDManager.m
//  CDManager
//
//  Created by 廖登科 on 17/6/13.
//  Copyright © 2017年 dengkel. All rights reserved.
//

#import "CDManager.h"

@interface CDManager ()
@property(nonatomic,strong)NSManagedObjectContext *bgObjectContext;
@property(nonatomic,strong)NSManagedObjectContext *mainObjectContext;
@property(nonatomic,strong)NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(nonatomic,copy)NSString *modelName,*fileName;
@end

@implementation CDManager

static CDManager *cdManager_;
+ (CDManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        cdManager_ = [[CDManager alloc] init];
    });
    return cdManager_;
}

+ (void)initCDManagerWithModelName:(NSString *)modelName fileName:(NSString *)fileName {
    [CDManager sharedManager].modelName = modelName;
    [CDManager sharedManager].fileName = fileName;
}

- (NSManagedObjectContext *)bgObjectContext {
    if (!_bgObjectContext) {
        _bgObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_bgObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return _bgObjectContext;
}

- (NSManagedObjectContext *)mainObjectContext {
    if (!_mainObjectContext) {
        _mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainObjectContext setParentContext:self.bgObjectContext];
    }
    return _mainObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    NSError *error = nil;
    if (!_persistentStoreCoordinator) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[[self applicationDocumentsDirectory] URLByAppendingPathComponent:_fileName] options:options error:&error];
    }
    return _persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    NSManagedObjectModel *managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

+ (BOOL)addObject:(NSManagedObject *)object error:(NSError **)error {
    __block BOOL success = YES;
    NSError *outer_error;
    if ([[CDManager sharedManager].mainObjectContext hasChanges]) {
        if ([[CDManager sharedManager].mainObjectContext save:&outer_error]) {
            [[CDManager sharedManager].bgObjectContext performBlock:^{
                __block NSError *inner_error = nil;
                if ([[CDManager sharedManager].bgObjectContext save:&inner_error]) {
                    [[CDManager sharedManager].mainObjectContext performBlock:^{
                        success = YES;
                    }];
                } else
                    success = NO;
            }];
        } else
            success = NO;
    }
    return success;
}

+ (BOOL)saveObject:(NSError * _Nullable __autoreleasing *)error {
    __block BOOL success = YES;
    NSError *outer_error;
    if ([[CDManager sharedManager].mainObjectContext hasChanges]) {
        if ([[CDManager sharedManager].mainObjectContext save:&outer_error]) {
            [[CDManager sharedManager].bgObjectContext performBlock:^{
                __block NSError *inner_error = nil;
                if ([[CDManager sharedManager].bgObjectContext save:&inner_error]) {
                    [[CDManager sharedManager].mainObjectContext performBlock:^{
                        success = YES;
                    }];
                } else
                    success = NO;
            }];
        } else
            success = NO;
    }
    return success;
}

+ (BOOL)deleteObject:(NSManagedObject *)object {
    [[CDManager sharedManager].mainObjectContext deleteObject:object];
    BOOL success = [self mainObjectChanged];
    return success;
}

+ (BOOL)updateObject:(NSManagedObject *)object {
    BOOL success = NO;
    if ([[CDManager sharedManager].mainObjectContext objectRegisteredForID:object.objectID]) {
        NSError *error = nil;
        success = [self addObject:object error:&error];
    }
    return success;
}

+ (NSManagedObject *)searchObjectWithID:(NSManagedObjectID *)objectID {
    return [[CDManager sharedManager].mainObjectContext objectRegisteredForID:objectID];
}

+ (BOOL)mainObjectChanged {
    return [[CDManager sharedManager].mainObjectContext hasChanges];
}

+ (BOOL)bgObjectChanged {
    return [[CDManager sharedManager].bgObjectContext hasChanges];
}

+ (void)backgroundObjectSave {
    NSError *error = nil;
    if ([self bgObjectChanged]) {
        [[CDManager sharedManager].bgObjectContext save:&error];
    }
}

+ (NSMutableArray<NSManagedObject *> *)fetchAllRecordsWithModelClass:(Class)modelClass {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(modelClass) inManagedObjectContext:[CDManager sharedManager].mainObjectContext];
    [request setEntity:entity];

    NSError *error = nil;
    return [[[CDManager sharedManager].mainObjectContext executeFetchRequest:request error:&error] mutableCopy];
}

@end

@implementation NSManagedObject (convert)
+ (NSManagedObject *)ConvertedObject {
    NSString *className = [NSString stringWithUTF8String:object_getClassName(self)];
    return [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[CDManager sharedManager].mainObjectContext];
}
@end
