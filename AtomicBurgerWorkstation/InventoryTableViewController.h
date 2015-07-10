//
//  InventoryTableViewController.h
//  AtomicBurgerWorkstation
//
//  Created by Nicholas Spitale on 5/27/15.
//  Copyright (c) 2015 Nicholas Spitale. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@interface InventoryTableViewController : UITableViewController
@property (nonatomic, strong) NSMutableArray *tableData;
@end
