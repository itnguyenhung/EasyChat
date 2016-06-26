//
//  Common.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "Common.h"

@implementation Common

- (void)checkCurrentUserWithCompletion:(void(^)(NSError *authError))completion {
    if ([[QBSession currentSession] currentUser] != nil) {
        if (completion) completion(nil);
    }
    else {
        NSMutableDictionary *dic_user = [USER_DEFAULTS objectForKey:CURRENT_USER];
        [QBRequest logInWithUserLogin:[dic_user objectForKey:USER_LOGIN] password:[dic_user objectForKey:PASS_LOGIN] successBlock:^(QBResponse * _Nonnull response, QBUUser * _Nullable user) {
            if (completion) completion(nil);
        } errorBlock:^(QBResponse * _Nonnull response) {
            if (completion) completion(response.error.error);
        }];
    }
}

@end
