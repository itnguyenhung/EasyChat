//
//  ChatMemberViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/2/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "ChatMemberViewController.h"
#import "Common.h"

@interface ChatMemberViewController () <QBChatDelegate>
{
    QBUUser *userTarget;
    QBUUser *userSource;
}

@end

@implementation ChatMemberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    userTarget = [_userInfo valueForKey:@"user"];
    self.title = userTarget.fullName != nil ? userTarget.fullName : userTarget.login;
    
    Common *common = [Common new];
    [common checkCurrentUserWithCompletion:^(NSError *authError) {
        if (authError) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[authError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
        else {
            [[QBChat instance] addDelegate:self];
            NSMutableDictionary *dic_user = [USER_DEFAULTS objectForKey:CURRENT_USER];
            userSource = [[QBSession currentSession] currentUser];
            userSource.password = [dic_user objectForKey:PASS_LOGIN];
            [[QBChat instance] connectWithUser:userSource completion:^(NSError * _Nullable error) {
                if (error == nil) {
                    QBChatDialog *chatDialog= [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePrivate];
                    chatDialog.occupantIDs = @[@(userTarget.ID)];
                    [QBRequest createDialog:chatDialog successBlock:^(QBResponse * _Nonnull response, QBChatDialog * _Nullable createdDialog) {
                        DEVLOG(@"[response] %@", response);
                    } errorBlock:^(QBResponse * _Nonnull response) {
                        DEVLOG(@"[error] %@", response);
                    }];
                }
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)actSendMessage:(id)sender {
    QBChatDialog *chatDialog= [[QBChatDialog alloc] initWithDialogID:nil type:QBChatDialogTypePrivate];
    chatDialog.occupantIDs = @[@(userTarget.ID)];
    
    QBChatMessage *message = [QBChatMessage message];
    [message setText:_txtMessage.text];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"save_to_history"] = @YES;
    [message setCustomParameters:params];
    [chatDialog sendMessage:message completionBlock:^(NSError * _Nullable error) {
        DEVLOG(@"[error] %@", error);
    }];
    
//    NSString *userId = [NSString stringWithFormat:@"%lu", user.ID];
//    [QBRequest sendPushWithText:_txtMessage.text toUsers:userId successBlock:^(QBResponse *response, NSArray *events) {
//        DEVLOG(@"Send OK");
//    } errorBlock:^(QBError *error) {
//        DEVLOG(@"[Error] %@", [error description]);
//    }];
}

#pragma mark -
#pragma mark QBChatDelegate
- (void)chatDidReceiveMessage:(QBChatMessage *)message {
    [[[UIAlertView alloc] initWithTitle:@"" message:message.text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    DEVLOG(@"[Message] %@", message.text);
}
@end
