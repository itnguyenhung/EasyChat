//
//  CallTableViewCell.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/29/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CallTableViewCellDelegate <NSObject>
@optional
- (void)onTouchUpInside:(NSInteger)button;
@end

@interface CallTableViewCell : UITableViewCell
- (IBAction)actFreeCall:(id)sender;
- (IBAction)actFreeMessage:(id)sender;

@property (nonatomic, weak) id <CallTableViewCellDelegate> delegate;

@end
