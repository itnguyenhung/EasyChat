//
//  Utilities.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+ (NSString *)formatDatetimeFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"US"]];
    NSTimeZone *zone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSCalendar *calender = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calender setTimeZone:zone];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *result = [formatter stringFromDate:date];
    return result;
}

+ (NSString *)truncateText:(NSString *)string withLenght:(int)len {
    if ([string lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > len) {
        string = [string substringWithRange:NSMakeRange(0, string.length - 1)];
        return [self truncateText:string withLenght:len];
    }
    return string;
}

+ (NSMutableArray *)getContactAuthorizationFromUser {
    NSMutableArray *finalContactList = [[NSMutableArray alloc] init];
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [finalContactList addObject:[Utilities getContacts]];
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        finalContactList = [Utilities getContacts];
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
//        DEVLOG(@"address book denied access");
    }
    return finalContactList;
}

+ (NSMutableArray *)getContacts {
    NSMutableArray *newContactArray = [[NSMutableArray alloc]init];
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *arrayOfAllPeople1 = (__bridge NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSUInteger peopleCounter = 0;
    for (peopleCounter = 0;peopleCounter < [arrayOfAllPeople1 count]; peopleCounter++) {
        ABRecordRef thisPerson = (__bridge ABRecordRef) [arrayOfAllPeople1 objectAtIndex:peopleCounter];
        NSString *name = (__bridge NSString *) ABRecordCopyCompositeName(thisPerson);
        ABMultiValueRef number = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
        for (NSUInteger emailCounter = 0; emailCounter < ABMultiValueGetCount(number); emailCounter++) {
            NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(number, emailCounter);
            if ([email length] != 0) {
                NSString *removed1 = [email stringByReplacingOccurrencesOfString:@"-" withString:@""];
                NSString *removed2 = [removed1 stringByReplacingOccurrencesOfString:@")" withString:@""];
                NSString *removed3 = [removed2 stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSString *removed4 = [removed3 stringByReplacingOccurrencesOfString:@"(" withString:@""];
                NSString *removed5 = [removed4 stringByReplacingOccurrencesOfString:@"+" withString:@""];
                NSMutableDictionary * contantDic = [[NSMutableDictionary alloc] init];
                if ([name length] == 0) {
                    [contantDic setValue:@"No name" forKey:@"name"];
                }
                else {
                    [contantDic setValue:name forKey:@"name"];
                }
                [contantDic setValue:removed5 forKey:@"phone"];
                [contantDic setValue:@"NO" forKey:@"isselected"];
                NSData *contactImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(thisPerson, kABPersonImageFormatThumbnail);
                if (contactImageData != nil) {
                    [contantDic setObject:contactImageData forKey:@"image_data"];
                }else{
                    [contantDic setObject:@"" forKey:@"image_data"];
                }
                [newContactArray addObject:contantDic];
            }
        }
    }
    CFRelease(addressBook);
    return newContactArray;
}

+ (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size {
    CGRect cropRect = CGRectMake(0, 0, size.width, size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    return cropped;
}

+ (UIImage *)resizeImage:(UIImage *)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
