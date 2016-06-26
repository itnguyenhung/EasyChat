//
//  LoginViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "LoginViewController.h"
#import "ChatsTableViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"LOG IN";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)actLogin:(id)sender {
    [self.view endEditing:YES];
    if ([self isSignUpTextValid]) {
        [SVProgressHUD showWithStatus:@"Login"];
        
        QBUUser *user = [QBUUser new];
        user.login = _txtPhone.text;
        user.password = _txtPassword.text;
        
        [ServicesManager.instance logInWithUser:user completion:^(BOOL success, NSString * _Nullable errorMessage) {
            if (success) {
                [SVProgressHUD dismiss];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                [dic setObject:_txtPhone.text forKey:USER_LOGIN];
                [dic setObject:_txtPassword.text forKey:PASS_LOGIN];
                [USER_DEFAULTS setObject:dic forKey:CURRENT_USER];
                [USER_DEFAULTS synchronize];
                [self presentVCWhenLoginFinished];
            }
            else {
                [SVProgressHUD dismiss];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }];
    }
}

- (BOOL)isSignUpTextValid {
    BOOL signUpValid = NO;
    if (_txtPhone.text != nil && _txtPhone.text.length > 0) {
        signUpValid = YES;
    }
    if (_txtPassword.text != nil && _txtPassword.text.length > 0) {
        signUpValid = YES;
    }
    return signUpValid;
}

- (void)presentVCWhenLoginFinished {
    ChatsTableViewController *chatsVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDDialog];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:chatsVC];
    [self presentViewController:nav animated:NO completion:nil];
}

@end
