//
//  LoginViewController.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *txtPhone;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
- (IBAction)actLogin:(id)sender;

@end
