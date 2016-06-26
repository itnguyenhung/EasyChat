//
//  DetailContactViewController.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/29/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailContactViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UITableView *tableFriendContact;
@property (weak, nonatomic) IBOutlet UILabel *lblOnlineStatus;
@property (nonatomic, weak) NSMutableArray *userInfo;

@end
