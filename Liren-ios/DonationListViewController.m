//
//  DonationListViewController.m
//  Liren-ios
//
//  Created by xuehai on 12/26/12.
//  Copyright (c) 2012 com.thoughtworks.liren. All rights reserved.
//

#import "DonationListViewController.h"

#define SERVICE_SUFFIX_LOAD_DONATION_LIST  @"/donation-by-device"
#define tag_view_cell_root          1000
#define tag_view_cell_book_count    tag_view_cell_root+1
#define tag_view_cell_status        tag_view_cell_root+2
#define tag_view_cell_time          tag_view_cell_root+3

@interface DonationListViewController ()

@end

@implementation DonationListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.trackedViewName=[NSString stringWithFormat:@"%s", class_getName(self.class)];
    
    [self initDonationList];
    [self initOperationQueue];
    [self buildRefreshHeaderView];
}

-(void)viewWillAppear:(BOOL)animated{
    [self loadDonationListByDevice];
    [super viewWillAppear:animated];
}

#pragma mark - util method
-(void)initDonationList{
    if(self.donationList==nil){
        NSMutableArray *array=[[NSMutableArray alloc] init];
        self.donationList=array;
        [array release];
    }
}

-(void)initOperationQueue{
    if(self.queue==nil){
        NSOperationQueue *q=[[NSOperationQueue alloc] init];
        self.queue=q;
        [q release];
    }
    [self.queue setMaxConcurrentOperationCount:5];
}

-(void)buildRefreshHeaderView{
    LOADING_DONATION_LIST=NO;
    if(self.refreshHeaderView==nil){
        EGORefreshTableHeaderView *view=[[EGORefreshTableHeaderView alloc]initWithFrame:CGRectMake(0, -200, 320, 200)];
        self.refreshHeaderView=view;
        [view release];
    }
    [self.refreshHeaderView setDelegate:self];
    [self.tableView addSubview:self.refreshHeaderView];
    [self.refreshHeaderView refreshLastUpdatedDate];
}

-(void)loadDonationListByDevice{
    LOADING_DONATION_LIST=YES;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *deviceID=[MacAddressUtil macaddress];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_ADDRESS, SERVICE_SUFFIX_LOAD_DONATION_LIST]];
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:10.0f];
    [request addValue:deviceID forHTTPHeaderField:@"device_id"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadDonationListByDeviceCallback:data withError:error];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            LOADING_DONATION_LIST=NO;
            [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        });
    }];
}

-(void)loadDonationListByDeviceCallback:(NSData *)data withError:(NSError *)error{
    NSArray *list = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if(list==nil || list.count==0) return;
    
    [self.donationList removeAllObjects];
    
    for(NSDictionary *item in list){
        Donation *donation=[[Donation alloc] init];
        donation.donationID=[item objectForKey:@"donation_id"];
        donation.donationStatus=[item objectForKey:@"donation_status"];
        NSNumber *donationTimestamp=[item objectForKey:@"donation_time"];
        donation.donationTime = [NSDate dateWithTimeIntervalSince1970:donationTimestamp.longValue];
        donation.bookCount=[item objectForKey:@"donation_book_count"];
        [self.donationList addObject:donation];
        [donation release];
    }
    [self.tableView reloadData];
}

#pragma mark - RefreshHeaderView Delegate
- (void)reloadTableViewDataSource{
    LOADING_DONATION_LIST= YES;
}
- (void)doneLoadingTableViewData{
    LOADING_DONATION_LIST= NO;
    [self loadDonationListByDevice];
}
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    LOADING_DONATION_LIST=YES;
    [self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:0];
}
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
    return LOADING_DONATION_LIST;
}
- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
    return [NSDate date];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

#pragma mark - TableView implementation
-(void)buildTableCell:(UITableViewCell *)cell withDonation:(Donation *)donation{
    UILabel *statusLabel=[[UILabel alloc] initWithFrame:CGRectMake(20, 8, 70, 30)];
    [statusLabel setBackgroundColor:[UIColor clearColor]];
    [statusLabel setTag:tag_view_cell_status];
    [statusLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
    [statusLabel setTextColor:[UIColor redColor]];
    
    if([DONATION_STATUS_NEW isEqualToString:donation.donationStatus.uppercaseString]){
        [statusLabel setText:@"[审核中]"];
        [statusLabel setTextColor:[UIColor colorWithRed:184.0f/255.0f green:165.0f/255.0f blue:79.0f/255.0f alpha:1.0f]];
    }else if([DONATION_STATUS_APPROVED isEqualToString:donation.donationStatus.uppercaseString]){
        [statusLabel setText:@"[可寄送]"];
        [statusLabel setTextColor:[UIColor colorWithRed:162.0f/255.0f green:208.0f/255.0f blue:38.0f/255.0f alpha:1.0f]];
    }else if([DONATION_STATUS_REJECTED isEqualToString:donation.donationStatus.uppercaseString]){
        [statusLabel setText:@"[已拒绝]"];
        [statusLabel setTextColor:[UIColor colorWithRed:204.0f/255.0f green:60.0f/255.0f blue:53.0f/255.0f alpha:1.0f]];
    }else if([DONATION_STATUS_RECEIVED isEqualToString:donation.donationStatus.uppercaseString]){
        [statusLabel setText:@"[已收到]"];
        [statusLabel setTextColor:[UIColor colorWithRed:131.0f/255.0f green:131.0f/255.0f blue:130.0f/255.0f alpha:1.0f]];
    }
    [cell addSubview:statusLabel];
    [statusLabel release];
    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    UILabel *timeLabel=[[UILabel alloc] initWithFrame:CGRectMake(85, 8, 200, 30)];
    [timeLabel setTag:tag_view_cell_time];
    [timeLabel setText:[dateFormatter stringFromDate:donation.donationTime]];
    [timeLabel setBackgroundColor:[UIColor clearColor]];
    [dateFormatter release];
    [timeLabel setTextColor:[UIColor blackColor]];
    [timeLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
    [cell addSubview:timeLabel];
    [timeLabel release];
    
    UILabel *bookCountLabel=[[UILabel alloc] initWithFrame:CGRectMake(240, 8, 60, 30)];
    [bookCountLabel setTag:tag_view_cell_book_count];
    [bookCountLabel setBackgroundColor:[UIColor clearColor]];
    [bookCountLabel setTextColor:[UIColor blackColor]];
    [bookCountLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
    [bookCountLabel setText:[NSString stringWithFormat:@"%d本", donation.bookCount.intValue]];
    [cell addSubview:bookCountLabel];
    [bookCountLabel release];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.donationList count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *bookIdentifier = @"DonationIndentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:bookIdentifier];
    if(cell==nil){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bookIdentifier] autorelease];
    }
    
    for(UIView *view in cell.subviews){
        if(view.tag>=tag_view_cell_root){
            [view removeFromSuperview];
        }
    }
    
    cell.selectionStyle=UITableViewCellSelectionStyleGray;
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    
    Donation *donation=[self.donationList objectAtIndex:indexPath.row];
    [self buildTableCell:cell withDonation:donation];
    
    return cell;
}

-(void)dealloc{
    [_donationList release];
    [_refreshHeaderView release];
    [_tableView release];
    [_queue release];
    [super dealloc];
}

@end
