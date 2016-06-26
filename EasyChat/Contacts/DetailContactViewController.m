//
//  DetailContactViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/29/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "DetailContactViewController.h"
#import "CallTableViewCell.h"
#import "FriendTableViewCell.h"
#import "ChatMemberViewController.h"

@interface DetailContactViewController () <UITableViewDelegate, UITableViewDataSource, CallTableViewCellDelegate>
{
    NSDictionary *dic_user;
}
@end

@implementation DetailContactViewController

- (void)initData {
    QBUUser *user = [_userInfo valueForKey:@"user"];
    dic_user = [[NSMutableDictionary alloc] init];
    [dic_user setValue:user.fullName != nil ? user.fullName : user.login forKey:@"Full name"];
    [dic_user setValue:user.phone forKey:@"Phone"];
    [dic_user setValue:user.email forKey:@"Email"];
    NSString *last_request_at = [Utilities formatDatetimeFromDate:user.lastRequestAt];
    if (last_request_at) {
        _lblOnlineStatus.text = [NSString stringWithFormat:@"     Online %@", last_request_at];
    }
    else {
    _lblOnlineStatus.text = @"     Offline";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    self.title = [dic_user objectForKey:@"Full name"];
    NSData *image_data = [_userInfo valueForKey:@"image_data"];
    if (![image_data  isEqual: @""]) {
        UIImage *image = [Utilities resizeImage:[UIImage imageWithData:image_data] newSize:_imgAvatar.frame.size];
        _imgAvatar.image = image;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dic_user.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        CallTableViewCell *call = [tableView dequeueReusableCellWithIdentifier:@"call_id" forIndexPath:indexPath];
        call.delegate = self;
        cell = call;
    }
    else {
        FriendTableViewCell *friend = [tableView dequeueReusableCellWithIdentifier:@"friend_id" forIndexPath:indexPath];
        NSString *key = [dic_user allKeys][indexPath.row - 1];
        friend.lblKey.text = key;
        friend.lblValue.text = [dic_user objectForKey:key];
        cell = friend;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:CHAT_MEMBER_ID]) {
        ChatMemberViewController *chat_member = [segue destinationViewController];
        chat_member.userInfo = _userInfo;
    }
}

#pragma mark - Deletage CallTableViewCell
- (void)onTouchUpInside:(NSInteger)button {
    switch (button) {
        case 0: {
            
            break;
        }
        case 1: {
            [self performSegueWithIdentifier:CHAT_MEMBER_ID sender:nil];
        }
        default:
            break;
    }
}

@end
