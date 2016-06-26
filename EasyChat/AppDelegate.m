//
//  AppDelegate.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "AppDelegate.h"
#import "UsersTableViewController.h"
#import "WelcomeViewController.h"
#import "ChatViewController.h"

@interface AppDelegate () <NotificationServiceDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerForRemoteNotifications];
    [Utilities getContactAuthorizationFromUser];
    
    //Config QuickBlox
    [QBSettings setApplicationID:QUICK_BLOX_KEY_APP_ID];
    [QBSettings setAuthKey:QUICK_BLOX_KEY_AUTHEN];
    [QBSettings setAuthSecret:QUICK_BLOX_KEY_AUTHEN_SECRET];
    [QBSettings setAccountKey:QUICK_BLOX_KEY_ACCOUNT];
    [QBSettings setChatDNSLookupCacheEnabled:YES];
    [QBSettings setCarbonsEnabled:YES];
    [QBSettings setLogLevel:QBLogLevelNothing];
    [QBSettings enableXMPPLogging];
    
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        ServicesManager.instance.notificationService.pushDialogID = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey][kPushNotificationDialogIdentifierKey];
    }
    
    NSMutableDictionary *dic_user = [USER_DEFAULTS objectForKey:CURRENT_USER];
    ServicesManager *servicesManager = [ServicesManager instance];
    if (servicesManager.currentUser != nil && dic_user != nil) {
        servicesManager.currentUser.password = [dic_user objectForKey:PASS_LOGIN];
        [servicesManager logInWithUser:servicesManager.currentUser completion:^(BOOL success, NSString * _Nullable errorMessage) {
            if ([ServicesManager instance].isAuthorized) {
//                [self loadDialogs];
            }
            if (!success) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
    }
    else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        WelcomeViewController *welcomVC = [storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWellcome];
        self.window.rootViewController = welcomVC;
        [self.window makeKeyAndVisible];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    application.applicationIconBadgeNumber = 0;
    [ServicesManager.instance.chatService disconnectWithCompletionBlock:nil]; //Logout to QuickBlox chat
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [ServicesManager.instance.chatService connectWithCompletionBlock:nil]; //Login to QuickBlox chat
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

#pragma mark - Register remote notification
- (void)registerForRemoteNotifications {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:nil errorBlock:nil];
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        DEVLOG(@"%@", objects);
    } errorBlock:^(QBResponse *response) {
        DEVLOG(@"[Error] - %@", response.error.reasons);
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"[Error] %@",err.localizedDescription);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification userInfo=%@", userInfo);
    if ([application applicationState] != UIApplicationStateActive) {
        return;
    }
    
    NSString *dialogID= userInfo[kPushNotiDialogID];
    if (dialogID == nil) {
        return;
    }
    
    NSString *dialogWithIDWasEnterd = [ServicesManager instance].currentDialogID;
    if ([dialogWithIDWasEnterd isEqualToString:dialogID]) {
        return;
    }
    
    [ServicesManager instance].notificationService.pushDialogID = dialogID;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ServicesManager instance].notificationService handlePushNotificationWithDelegate:self];
    });
}

#pragma mark - NotificationServiceDelegate protocol
- (void)notificationServiceDidSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    ChatViewController *chatsVC = (ChatViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:kStoryboardIDChats];
    chatsVC.dialog = chatDialog;
    UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
    
    NSString *dialogWithIDWasentered = [ServicesManager instance].currentDialogID;
    if (dialogWithIDWasentered != nil) {
        [nav popViewControllerAnimated:NO];
    }
    [nav pushViewController:chatsVC animated:YES];
}
@end
