//
//  MessagesViewController.h
//  Fooda
//
//  Created by Christopher Gu on 5/25/14.
//  Copyright (c) 2014 Christopher Gu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MessagesViewController : UIViewController
@property (nonatomic) PFObject *conversation;
@property (nonatomic) NSString *chattersString;
@property BOOL viewingMessages;

@end
