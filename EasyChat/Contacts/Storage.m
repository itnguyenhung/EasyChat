//
//  Storage.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "Storage.h"

@implementation Storage

+ (instancetype)instance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.users = [NSMutableArray array];
    }
    return self;
}
@end
