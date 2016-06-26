//
//  SignUpViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "SignUpViewController.h"
#import "ChatsTableViewController.h"

@interface SignUpViewController ()

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"SIGN UP";
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

- (IBAction)actSignUp:(id)sender {
    [self.view endEditing:YES];
    if ([self isSignUpTextValid]) {
        [SVProgressHUD showWithStatus:@"Signing up"];
        QBUUser *user = [QBUUser new];
        user.login = _txtPhone.text;
        user.password = _txtPassword.text;
        [user.tags addObject:ENVIROMENT_USER];
        NSString *password = user.password;
        
        [QBRequest signUp:user successBlock:^(QBResponse * _Nonnull response, QBUUser * _Nullable user) {
            user.password = password;
            [ServicesManager.instance logInWithUser:user completion:^(BOOL success, NSString * _Nullable errorMessage) {
                if (success) {
                    [SVProgressHUD dismiss];
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    [dic setObject:user.login forKey:USER_LOGIN];
                    [dic setObject:password forKey:PASS_LOGIN];
                    [USER_DEFAULTS setObject:dic forKey:CURRENT_USER];
                    [USER_DEFAULTS synchronize];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                else {
                    [SVProgressHUD dismiss];
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
            }];
        } errorBlock:^(QBResponse * _Nonnull response) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[response.error description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
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

@end
