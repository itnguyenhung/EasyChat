//
//  MoreViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "MoreViewController.h"
#import "WelcomeViewController.h"

@interface MoreViewController ()

@end

@implementation MoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)actLogOut:(id)sender {
    [SVProgressHUD showWithStatus:@"Logout user"];
    [QBRequest logOutWithSuccessBlock:^(QBResponse *response) {
        [USER_DEFAULTS removeObjectForKey:CURRENT_USER];
        [USER_DEFAULTS synchronize];
        [SVProgressHUD  dismiss];
        [self presentVCWhenLogOutFinished];
    } errorBlock:^(QBResponse *response) {
        [SVProgressHUD dismiss];
        DEVLOG(@"Response error %@:", response.error);
    }];
}

- (void)presentVCWhenLogOutFinished {
    WelcomeViewController *welcome = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWellcome];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcome];
    [self presentViewController:nav animated:NO completion:nil];
}
@end
