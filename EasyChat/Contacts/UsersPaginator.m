//
//  UsersPaginator.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "UsersPaginator.h"

@implementation UsersPaginator

- (void)fetchResultsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize {
    __weak __typeof(self)weakSeft = self;
    QBGeneralResponsePage *responsePage = [QBGeneralResponsePage responsePageWithCurrentPage:page perPage:pageSize];
    [QBRequest usersForPage:responsePage successBlock:^(QBResponse * _Nonnull response, QBGeneralResponsePage * _Nullable page, NSArray<QBUUser *> * _Nullable users) {
        [weakSeft receivedResults:users total:page.totalEntries];
    } errorBlock:^(QBResponse * _Nonnull response) {
        [weakSeft receivedResults:nil total:0];
        DEVLOG(@"[Error] - %@", response.error);
    }];
}

@end
