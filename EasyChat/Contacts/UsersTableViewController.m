//
//  UsersTableViewController.m
//  EasyChat
//
//  Created by Nguyen Van Hung on 5/24/16.
//  Copyright © 2016 HungNV. All rights reserved.
//

#import "UsersTableViewController.h"
#import "Storage.h"
#import "UsersPaginator.h"
#import "UserTableViewCell.h"
#import "DetailContactViewController.h"

@interface UsersTableViewController () <UITableViewDelegate, UITableViewDataSource, NMPaginatorDelegate>
{
    NSMutableArray *arrContactAddressBook;
}
@property (nonatomic, strong) UsersPaginator *paginator;
@property (nonatomic, weak) UILabel *lblFooter;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL isActionsOpened;

@end

@implementation UsersTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.paginator = [[UsersPaginator alloc] initWithPageSize:PAGE_SIZE delegate:self];
    
    arrContactAddressBook =  [Utilities getContacts];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
    [arrContactAddressBook sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof (self)weakSelf = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [weakSelf setupTableViewFooter];
        [SVProgressHUD showWithStatus:@"Get users"];
        [weakSelf.paginator fetchFirstPage];
        
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[Storage instance].users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"user_id" forIndexPath:indexPath];
    cell.tag = indexPath.row;
    
    QBUUser *user = [[Storage instance].users[indexPath.row] objectForKey:@"user"];
    cell.lblName.text = user.fullName != nil ? user.fullName : user.login;
    cell.lblPhone.text = user.phone;
    NSData *image_data = [[Storage instance].users[indexPath.row] objectForKey:@"image_data"];
    if (![image_data  isEqual: @""]) {
        UIImage *image = [Utilities resizeImage:[UIImage imageWithData:image_data] newSize:CGSizeMake(20, 20)];
        cell.imgAvatar.image = image;
    }
    if (indexPath.row ==  [[Storage instance].users count]-1) {
        if(![self.paginator reachedLastPage]){
            [self fetchNextPage];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:DETAIL_CONTACT_ID sender:indexPath];
}
#pragma mark
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSIndexPath *)sender {
    if ([[segue identifier] isEqualToString:DETAIL_CONTACT_ID]) {
        NSUInteger row = sender.row;
        DetailContactViewController *detail = [segue destinationViewController];
        detail.userInfo = [Storage instance].users[row];
    }
}

#pragma mark
#pragma mark - Paginator
- (void)fetchNextPage {
    [self.paginator fetchNextPage];
    [self.activityIndicator startAnimating];
}

- (void)setupTableViewFooter{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    footerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.lblFooter = label;
    [footerView addSubview:label];
    
    // set up activity indicator
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.center = CGPointMake(40, 22);
    activityIndicatorView.hidesWhenStopped = YES;
    
    self.activityIndicator = activityIndicatorView;
    [footerView addSubview:activityIndicatorView];
    
    self.tableView.tableFooterView = footerView;
}

- (void)updateTableViewFooter {
    if ([self.paginator.results count] != 0) {
        self.lblFooter.text = [NSString stringWithFormat:@"%lu results out of %ld",
                                 (unsigned long)[self.paginator.results count], (long)self.paginator.total];
    } else {
        self.lblFooter.text = @"";
    }
    
    [self.lblFooter setNeedsDisplay];
}
#pragma mark

#pragma mark NMPaginatorDelegate
- (void)paginator:(id)paginator didReceiveResults:(NSArray *)results {
    NSMutableArray *arrResult = [[NSMutableArray alloc] init];
    for (QBUUser *user in results) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        NSData *image_data = nil;
        for (NSArray *arr in arrContactAddressBook) {
            NSString *phone = [arr valueForKey:@"phone"];
            if ([user.phone isEqualToString:phone]) {
                image_data = (NSData *)[arr valueForKey:@"image_data"];
                break;
            }
        }
        [dic setObject:user forKey:@"user"];
        [dic setObject:image_data != nil ? image_data : @"" forKey:@"image_data"];
        [arrResult addObject:dic];
    }
    [[Storage instance].users addObjectsFromArray:arrResult];
    
    // update tableview footer
    [self updateTableViewFooter];
    [self.activityIndicator stopAnimating];
    
    // reload table
    [self.tableView reloadData];
    [SVProgressHUD dismiss];
}

@end
