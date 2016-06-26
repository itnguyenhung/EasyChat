//
//  ChatViewController.h
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/20/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMChatViewController.h"

@interface ChatViewController : QMChatViewController

@property (nonatomic, strong) QBChatDialog *dialog;

@end
