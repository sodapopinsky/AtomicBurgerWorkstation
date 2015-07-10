//
//  InventoryTableViewController.m
//  AtomicBurgerWorkstation
//
//  Created by Nicholas Spitale on 5/27/15.
//  Copyright (c) 2015 Nicholas Spitale. All rights reserved.
//

#import "InventoryTableViewController.h"
#import "AFNetworking.h"
@interface InventoryTableViewController ()

@end

@implementation InventoryTableViewController
@synthesize tableData;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self clear];
    [self fetchData];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)fetchData{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"http://atomicburger.herokuapp.com/api/1/inventory"
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             for(NSDictionary *inventoryItem in responseObject){
                 [self save:inventoryItem];
             }
             [self dump];
             [self.tableView reloadData];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
         }];
    
}
- (NSManagedObjectContext *)managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (void)save:(NSDictionary *)inventoryObject {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObject *newDevice = [NSEntityDescription insertNewObjectForEntityForName:@"Inventory" inManagedObjectContext:context];
    [newDevice setValue:[inventoryObject objectForKey:@"name"] forKey:@"name"];
    CGFloat num = (CGFloat)[[inventoryObject valueForKey:@"quantityOnHand"] floatValue];
    [newDevice setValue:[NSNumber numberWithFloat:num] forKey:@"quantityOnHand"];
    CGFloat objectId = (CGFloat)[[inventoryObject valueForKey:@"id"] floatValue];
    [newDevice setValue:[NSNumber numberWithFloat:objectId] forKey:@"id"];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    
}

-(void)setSynced:(NSManagedObject*)inventoryObject {
    NSManagedObjectContext *context = [self managedObjectContext];
    [inventoryObject setValue:0 forKey:@"sync_status"];
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

-(void)clear{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Inventory"];
    NSMutableArray *inventory = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    for (NSManagedObject * car in inventory) {
        [context  deleteObject:car];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    
}

-(void)dump{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Inventory"];
    tableData = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCellIdentifier" forIndexPath:indexPath];
    
    [cell.detailTextLabel setText:@""];
    [cell.textLabel setText:@""];
    NSManagedObject *item = [tableData objectAtIndex:indexPath.row];
    [cell.textLabel setText:[item valueForKey:@"name"]];
    NSNumber *num = [item valueForKey:@"quantityOnHand"];
    [cell.detailTextLabel setText:[num stringValue]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New item"
                                                    message:@"Enter a quantity for the item"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"submit", nil];
    alert.alertViewStyle=UIAlertViewStylePlainTextInput;
    alert.tag = indexPath.row;
    [alert show];
    return;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0)
        return;
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObject *object= [tableData objectAtIndex:alertView.tag];
    if (object) {
        // Update existing
        CGFloat num = [[[alertView textFieldAtIndex:0] text] floatValue];
        [object setValue:[NSNumber numberWithFloat:num]forKey:@"quantityOnHand"];
        [object setValue:@1 forKey:@"sync_status"];
    }
    
    // Save the object to persistent store
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    else{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    
    
    [self sync];
    
    
}

-(void)sync{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Inventory"];
    NSPredicate *predicateID = [NSPredicate predicateWithFormat:@"sync_status == 1"];
    [fetchRequest setPredicate:predicateID];
    NSMutableArray *array = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for(NSManagedObject *object in array){
        NSArray *keys = [[[object entity] attributesByName] allKeys];
        NSDictionary *dict = [object dictionaryWithValuesForKeys:keys];
        [objects addObject:dict];
    }
    
    
    NSDictionary *params = @ {@"objects" : objects };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSLog(@"%@",params);
    [manager POST:@"http://atomicburger.herokuapp.com/api/1/inventory" parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         
         for(NSManagedObject *object in array){
             [self setSynced:object];
         }
         
         
         
     }
          failure:
     ^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Error: %@", error);
     }];
    
}


@end
