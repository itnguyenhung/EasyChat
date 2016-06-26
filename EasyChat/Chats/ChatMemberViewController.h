//
//  ChatMemberViewController.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/2/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SAMTextView.h"

@interface ChatMemberViewController : UIViewController
@property (nonatomic, strong) QBChatDialog *dialog;
@property (nonatomic, weak) NSMutableArray *userInfo;
@property (weak, nonatomic) IBOutlet SAMTextView *txtMessage;
- (IBAction)actSendMessage:(id)sender;

@end
