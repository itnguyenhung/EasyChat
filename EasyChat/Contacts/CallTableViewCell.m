//
//  CallTableViewCell.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/29/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "CallTableViewCell.h"

@implementation CallTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)actFreeCall:(id)sender {
    [self.delegate onTouchUpInside:0];
}

- (IBAction)actFreeMessage:(id)sender {
    [self.delegate onTouchUpInside:1];
}
@end
