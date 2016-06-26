//
//  ChatViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 6/20/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "ChatViewController.h"
#import "MessageStatusStringBuilder.h"
#import "UIImage+fixOrientation.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "QMMessageNotificationManager.h"
#import <NSString+EMOEmoji.h>

static const NSUInteger widthPadding = 40.0f;
static const NSUInteger maxCharactersNumber = 1024; //0 - unlimited

@interface ChatViewController () <QMChatServiceDelegate, QMChatConnectionDelegate, QMChatCellDelegate, QMChatAttachmentServiceDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) QBUUser *opponentUser;
@property (nonatomic, strong) MessageStatusStringBuilder *stringBuilder;
@property (nonatomic, strong) NSMapTable *attachmentCells;
@property (nonatomic, readonly) UIImagePickerController *pickerController;
@property (nonatomic, strong) NSTimer *typingTimer;
@property (nonatomic, strong) id observerWillResignActive;
@property (nonatomic, strong) NSArray QB_GENERIC(QBChatMessage *) *unreadMessages;
@property (nonatomic, strong) NSMutableSet *detailedCells;
@end

@implementation ChatViewController
@synthesize pickerController = _pickerController;

- (UIImagePickerController *)pickerController {
    if (_pickerController == nil) {
        _pickerController = [UIImagePickerController new];
        _pickerController.delegate = self;
    }
    return _pickerController;
}

#pragma mark - Override
- (NSUInteger)senderID {
    return [QBSession currentSession].currentUser.ID;
}

- (NSString *)senderDisplayName {
    return [QBSession currentSession].currentUser.fullName;
}

- (CGFloat)heightForSectionHeader {
    return 40.0f;
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBarController.tabBar setHidden:YES];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.inputToolbar.contentView.backgroundColor = [UIColor whiteColor];
    self.inputToolbar.contentView.textView.placeHolder = @"Message";
    self.attachmentCells = [NSMapTable strongToWeakObjectsMapTable];
    self.stringBuilder = [MessageStatusStringBuilder new];
    self.detailedCells = [NSMutableSet set];
    
    [self updateTitle];
    
    if (self.dialog.type == QBChatDialogTypePrivate) {
        //Handling 'typing' status.
        __weak __typeof(self)weakSelf = self;
        [self.dialog setOnUserIsTyping:^(NSUInteger userID) {
            __typeof(weakSelf)strongSelf = weakSelf;
            if ([QBSession currentSession].currentUser.ID == userID) {
                return;
            }
            strongSelf.title = @"Typing...";
        }];
        
        //Handling user stopped typing.
        [self.dialog setOnUserStoppedTyping:^(NSUInteger userID) {
            __typeof(weakSelf)strongSelf = weakSelf;
            if ([QBSession currentSession].currentUser.ID == userID) {
                return;
            }
            [strongSelf updateTitle];
        }];
    }
    
    [[ServicesManager instance].chatService addDelegate:self];
    [ServicesManager instance].chatService.chatAttachmentService.delegate = self;
    if ([[self storedMessages] count] > 0 && self.chatSectionManager.totalMessagesCount == 0) {
        [self.chatSectionManager addMessages:[self storedMessages]];
    }
    [self refreshMessagesShowingProgress:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [ServicesManager instance].currentDialogID = self.dialog.ID;
    __weak __typeof(self)weakSelf = self;
    self.observerWillResignActive = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [weakSelf fireStopTypingIfNecessary];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self.observerWillResignActive];
    
    //Delete typing blocks
    [self.dialog clearTypingStatusBlocks];
    
    //Resetting currently opened dialog
    [ServicesManager instance].currentDialogID = nil;
}

- (void)updateTitle {
    if (self.dialog.type == QBChatDialogTypePrivate) {
        NSMutableArray *mutableOccupants = [self.dialog.occupantIDs mutableCopy];
        [mutableOccupants removeObject:@([self senderID])];
        NSNumber *opponentID = [mutableOccupants firstObject];
        QBUUser *opponentUser = [[ServicesManager instance].usersService.usersMemoryStorage userWithID:[opponentID unsignedIntegerValue]];
        if (!opponentUser) {
            self.title = [opponentID stringValue];
            return;
        }
        self.opponentUser = opponentUser;
        self.title = self.opponentUser.fullName;
    }
    else {
        self.title = self.dialog.name;
    }
}

- (NSArray *)storedMessages {
    NSArray *arr = [[ServicesManager instance].chatService.messagesMemoryStorage messagesWithDialogID:self.dialog.ID];
    return arr;
}

- (void)refreshMessagesShowingProgress:(BOOL)showingProgress {
    if (showingProgress) {
        [SVProgressHUD showWithStatus:@"Loading messages"];
    }
    __weak __typeof(self)weakSelf = self;
    [[ServicesManager instance].chatService messagesWithChatDialogID:self.dialog.ID completion:^(QBResponse * _Nonnull response, NSArray<QBChatMessage *> * _Nullable messages) {
        if (response.success) {
            if ([messages count] > 0) {
                [weakSelf.chatSectionManager addMessages:messages];
            }
            [SVProgressHUD dismiss];
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"[Error] %@", response.error.description]];
        }
    }];
}

#pragma mark - Utilitties
- (void)sendReadStatusForMessage:(QBChatMessage *)message {
    if (message.senderID != self.senderID && ![message.readIDs containsObject:@(self.senderID)]) {
        [[ServicesManager instance].chatService readMessage:message completion:^(NSError * _Nullable error) {
            if (error != nil) {
                return;
            }
            if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
                [UIApplication sharedApplication].applicationIconBadgeNumber--;
            }
        }];
    }
}

- (void)readMessages:(NSArray *)messages {
    if ([ServicesManager instance].isAuthorized) {
        [[ServicesManager instance].chatService readMessages:messages forDialogID:self.dialog.ID completion:nil];
    }
    else {
        self.unreadMessages = messages;
    }
}

- (void)fireStopTypingIfNecessary {
    [self.typingTimer invalidate];
    self.typingTimer = nil;
    [self.dialog sendUserStoppedTyping];
}

- (NSString *)timeStampWithDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
//        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"HH:mm";
    });
    NSString *timeStamp = [dateFormatter stringFromDate:date];
    return timeStamp;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Tool bar Actions
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSUInteger)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date {
    BOOL shouldJoin = (self.dialog.type == QBChatDialogTypeGroup ? !self.dialog.isJoined : NO);
    if (![[QBChat instance] isConnected] || shouldJoin) {
        return;
    }
    
    if (self.typingTimer != nil) {
        [self fireStopTypingIfNecessary];
    }
    
    QBChatMessage *message = [QBChatMessage message];
    message.text = text;
    message.senderID = senderId;
    message.markable = YES;
    message.deliveredIDs = @[@(self.senderID)];
    message.readIDs = @[@(self.senderID)];
    message.dialogID = self.dialog.ID;
    message.dateSent = date;
    
    //Sending message
    [[ServicesManager instance].chatService sendMessage:message toDialogID:self.dialog.ID saveToHistory:YES saveToStorage:YES completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSString *title = @"Error";
            NSString *subtitle = error.localizedDescription;
            UIImage *iconImage = [UIImage imageNamed:@"icon-error"];
            UIColor *backgroundColor = [UIColor colorWithRed:241.0/255.0 green:196.0/255.0 blue:15.0/255.0 alpha:1.0];
            [QMMessageNotificationManager showNotificationWithTitle:title subtitle:subtitle color:backgroundColor iconImage:iconImage];
        }
    }];
    [self finishSendingMessageAnimated:YES];
}

#pragma mark - Cell classes
- (Class)viewClassForItem:(QBChatMessage *)item {
    if (item.isNotificatonMessage) {
        return [QMChatNotificationCell class];
    }
    
    if (item.senderID != self.senderID) {
        if (item.isMediaMessage && item.attachmentStatus != QMMessageAttachmentStatusError) {
            return [QMChatAttachmentIncomingCell class];
        }
        else {
            return [QMChatIncomingCell class];
        }
    }
    else {
        if (item.isMediaMessage && item.attachmentStatus != QMMessageAttachmentStatusError) {
            return [QMChatAttachmentOutgoingCell class];
        }
        else {
            return [QMChatOutgoingCell class];
        }
    }
}

#pragma mark - Strings builder
- (NSAttributedString *)attributedStringForItem:(QBChatMessage *)messageItem {
    UIColor *textColor;
    if (messageItem.isNotificatonMessage) {
        textColor = [UIColor blackColor];
    }
    else {
        textColor = [messageItem senderID] == self.senderID ? [UIColor whiteColor] : [UIColor blackColor];
    }
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:17.0f];
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName:textColor, NSFontAttributeName:font};
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:messageItem.text ? messageItem.text : @"" attributes:attributes];
    
    return attrStr;
}

- (NSAttributedString *)topLabelAttributedStringForItem:(QBChatMessage *)messageItem {
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    if ([messageItem senderID] == self.senderID || self.dialog.type == QBChatDialogTypePrivate) {
        return nil;
    }
    
    NSString *lblTopText = self.opponentUser.fullName != nil ? self.opponentUser.fullName : self.opponentUser.login;
    if (self.dialog.type != QBChatDialogTypePrivate) {
        QBUUser *messageSender = [[ServicesManager instance].usersService.usersMemoryStorage userWithID:messageItem.senderID];
        if (messageSender) {
            lblTopText = messageSender.login;
        }
        else {
            lblTopText = [NSString stringWithFormat:@"%lu", messageItem.senderID];
        }
    }
    
    NSMutableParagraphStyle *paragrapjStyle = [[NSMutableParagraphStyle alloc] init];
    paragrapjStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *attributes = @{NSForegroundColorAttributeName:[UIColor colorWithRed:0 green:122.0/255.0 blue:1.0/255.0 alpha:1.0], NSFontAttributeName:font, NSParagraphStyleAttributeName:paragrapjStyle};
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:lblTopText attributes:attributes];
    
    return attrStr;
}

- (NSAttributedString *)bottomLabelAttributedStringForItem:(QBChatMessage *)messageItem {
    UIColor *textColor = [messageItem senderID] == self.senderID ? [UIColor colorWithWhite:1 alpha:0.7f] : [UIColor colorWithWhite:0.0 alpha:0.7f];
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:13.0f];
    
    NSMutableParagraphStyle *paragraphStype = [[NSMutableParagraphStyle alloc] init];
    paragraphStype.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *attributes = @{NSForegroundColorAttributeName:textColor, NSForegroundColorAttributeName:font, NSParagraphStyleAttributeName:paragraphStype};
    NSString *text = messageItem.dateSent ? [self timeStampWithDate:messageItem.dateSent] : @"";
    if ([messageItem senderID] == self.senderID) {
        text = [NSString stringWithFormat:@"%@\n%@", text, [self.stringBuilder statusFromMessage:messageItem]];
    }
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    
    return attrStr;
}

#pragma mark - Collection view Datasource
- (CGSize)collectionView:(QMChatCollectionView *)collectionView dynamicSizeAtIndexPath:(NSIndexPath *)indexPath maxWidth:(CGFloat)maxWidth {
    QBChatMessage *item = [self.chatSectionManager messageForIndexPath:indexPath];
    Class viewClass = [self viewClassForItem:item];
    CGSize size = CGSizeZero;
    
    if (viewClass == [QMChatAttachmentIncomingCell class]) {
        size = CGSizeMake(MIN(200, maxWidth), 200);
    }
    else if (viewClass == [QMChatAttachmentOutgoingCell class]) {
        NSAttributedString *attributedString = [self bottomLabelAttributedStringForItem:item];
        CGSize bottomLableSize = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString withConstraints:CGSizeMake(MIN(200, maxWidth), 200) limitedToNumberOfLines:0];
        size = CGSizeMake(MIN(200, maxWidth), 200 + ceilf(bottomLableSize.height));
    }
    else if (viewClass == [QMChatNotificationCell class]) {
        NSAttributedString *attributedString = [self attributedStringForItem:item];
        size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString withConstraints:CGSizeMake(maxWidth, CGFLOAT_MAX) limitedToNumberOfLines:0];
    }
    else {
        NSAttributedString *attributedString = [self attributedStringForItem:item];
        size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedString withConstraints:CGSizeMake(maxWidth, CGFLOAT_MAX) limitedToNumberOfLines:0];
    }
    
    return size;
}

- (CGFloat)collectionView:(QMChatCollectionView *)collectionView minWidthAtIndexPath:(NSIndexPath *)indexPath {
    QBChatMessage *item = [self.chatSectionManager messageForIndexPath:indexPath];
    CGSize size = CGSizeZero;
    if ([self.detailedCells containsObject:item.ID]) {
        size = [TTTAttributedLabel sizeThatFitsAttributedString:[self bottomLabelAttributedStringForItem:item] withConstraints:CGSizeMake(CGRectGetWidth(self.collectionView.frame) - widthPadding, CGFLOAT_MAX) limitedToNumberOfLines:0];
    }
    
    if (self.dialog.type != QBChatDialogTypePrivate) {
        CGSize topLableSize = [TTTAttributedLabel sizeThatFitsAttributedString:[self topLabelAttributedStringForItem:item] withConstraints:CGSizeMake(CGRectGetWidth(self.collectionView.frame) - widthPadding, CGFLOAT_MAX) limitedToNumberOfLines:0];
        if (topLableSize.width > size.width) {
            size = topLableSize;
        }
    }
    
    return size.width;
}

//Allows to perform copy action for QMChatIncomingCell and QMChatOutgoingCell
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    QBChatMessage *item = [self.chatSectionManager messageForIndexPath:indexPath];
    Class viewClass = [self viewClassForItem:item];
    
    if (viewClass == [QMChatAttachmentIncomingCell class] || viewClass == [QMChatAttachmentOutgoingCell class] || viewClass == [QMChatNotificationCell class] || viewClass == [QMChatContactRequestCell class]) {
        return NO;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    QBChatMessage *item = [self.chatSectionManager messageForIndexPath:indexPath];
    Class viewClass = [self viewClassForItem:item];
    
    if (viewClass == [QMChatAttachmentIncomingCell class] || viewClass == [QMChatAttachmentOutgoingCell class]) {
        return;
    }
    [UIPasteboard generalPasteboard].string = item.text;
}

#pragma mark - QMChatCollectionViewDelegateFlowLayout
- (QMChatCellLayoutModel)collectionView:(QMChatCollectionView *)collectionView layoutModelAtIndexPath:(NSIndexPath *)indexPath {
    QMChatCellLayoutModel layoutModel = [super collectionView:collectionView layoutModelAtIndexPath:indexPath];
    layoutModel.avatarSize = (CGSize){0.0, 0.0};
    layoutModel.topLabelHeight = 0.0f;
    layoutModel.maxWidthMarginSpace = 20.0f;
    
    QBChatMessage *item = [self.chatSectionManager messageForIndexPath:indexPath];
    Class class = [self viewClassForItem:item];
    
    if (class == [QMChatAttachmentIncomingCell class] || class == [QMChatIncomingCell class]) {
        if (self.dialog.type != QBChatDialogTypePrivate) {
            NSAttributedString *topLableString = [self topLabelAttributedStringForItem:item];
            CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:topLableString withConstraints:CGSizeMake(CGRectGetWidth(self.collectionView.frame) - widthPadding, CGFLOAT_MAX) limitedToNumberOfLines:1];
            layoutModel.topLabelHeight = size.height;
        }
        layoutModel.spaceBetweenTopLabelAndTextView = 5.0f;
    }
    else if (class == [QMChatNotificationCell class]) {
        layoutModel.spaceBetweenTopLabelAndTextView = 5.0f;
    }
    
    CGSize size = CGSizeZero;
    if ([self.detailedCells containsObject:item.ID]) {
        NSAttributedString *bottomAttributedString = [self bottomLabelAttributedStringForItem:item];
        size = [TTTAttributedLabel sizeThatFitsAttributedString:bottomAttributedString withConstraints:CGSizeMake(CGRectGetWidth(self.collectionView.frame) - widthPadding, CGFLOAT_MAX) limitedToNumberOfLines:0];
    }
    layoutModel.bottomLabelHeight = ceilf(size.height);
    layoutModel.spaceBetweenTextViewAndBottomLabel = 5.0f;
    
    return layoutModel;
}

- (void)collectionView:(QMChatCollectionView *)collectionView configureCell:(UICollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView configureCell:cell forIndexPath:indexPath];
    
    QMChatCell *chatCell = (QMChatCell *)cell;
    [chatCell setDelegate:self];
    [chatCell containerView].highlightColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    
    if ([cell isKindOfClass:[QMChatOutgoingCell class]] || [cell isKindOfClass:[QMChatAttachmentOutgoingCell class]]) {
        [chatCell containerView].bgColor = [UIColor colorWithRed:0 green:121.0/255.0 blue:1 alpha:1.0];
    }
    else if ([cell isKindOfClass:[QMChatIncomingCell class]] || [cell isKindOfClass:[QMChatAttachmentIncomingCell class]]) {
        [chatCell containerView].bgColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1.0];
    }
    else if ([cell isKindOfClass:[QMChatNotificationCell class]]) {
        [chatCell containerView].bgColor = self.collectionView.backgroundColor;
        cell.userInteractionEnabled = NO;
    }
    
    if (![cell conformsToProtocol:@protocol(QMChatAttachmentCell)]) {
        return;
    }
    
    QBChatMessage *message = [self.chatSectionManager messageForIndexPath:indexPath];
    if (message.attachments == nil) {
        return;
    }
    
    QBChatAttachment *attachment = message.attachments.firstObject;
    NSMutableArray *keysToRemove = [NSMutableArray array];
    NSEnumerator *enumerator = [self.attachmentCells keyEnumerator];
    NSString *existingAttachmentID = nil;
    while (existingAttachmentID = [enumerator nextObject]) {
        UICollectionViewCell *cachedCell = [self.attachmentCells objectForKey:existingAttachmentID];
        if ([cachedCell isEqual:cell]) {
            [keysToRemove addObject:existingAttachmentID];
        }
    }
    
    for (NSString *key in keysToRemove) {
        [self.attachmentCells removeObjectForKey:key];
    }
    
    [self.attachmentCells setObject:cell forKey:attachment.ID];
    [(id<QMChatAttachmentCell>)cell setAttachmentID:attachment.ID];
    
    //Getting image from chat attachment service
    __weak __typeof(self)weakSelf = self;
    [[ServicesManager instance].chatService.chatAttachmentService getImageForAttachmentMessage:message completion:^(NSError * _Nullable error, UIImage * _Nullable image) {
        if ([(id<QMChatAttachmentCell>)cell attachmentID] != attachment.ID) {
            return;
        }
        [weakSelf.attachmentCells removeObjectForKey:attachment.ID];
        
        if (error != nil) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        else {
            if (image != nil) {
                [(id<QMChatAttachmentCell>)cell setAttachmentImage:image];
                [cell updateConstraints];
            }
        }
    }];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger lastSection = [self.collectionView numberOfSections] - 1;
    if (indexPath.section == lastSection && indexPath.item == [self.collectionView numberOfItemsInSection:lastSection] - 1) {
        //load more if exists message
        __weak typeof(self)weakSelf = self;
        [[[ServicesManager instance].chatService loadEarlierMessagesWithChatDialogID:self.dialog.ID] continueWithBlock:^id _Nullable(BFTask<NSArray<QBChatMessage *> *> * _Nonnull task) {
            if ([task.result count] > 0) {
                [weakSelf.chatSectionManager addMessages:task.result];
            }
            
            return nil;
        }];
    }
    
    //Marking message as read if needed
    QBChatMessage *itemMessage = [self.chatSectionManager messageForIndexPath:indexPath];
    [self sendReadStatusForMessage:itemMessage];
    
    return [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - QMChatCellDelegate
- (void)chatCellDidTapContainer:(QMChatCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    QBChatMessage *currentMessage = [self.chatSectionManager messageForIndexPath:indexPath];
    
    if ([self.detailedCells containsObject:currentMessage.ID]) {
        [self.detailedCells removeObject:currentMessage.ID];
    }
    else {
        [self.detailedCells addObject:currentMessage.ID];
    }
    
    [self.collectionView.collectionViewLayout removeSizeFromCacheForItemID:currentMessage.ID];
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)chatCell:(QMChatCell *)cell didPerformAction:(SEL)action withSender:(id)sender {

}

- (void)chatCellDidTapAvatar:(QMChatCell *)cell {
    
}

- (void)chatCell:(QMChatCell *)cell didTapAtPosition:(CGPoint)position {
    
}

#pragma mark - QMChatServiceDelegate
- (void)chatService:(QMChatService *)chatService didLoadMessagesFromCache:(NSArray<QBChatMessage *> *)messages forDialogID:(NSString *)dialogID {
    if ([self.dialog.ID isEqualToString:dialogID]) {
        [self.chatSectionManager addMessages:messages];
    }
}

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    if ([self.dialog.ID isEqualToString:dialogID]) {
        [self.chatSectionManager addMessage:message];
    }
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog {
    if (self.dialog.type != QBChatDialogTypePrivate && [self.dialog.ID isEqualToString:chatDialog.ID]) {
        self.dialog = chatDialog;
        self.title = self.dialog.name;
    }
}

- (void)chatService:(QMChatService *)chatService didUpdateMessage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    if ([self.dialog.ID isEqualToString:dialogID] && message.senderID == self.senderID) {
        [self.chatSectionManager updateMessage:message];
    }
}

- (void)chatService:(QMChatService *)chatService didUpdateMessages:(NSArray<QBChatMessage *> *)messages forDialogID:(NSString *)dialogID {
    if ([self.dialog.ID isEqualToString:dialogID]) {
        [self.chatSectionManager updateMessages:messages];
    }
}

#pragma mark - QMChatConnectionDelegate
- (void)refreshAndReadMessages {
    [self refreshMessagesShowingProgress:YES];
    if (self.unreadMessages.count > 0) {
        [self readMessages:self.unreadMessages];
    }
    self.unreadMessages = nil;
}

- (void)chatServiceChatDidConnect:(QMChatService *)chatService {
    [self refreshAndReadMessages];
}

- (void)chatServiceChatDidReconnect:(QMChatService *)chatService {
    [self refreshAndReadMessages];
}

#pragma mark - QMChatAttachmentServiceDelegate
- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService didChangeAttachmentStatus:(QMMessageAttachmentStatus)status forMessage:(QBChatMessage *)message {
    if (status != QMMessageAttachmentStatusNotLoaded) {
        if ([message.dialogID isEqualToString:self.dialog.ID]) {
            [self.chatSectionManager updateMessage:message];
        }
    }
}

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService didChangeLoadingProgress:(CGFloat)progress forChatAttachment:(QBChatAttachment *)attachment {
    id<QMChatAttachmentCell> cell = [self.attachmentCells objectForKey:attachment.ID];
    if (cell != nil) {
        [cell updateLoadingProgress:progress];
    }
}

- (void)chatAttachmentService:(QMChatAttachmentService *)chatAttachmentService didChangeUploadingProgress:(CGFloat)progress forMessage:(QBChatMessage *)message {
    id<QMChatAttachmentCell> cell = [self.attachmentCells objectForKey:message.ID];
    if (cell != nil && progress < 1.0f) {
        NSIndexPath *indexPath = [self.chatSectionManager indexPathForMessage:message];
        cell = (UICollectionViewCell <QMChatAttachmentCell> *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self.attachmentCells setObject:cell forKey:message.ID];
    }
    
    if (cell != nil) {
        [cell updateLoadingProgress:progress];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    [super textViewDidChange:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.length + range.location > textView.text.length) {
        return NO;
    }
    
    if (![ServicesManager instance].isAuthorized) {
        return YES;
    }
    
    if (self.typingTimer) {
        [self.typingTimer invalidate];
        self.typingTimer = nil;
    }
    else {
        [self.dialog sendUserIsTyping];
    }
    
    self.typingTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(fireStopTypingIfNecessary) userInfo:nil repeats:NO];
    
    if (maxCharactersNumber > 0) {
        if (textView.text.length >= maxCharactersNumber && text.length > 0) {
            [self showCharactersNumberError];
            return NO;
        }
        
        NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
        if ([newText length] <= maxCharactersNumber || text.length == 0) {
            return YES;
        }
        
        NSInteger symbolsToCut = maxCharactersNumber - textView.text.length;
        NSRange stringRange = {0, MIN([text length], symbolsToCut)};
        stringRange = [text rangeOfComposedCharacterSequencesForRange:stringRange];
        
        NSString *shortString = [text substringWithRange:stringRange];
        NSMutableString *newtext = textView.text.mutableCopy;
        [newtext insertString:shortString atIndex:range.location];
        textView.text = newtext.copy;
        
        [self showCharactersNumberError];
        [self textViewDidChange:textView];
        
        return NO;
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [super textViewDidEndEditing:textView];
    [self fireStopTypingIfNecessary];
}

- (void)showCharactersNumberError {
    NSString *title = @"Error";
    NSString *subtitle = [NSString stringWithFormat:@"The character limit is %lu. ", maxCharactersNumber];
    [QMMessageNotificationManager showNotificationWithTitle:title subtitle:subtitle type:QMMessageNotificationTypeWarning];
}

#pragma mark - UIImagePicketControllerDelegate
- (void)didPickAttachmentImage:(UIImage *)image {
    QBChatMessage *message = [QBChatMessage new];
    message.senderID = self.senderID;
    message.dialogID = self.dialog.ID;
    message.dateSent = [NSDate date];
    
    __weak __typeof(self)weakSelf = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        __typeof(weakSelf)strongSelf = weakSelf;
        UIImage *newImage = image;
        if (strongSelf.pickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
            newImage = [newImage fixOrientation];
        }
        
        UIImage *resizedImage = [strongSelf resizedImageFromImage:newImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ServicesManager instance].chatService sendAttachmentMessage:message toDialog:strongSelf.dialog withAttachmentImage:resizedImage completion:^(NSError * _Nullable error) {
                [strongSelf.attachmentCells removeObjectForKey:message.ID];
                if (error != nil) {
                    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                    [[ServicesManager instance].chatService deleteMessageLocally:message];
                    [strongSelf.chatSectionManager deleteMessage:message];
                }
            }];
        });
    });
}

- (UIImage *)resizedImageFromImage:(UIImage *)image {
    CGFloat largestSide = image.size.width > image.size.height ? image.size.width : image.size.height;
    CGFloat scaleCoefficient = largestSide / 560.0f;
    CGSize newSize = CGSizeMake(image.size.width / scaleCoefficient, image.size.height / scaleCoefficient);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:(CGRect){0, 0, newSize.width, newSize.height}];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}
@end
