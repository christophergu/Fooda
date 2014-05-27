//
//  LoginViewController.m
//  Fooda
//
//  Created by Christopher Gu on 5/23/14.
//  Copyright (c) 2014 Christopher Gu. All rights reserved.
//

#import "LoginViewController.h"
#import "MainViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton *signInButton;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.emailTextField.placeholder = @" Email";
    [self.emailTextField.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [self.emailTextField.layer setBorderWidth:0.8];
    self.emailTextField.layer.cornerRadius = 3;
    
    self.passwordTextField.placeholder = @" Password";
    [self.passwordTextField.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [self.passwordTextField.layer setBorderWidth:0.8];
    self.passwordTextField.layer.cornerRadius = 3;
    
    [self.signInButton.layer setBorderColor:[[UIColor orangeColor] CGColor]];
    [self.signInButton.layer setBorderWidth:0.8];
    self.signInButton.layer.cornerRadius = 3;
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:241/255.0f green:101/255.0f blue:33/255.0f alpha:1.0f];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (IBAction)onSignInButtonPressed:(id)sender
{
    [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error)
     {
         if (user)
         {
             UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
             MainViewController *mvc =[storyboard instantiateViewControllerWithIdentifier:@"MainViewControllerID"];
             
             [UIView beginAnimations:@"animation" context:nil];
             [self.navigationController pushViewController:mvc animated:NO];
             [UIView setAnimationDuration:0.8];
             [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:NO];
             [UIView commitAnimations];
             
             user[@"loggedIn"]=@YES;
             [user saveInBackground];
         }
         else
         {
             UIAlertView *logInFailAlert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Username or Password is Incorrect or No Internet Connection" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             [logInFailAlert show];
         }
     }];
    
    [self.emailTextField endEditing:YES];
    [self.passwordTextField endEditing:YES];
}

@end
