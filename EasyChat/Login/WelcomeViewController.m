//
//  WelcomeViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)actLogin:(id)sender {
    [self performSegueWithIdentifier:LOGIN_ID sender:nil];
}

- (IBAction)actSignUp:(id)sender {
    [self performSegueWithIdentifier:SIGN_UP_ID sender:nil];
}

- (IBAction)actConnectWithFacebook:(id)sender {
}

- (IBAction)actConnectWithGoogle:(id)sender {
}
@end
