//
//  MainViewController.m
//  Fooda
//
//  Created by Christopher Gu on 5/23/14.
//  Copyright (c) 2014 Christopher Gu. All rights reserved.
//

#import "MainViewController.h"
#import "LoginViewController.h"
#import "MessagesViewController.h"
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface MainViewController ()<CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate>
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation* currentLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *viewForMapElements;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *gpsBarButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UIButton *writeButtonMessage;
@property (nonatomic) NSArray *driverArray;
@property (nonatomic) NSMutableArray *driverActiveArray;
@property (nonatomic) NSArray *conversationArray;
@property (nonatomic) NSMutableArray *addToChatMutableArray;
@property (nonatomic) PFUser *currentUser;
@property (nonatomic) PFObject *conversation;
@property int viewMessageIndexPathRow;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentUser = [PFUser currentUser];
    self.driverActiveArray = [NSMutableArray new];
    
    self.navigationItem.hidesBackButton = YES;
    self.tabBar.selectedItem = self.tabBar.items[0];
    
	[self setUpLocationManager];
    [self setRegion];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.addToChatMutableArray = [NSMutableArray new];
    [self retrieveDriverInfoFromCloud];
    [self retrieveConversationInfo];
}

-(void)viewDidAppear:(BOOL)animated
{
    if ([self.tabBar.selectedItem isEqual:self.tabBar.items[1]])
    {
        self.writeButtonMessage.hidden = NO;
        self.tableView.frame = CGRectMake(0, 64, 320, 416);
    }
    else if ([self.tabBar.selectedItem isEqual:self.tabBar.items[2]])
    {
        self.writeButtonMessage.hidden = YES;
        self.tableView.frame = CGRectMake(0, 64, 320, 553);
    }
}

#pragma mark - location methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // updates the current user's location to the cloud for annotation purposes
    self.currentUser[@"latitude"] = @(self.locationManager.location.coordinate.latitude);
    self.currentUser[@"longitude"] = @(self.locationManager.location.coordinate.longitude);
    [self.currentUser saveInBackground];
    
    // retrieves other drivers' locations from the cloud for annotation purposes
    for (PFUser *driver in self.driverActiveArray)
    {
        PFQuery *driverQuery = [PFUser query];
        [driverQuery whereKey:@"email" equalTo:driver[@"email"]];
        [driverQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            PFUser *thisDriver = objects.firstObject;
            if (![thisDriver[@"latitude"] isEqual:[NSNull null]] && ![thisDriver[@"longitude"] isEqual:[NSNull null]] )
            {
                CLLocationCoordinate2D driverCoordinate = CLLocationCoordinate2DMake([thisDriver[@"latitude"] doubleValue], [thisDriver[@"longitude"] doubleValue]);
                MKPointAnnotation *driverPoint = [MKPointAnnotation new];
                driverPoint.coordinate = driverCoordinate;
                driverPoint.title = thisDriver[@"username"];
                
                // makes sure there is only one annotation on the map for each driver at any time
                for (MKPointAnnotation *annotationInside in self.mapView.annotations)
                {
                    if ([annotationInside.title isEqualToString:driverPoint.title])
                    {
                        [self.mapView removeAnnotation:annotationInside];
                    }
                }
                [self.mapView addAnnotation:driverPoint];
            }
        }];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    else
    {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        pin.image = [UIImage imageNamed:@"foodaDriverIcon"];
        
        // creating a label for the pin
        UILabel *pinDriverLabel = [[UILabel alloc] initWithFrame:CGRectMake(-35, -10, 90, 10)];
        pinDriverLabel.backgroundColor = [UIColor whiteColor];
        pinDriverLabel.layer.borderColor = [[UIColor orangeColor] CGColor];
        pinDriverLabel.layer.borderWidth = 1.0;
        pinDriverLabel.text = annotation.title;
        pinDriverLabel.textAlignment = NSTextAlignmentCenter;
        [pinDriverLabel setFont:[UIFont systemFontOfSize:10]];
        [pin addSubview:pinDriverLabel];
        
        return pin;
    }
}

#pragma mark - table view delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numberOfRows;
    
    if ([self.tabBar.selectedItem isEqual:self.tabBar.items[1]])
    {
        numberOfRows = (int)[self.driverArray count];
    }
    else if ([self.tabBar.selectedItem isEqual:self.tabBar.items[2]])
    {
        if (self.conversationArray)
        {
            numberOfRows = (int)[self.conversationArray count];
        }
        else
        {
            numberOfRows = 0;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellReuseID"];
    
    if ([self.tabBar.selectedItem isEqual:self.tabBar.items[1]])
    {
        PFUser *driver = self.driverArray[indexPath.row];
        cell.textLabel.text = driver[@"username"];
        if ([driver[@"loggedIn"] isEqualToNumber:@1])
        {
            cell.textLabel.textColor = [UIColor blackColor];
            cell.detailTextLabel.text = @"ACTIVE";
            cell.detailTextLabel.textColor = [UIColor greenColor];
        }
        else
        {
            cell.textLabel.textColor = [UIColor grayColor];
            cell.detailTextLabel.text = @"INACTIVE";
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
        
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor whiteColor];
    }
    else if ([self.tabBar.selectedItem isEqual:self.tabBar.items[2]])
    {
        NSString *chattersString = [self.conversationArray[indexPath.row][@"chattersArray"] componentsJoinedByString:@", "];
        
        cell.textLabel.text = chattersString;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"by %@", self.conversationArray[indexPath.row][@"senderString"]];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tabBar.selectedItem isEqual:self.tabBar.items[1]])
    {
        UITableViewCell *selectedCell = [(UITableView *)tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell.backgroundColor == [UIColor whiteColor])
        {
            selectedCell.backgroundColor = [UIColor colorWithRed:255/255.0f green:235/255.0f blue:175/255.0f alpha:1.0f];
            if (![self.addToChatMutableArray containsObject:selectedCell.textLabel.text] && ![selectedCell.textLabel.text isEqualToString:self.currentUser[@"username"]])
            {
                [self.addToChatMutableArray addObject:selectedCell.textLabel.text];
            }
        }
        else
        {
            selectedCell.backgroundColor = [UIColor whiteColor];
            if ([self.addToChatMutableArray containsObject:selectedCell.textLabel.text])
            {
                [self.addToChatMutableArray removeObject:selectedCell.textLabel.text];
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else if ([self.tabBar.selectedItem isEqual:self.tabBar.items[2]])
    {
        self.viewMessageIndexPathRow = (int)indexPath.row;
        [self performSegueWithIdentifier:@"ViewMessagesVCSegue" sender:self];
    }
}

#pragma mark - tab bar delegate methods

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if ([tabBar.selectedItem isEqual:self.tabBar.items[0]])
    {
        self.viewForMapElements.alpha = 1.0;
    }
    else
    {
        if ([tabBar.selectedItem isEqual:self.tabBar.items[1]])
        {
            self.writeButtonMessage.hidden = NO;
            self.tableView.frame = CGRectMake(0, 64, 320, 416);
        }
        else
        {
            self.writeButtonMessage.hidden = YES;
            self.tableView.frame = CGRectMake(0, 64, 320, 553);
        }
        
        self.viewForMapElements.alpha = 0.0;
        [self.tableView reloadData];
    }
}

#pragma mark - helper methods

- (void)setUpLocationManager
{
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.currentLocation = self.locationManager.location;
    
    [self.mapView setShowsUserLocation:YES];
}

// used to initially set the user location on the map and to reset it with the orange navArrow
- (void)setRegion
{
    CLLocationCoordinate2D loc = [self.currentLocation coordinate];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 500, 500);
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

// used to change the GPS bar button when the user first allows the app to see their location
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorized)
    {
        [self.gpsBarButton setTitle:@"GPS:ON"];
    }
}

- (void)retrieveDriverInfoFromCloud
{
    // finds all drivers for the table view
    // and finds active drivers for the map
    PFQuery *driverQuery = [PFUser query];
    [driverQuery addDescendingOrder:@"loggedIn"];
    [driverQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        self.driverArray = objects;
        [self.tableView reloadData];
        
        for (PFUser *driver in objects)
        {
            if ([driver[@"loggedIn"] isEqualToNumber:@1] && ![driver[@"email"] isEqual:self.currentUser[@"email"]])
            {
                [self.driverActiveArray addObject:driver];
            }
        }
    }];
}

- (void)retrieveConversationInfo
{
    NSArray *currentUserArray = @[self.currentUser[@"username"]];
    
    PFQuery *conversationQuery = [PFQuery queryWithClassName:@"ConversationThread"];
    [conversationQuery whereKey:@"chattersArray" containsAllObjectsInArray:currentUserArray];
    [conversationQuery includeKey:@"messageArray"];
    [conversationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.conversationArray = objects;
        [self.tableView reloadData];
    }];
}

#pragma mark - button methods

- (IBAction)onWriteMessagePressed:(id)sender
{
    if ([self.addToChatMutableArray count]>0)
    {
        self.conversation = [PFObject objectWithClassName:@"ConversationThread"];
        self.conversation[@"senderString"] = self.currentUser[@"username"];
        self.conversation[@"chattersArray"] = self.addToChatMutableArray;
        [self.conversation[@"chattersArray"] addObject:self.currentUser[@"username"]];
        self.conversation[@"createdDate"] = [NSDate date];
        
        [self performSegueWithIdentifier:@"CreateMessagesVCSegue" sender:self];
    }
    else
    {
        UIAlertView *needToAddAlert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                 message:@"You must choose at least one other recipient to send your message to."
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles: nil];
        [needToAddAlert show];
    }
}

- (IBAction)onMapNavArrowButtonPressed:(id)sender
{
    [self setRegion];
}

- (IBAction)onGPSBarButtonPressed:(id)sender
{
    if ([self.gpsBarButton.title isEqualToString:@"GPS:OFF"])
    {
        [self.gpsBarButton setTitle:@"GPS:ON"];
        [self.locationManager startUpdatingLocation];
    }
    else if ([self.gpsBarButton.title isEqualToString:@"GPS:ON"])
    {
        [self.gpsBarButton setTitle:@"GPS:OFF"];
        [self.locationManager stopUpdatingLocation];
        
        self.currentUser[@"latitude"]=[NSNull null];
        self.currentUser[@"longitude"]=[NSNull null];
    }
}

- (IBAction)onLogoutButtonPressed:(id)sender
{
    [self.locationManager stopUpdatingLocation];
    self.currentUser[@"loggedIn"] = @NO;
    self.currentUser[@"latitude"]=[NSNull null];
    self.currentUser[@"longitude"]=[NSNull null];
    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
    {
        [PFUser logOut];
    }];
    
    [UIView beginAnimations:@"animation" context:nil];
    [UIView setAnimationDuration:0.8];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    [UIView commitAnimations];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MessagesViewController *mvc = segue.destinationViewController;
    mvc.conversation = self.conversation;
    
    if ([segue.identifier isEqualToString:@"ViewMessagesVCSegue"])
    {
        mvc.viewingMessages = 1;
        mvc.conversation = self.conversationArray[self.viewMessageIndexPathRow];
    }
    else
    {
        mvc.viewingMessages = 0;
    }
}

@end
