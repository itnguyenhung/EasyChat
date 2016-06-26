//
//  ChatTableViewCell.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/29/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UILabel *lblUnreadCount;

@end
