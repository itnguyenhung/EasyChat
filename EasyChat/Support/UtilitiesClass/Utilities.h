//
//  Utilities.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

+ (NSString *)formatDatetimeFromDate:(NSDate *)date;
+ (NSString *)truncateText:(NSString *)string withLenght:(int)len;
+ (NSMutableArray *)getContactAuthorizationFromUser;
+ (NSMutableArray *)getContacts;
+ (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize ;
@end
