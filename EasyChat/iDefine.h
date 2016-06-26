//
//  iDefine.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#ifndef iDefine_h
#define iDefine_h

#define API_KEY_FLAG 1  //0: REAL   1: DEV

#if API_KEY_FLAG == 0
    #define QUICK_BLOX_KEY_APP_ID           41216
    #define QUICK_BLOX_KEY_AUTHEN           @"7TgGEbaraQGZ2rb"
    #define QUICK_BLOX_KEY_AUTHEN_SECRET    @"nCayqajtxehENW9"
    #define QUICK_BLOX_KEY_ACCOUNT          @"xFRKtiewTvvZHKDXWu7q"

    #define ENVIROMENT_USER                 @"REAL"
#else
    #define QUICK_BLOX_KEY_APP_ID           41216
    #define QUICK_BLOX_KEY_AUTHEN           @"7TgGEbaraQGZ2rb"
    #define QUICK_BLOX_KEY_AUTHEN_SECRET    @"nCayqajtxehENW9"
    #define QUICK_BLOX_KEY_ACCOUNT          @"xFRKtiewTvvZHKDXWu7q"

    #define ENVIROMENT_USER                 @"DEV"
#endif

#define PAGE_SIZE 10
#define USER_DEFAULTS [NSUserDefaults standardUserDefaults]
#define NOTIFICATION_CENTER [NSNotificationCenter defaultCenter]

#define CURRENT_USER @"current_user"
#define USER_LOGIN @"user_login"
#define PASS_LOGIN @"pass_login"

//Segue
#define SIGN_UP_ID @"signup_id"
#define LOGIN_ID @"login_id"
#define DETAIL_CONTACT_ID @"detail_contact_id"
#define CHAT_MEMBER_ID @"chat_member_id"
#define CHAT_ID @"chat_id"

//Storyboard ID
#define kStoryboardIDWellcome @"storyboard_id_welcome"
#define kStoryboardIDDialog @"storyboard_id_dialog"
#define kStoryboardIDChats @"storyboard_id_chats"

//NotificationCenter

//Push
#define kPushNotiDialogID @"dialog_id"
#define kPushNotiDialogMessage @"message"

#endif /* iDefine_h */
