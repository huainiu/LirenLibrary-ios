//
//  DonationListViewController.h
//  Liren-ios
//
//  Created by xuehai on 12/26/12.
//  Copyright (c) 2012 com.thoughtworks.liren. All rights reserved.

//  The controller to list all the donation request generated by the device

#import <UIKit/UIKit.h>
#import "Donation.h"

@interface DonationListViewController : UIViewController

@property(nonatomic, retain) NSMutableArray *donationList;

-(void)initDonationList;

-(void)loadDonationListByDevice;
-(void)loadDonationListByDeviceCallback:(NSData *)data withError:(NSError *)error;

@end
