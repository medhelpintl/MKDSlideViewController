//
//  MKDSlideViewController.h
//  MKDSlideViewController
//
//  Created by Marcel Dierkes on 03.12.11.
//  Copyright (c) 2011 Marcel Dierkes. All rights reserved.
//
// Test Edit

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>  // Don't forget to add the QuartzCore Framework to your project

#define kSlideSpeed 0.3f
#define kSlideOverlapWidth 52.0f;

@interface MKDSlideViewController : UIViewController

@property (nonatomic, retain) UIViewController * leftViewController;
@property (nonatomic, retain) UIViewController * rightViewController;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UINavigationController * rootNavViewController;

@property (nonatomic, retain) UIBarButtonItem * menuBarButtonItem;

- (id)initWithRootViewController:(UIViewController *)rootViewController;
- (void) updateMainViewController:(UIViewController *)mainViewController;
- (void) pushMainViewController:(UIViewController *)mainViewController;
- (void)setLeftViewController:(UIViewController *)leftViewController rightViewController:(UIViewController *)rightViewController;

- (IBAction)showLeftViewController:(id)sender;
- (IBAction)showRightViewController:(id)sender;
- (IBAction)showMainViewController:(id)sender;

@end

@protocol MKDSlideViewControllerDelegate <NSObject>

- (void)slideViewController:(MKDSlideViewController *)svc willSlideToViewController:(UIViewController *)vc;
- (void)slideViewController:(MKDSlideViewController *)svc didSlideToViewController:(UIViewController *)vc;

@end
