//
//  ChatsTableViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/1/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "ChatsTableViewController.h"
#import "ChatTableViewCell.h"
#import "ChatViewController.h"

@interface ChatsTableViewController () <QMChatServiceDelegate, QMAuthServiceDelegate, QMChatConnectionDelegate>

@property (nonatomic, strong) id <NSObject> observerDidBecomeActive;
@property (nonatomic, strong) id <NSObject> observerDidFinishLaunching;
@property (nonatomic, readonly) NSArray *dialogs;

@end

@implementation ChatsTableViewController

- (void)loadDialogs {
    __weak __typeof(self)weakSelf = self;
    if ([ServicesManager instance].lastActivityDate != nil) {
        [[ServicesManager instance].chatService fetchDialogsUpdatedFromDate:[ServicesManager instance].lastActivityDate andPageLimit:kDialogsPageLimit iterationBlock:^(QBResponse * _Nonnull response, NSArray<QBChatDialog *> * _Nullable dialogObjects, NSSet<NSNumber *> * _Nullable dialogsUsersIDs, BOOL * _Nonnull stop) {
            [weakSelf.tableView reloadData];
        } completionBlock:^(QBResponse * _Nonnull response) {
            if ([ServicesManager instance].isAuthorized && response.success) {
                [ServicesManager instance].lastActivityDate = [NSDate date];
            }
        }];
    }
    else {
        [SVProgressHUD showWithStatus:@"Loading dialogs"];
        [[ServicesManager instance].chatService allDialogsWithPageLimit:kDialogsPageLimit extendedRequest:nil iterationBlock:^(QBResponse * _Nonnull response, NSArray<QBChatDialog *> * _Nullable dialogObjects, NSSet<NSNumber *> * _Nullable dialogsUsersIDs, BOOL * _Nonnull stop) {
            [weakSelf.tableView reloadData];
        } completion:^(QBResponse * _Nonnull response) {
            if ([ServicesManager instance].isAuthorized) {
                if (response.success) {
                    [SVProgressHUD showSuccessWithStatus:@"Completed"];
                    [ServicesManager instance].lastActivityDate = [NSDate date];
                }
                else {
                    [SVProgressHUD showErrorWithStatus:@"Failed to load dialogs"];
                }
            }
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[ServicesManager instance].chatService addDelegate:self];
    self.navigationItem.title = [ServicesManager instance].currentUser.fullName;
    if ([ServicesManager instance].isAuthorized) {
        [self loadDialogs];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)dialogs {
    return [ServicesManager.instance.chatService.dialogsMemoryStorage dialogsSortByUpdatedAtWithAscending:NO];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:CHAT_ID]) {
        ChatViewController *chatViewController = segue.destinationViewController;
        chatViewController.dialog = sender;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dialogs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chat_cell" forIndexPath:indexPath];
    
    QBChatDialog *chatDialog = self.dialogs[indexPath.row];
    switch (chatDialog.type) {
        case QBChatDialogTypePrivate: {
            cell.imgAvatar.image = [UIImage imageNamed:@"chatRoomIcon"];
            cell.lblName.text = chatDialog.name;
            cell.lblMessage.text = chatDialog.lastMessageText;
            break;
        }
        case QBChatDialogTypeGroup: {
            cell.imgAvatar.image = [UIImage imageNamed:@"GroupChatIcon"];
            cell.lblName.text = chatDialog.name;
            cell.lblMessage.text = chatDialog.lastMessageText;
            break;
        }
        case QBChatDialogTypePublicGroup: {
            cell.imgAvatar.image = [UIImage imageNamed:@"GroupChatIcon"];
            cell.lblName.text = chatDialog.name;
            cell.lblMessage.text = chatDialog.lastMessageText;
        }
        default:
            break;
    }
    
    BOOL hasUnreadMessage = chatDialog.unreadMessagesCount > 0;
    cell.lblUnreadCount.hidden = !hasUnreadMessage;
    if (hasUnreadMessage) {
        NSString *unreadText = nil;
        if (chatDialog.unreadMessagesCount > 99) {
            unreadText = @"99+";
        }
        else {
            unreadText = [NSString stringWithFormat:@"%lu", chatDialog.unreadMessagesCount];
        }
        cell.lblUnreadCount.text = unreadText;
    }
    else {
        cell.lblUnreadCount.text = nil;
    }
    
    return cell;
}

- (void)deleteDialogWithID:(NSString *)dialogID {
    __weak __typeof(self)weakSelf = self;
    [ServicesManager.instance.chatService deleteDialogWithID:dialogID completion:^(QBResponse * _Nonnull response) {
        if (response.success) {
            __typeof(self)strongSelf = weakSelf;
            [strongSelf.tableView reloadData];
            [SVProgressHUD dismiss];
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"Error leaving"];
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    QBChatDialog *dialog = self.dialogs[indexPath.row];
    [self performSegueWithIdentifier:CHAT_ID sender:dialog];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    QBChatDialog *chatDialog = self.dialogs[indexPath.row];
    NSMutableArray *occupantsWithoutCurrentUser = [NSMutableArray array];
    for (NSNumber *identifier in chatDialog.occupantIDs) {
        if (![identifier isEqualToNumber:@(ServicesManager.instance.currentUser.ID)]) {
            [occupantsWithoutCurrentUser addObject:identifier];
        }
    }
    chatDialog.occupantIDs = [occupantsWithoutCurrentUser copy];
    [SVProgressHUD showWithStatus:@"Leaving..."];
    if (chatDialog.type == QBChatDialogTypeGroup) {
        NSString *notificationText = [NSString stringWithFormat:@"%@ has left dialog.", [ServicesManager instance].currentUser.login];
        __weak __typeof(self)weakSelf = self;
        [[ServicesManager instance].chatService sendNotificationMessageAboutLeavingDialog:chatDialog withNotificationText:notificationText completion:^(NSError * _Nullable error) {
            [weakSelf deleteDialogWithID:chatDialog.ID];
        }];
    }
    else {
        [self deleteDialogWithID:chatDialog.ID];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Leave";
}

#pragma mark -
#pragma mark - Chat service Delegate
- (void)chatService:(QMChatService *)chatService didAddChatDialogsToMemoryStorage:(NSArray<QBChatDialog *> *)chatDialogs {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogsInMemoryStorage:(NSArray<QBChatDialog *> *)dialogs {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogInMemoryStorage:(nonnull QBChatDialog *)chatDialog {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didReceiveNotificationMessage:(nonnull QBChatMessage *)message createDialog:(nonnull QBChatDialog *)dialog {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddMessagesToMemoryStorage:(NSArray<QBChatMessage *> *)messages forDialogID:(NSString *)dialogID {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didDeleteChatDialogWithIDFromMemoryStorage:(NSString *)chatDialogID {
    [self.tableView reloadData];
}

#pragma mark - QMChatConnecttionDelegate
- (void)chatServiceChatDidConnect:(QMChatService *)chatService {
    [self loadDialogs];
}

- (void)chatServiceChatDidReconnect:(QMChatService *)chatService {
    [self loadDialogs];
}

- (void)chatServiceChatDidAccidentallyDisconnect:(QMChatService *)chatService {
    [SVProgressHUD showErrorWithStatus:@"Disconnected"];
}

- (void)chatService:(QMChatService *)chatService chatDidNotConnectWithError:(nonnull NSError *)error {
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Did not connect with error: %@", [error localizedDescription]]];
}

- (void)chatServiceChatDidFailWithStreamError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Chat failed with error: %@", [error localizedDescription]]];
}

@end
