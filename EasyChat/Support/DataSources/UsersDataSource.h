//
//  UsersDataSource.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UsersDataSource : NSObject <UITableViewDataSource>
//User DataSource for table view
- (instancetype)initWithUsers:(NSArray QB_GENERIC(QBUUser *) *)users;
//Add user to DataSource
- (void)addUsers:(NSArray QB_GENERIC(QBUUser *) *)users;

@property (nonatomic, strong, readonly) NSArray QB_GENERIC(QBUUser *) *users;
@property (nonatomic, strong) NSArray QB_GENERIC(NSNumber *) *excludeUsersIDS;
@property (nonatomic, assign) BOOL addStringLoginAsBeforeUserFullname;

- (NSInteger)indexOfUser:(QBUUser *)user;
- (UIColor *)colorForUser:(QBUUser *)user;
@end
