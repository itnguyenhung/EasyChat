//
//  UsersDataSource.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "UsersDataSource.h"
#import "SelectUsersTableViewCell.h"
#import "ServicesManager.h"

@interface UsersDataSource()
@property (nonatomic, copy) NSArray *customUsers;
@end

@implementation UsersDataSource
- (instancetype)initWithUsers:(NSArray *)users {
    self = [super init];
    if (self) {
        _excludeUsersIDS = @[];
        _customUsers = [[users copy] sortedArrayUsingComparator:^NSComparisonResult(QBUUser *obj1, QBUUser *obj2) {
            return [obj1.login compare:obj2.login options:NSNumericSearch];
        }];
        _users = _customUsers == nil ? [[ServicesManager instance].usersService.usersMemoryStorage unsortedUsers] : _customUsers;
    }
    return self;
}

- (void)addUsers:(NSArray<QBUUser *> *)users {
    NSMutableArray *mUsers;
    if (_users != nil) {
        mUsers = [users mutableCopy];
    }
    else {
        mUsers = [NSMutableArray array];
    }
    [mUsers addObjectsFromArray:users];
    _users = [mUsers copy];
}

- (instancetype)init {
    return [self initWithUsers:[[ServicesManager instance] sortedUsers]];
}

- (void)setExcludeUsersIDS:(NSArray *)excludeUsersIDS {
    if (excludeUsersIDS == nil) {
        _users = self.customUsers == nil ? self.customUsers : [[ServicesManager instance].usersService.usersMemoryStorage unsortedUsers];
        return;
    }
    
    if ([excludeUsersIDS isEqualToArray:self.users]) {
        return;
    }
    
    if (self.customUsers == nil) {
        _users = [[[ServicesManager instance].usersService.usersMemoryStorage unsortedUsers] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (ID IN %@)", self.excludeUsersIDS]];
    }
    else {
        _users = self.customUsers;
    }
    
    NSMutableArray *excludedUsers = [NSMutableArray array];
    [_users enumerateObjectsUsingBlock:^(QBUUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSNumber *excID in excludeUsersIDS) {
            if (obj.ID == excID.integerValue) {
                [excludedUsers addObject:obj];
            }
        }
    }];
    
    //Remove excluded users
    NSMutableArray *mUsers = [_users mutableCopy];
    [mUsers removeObjectsInArray:excludedUsers];
    _users = [mUsers copy];
}
@end
