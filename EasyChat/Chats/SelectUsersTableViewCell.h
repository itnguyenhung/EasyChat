//
//  SelectUsersTableViewCell.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectUsersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgCheckbox;
@property (weak, nonatomic) IBOutlet UIImageView *imgAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblPhone;

@end
