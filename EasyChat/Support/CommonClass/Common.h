//
//  Common.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Common : NSObject

- (void)checkCurrentUserWithCompletion:(void(^)(NSError *authError))completion;

@end
