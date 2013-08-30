//
//  MKDSlideViewController.m
//  MKDSlideViewController
//
//  Created by Marcel Dierkes on 03.12.11.
//  Copyright (c) 2011 Marcel Dierkes. All rights reserved.
//

#import "MKDSlideViewController.h"

#import "UIColor+MHExtensions.h"
#import "CustomNavigationBar.h"

@interface MKDSlideViewController ()

@property (nonatomic, retain) UIViewController * mainViewController;
@property (nonatomic, retain) UIView * mainContainerView;
@property (nonatomic, retain) UIView * mainTapView;
@property (nonatomic, retain) UIPanGestureRecognizer * panGesture;
@property (nonatomic) CGPoint previousLocation;

@property (nonatomic, assign) CGRect originalFrame;

- (void)setupPanGestureForView:(UIView *)view;
- (void)panGesture:(UIPanGestureRecognizer *)gesture;
- (void)addTapViewOverlay;
- (void)removeTapViewOverlay;

@end

@implementation MKDSlideViewController

@synthesize leftViewController = _leftViewController, rightViewController = _rightViewController;
@synthesize rootViewController = _rootViewController;
@synthesize rootNavViewController = _rootNavViewController;
@synthesize panGesture = _panGesture, menuBarButtonItem = _menuBarButtonItem;
@synthesize mainViewController = _mainViewController, mainContainerView = _mainContainerView, mainTapView = _mainTapView;

@synthesize previousLocation = _previousLocation;

- (id)initWithRootViewController:(UIViewController *)rootViewController;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.rootViewController = rootViewController;
    }
    return self;
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    UIView * containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, [[UIScreen mainScreen] bounds].size.height - 20)];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    containerView.backgroundColor = [UIColor viewFlipsideBackgroundColor];
    
    if( self.rootViewController )
    {
        // Wrap inside Navigation Controller
        self.rootNavViewController = [[UINavigationController alloc] initWithRootViewController:self.rootViewController];
        
        [self setupPanGestureForView:self.rootNavViewController.navigationBar];
        
        self.mainViewController = self.rootNavViewController;
        self.originalFrame = self.mainViewController.view.frame;
        
        [self addChildViewController:self.mainViewController];
        self.mainViewController.view.clipsToBounds = YES;
        
        // Add menu item
        if( self.menuBarButtonItem == nil ) {
            _menuBarButtonItem = [UIBarButtonItem UIBarButtonItemWithImage:[UIImage imageNamed:@"drawer_btn"] target:self selector:@selector(showLeftViewController:)];
        }
        
        self.rootViewController.navigationItem.leftBarButtonItem = self.menuBarButtonItem;
        
        // Add layer shadow
        CALayer * mainLayer = [self.mainViewController.view layer];
        mainLayer.masksToBounds = NO;
        CGPathRef pathRect = [UIBezierPath bezierPathWithRect:self.mainViewController.view.bounds].CGPath;
        mainLayer.shadowColor = [UIColor blackColor].CGColor;
        mainLayer.shadowOffset = CGSizeMake(0.0, 0.0);
        mainLayer.shadowOpacity = 1.0f;
        mainLayer.shadowPath = pathRect;
        mainLayer.shadowRadius = 20.0f;
        
        [containerView addSubview:self.mainViewController.view];
    }
    
    self.view = containerView;
    [containerView release];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.mainViewController viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.mainViewController viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    [_leftViewController release];
    [_rightViewController release];
    [_mainViewController release];
    [_rootViewController release];
    [_rootNavViewController release];
    [_mainContainerView release];
    [_mainTapView release];
    
    [_panGesture release];
    [_menuBarButtonItem release];
    
    [super dealloc];
}

#pragma mark - Sub View Controllers

- (void)setLeftViewController:(UIViewController *)leftViewController rightViewController:(UIViewController *)rightViewController
{
    [self.mainViewController.view removeFromSuperview];
    
    self.leftViewController = leftViewController;
    self.rightViewController = rightViewController;
    
    if( self.leftViewController != nil )
    {
        [self.leftViewController.view setFrame:CGRectMake(0, 0, self.leftViewController.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 20)];
        
        [self addChildViewController:self.leftViewController];
        [self.view addSubview:self.leftViewController.view];
    }
    
    if( self.rightViewController != nil )
    {
        [self.rightViewController.view setFrame:CGRectMake(0, 0, self.rightViewController.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height - 20)];

        [self addChildViewController:self.rightViewController];
        [self.view addSubview:self.rightViewController.view];
    }
    
    [self.view addSubview:self.mainViewController.view];
}

- (void) updateMainViewController:(UIViewController *)mainViewController
{
    [self updateMainViewControllers:@[mainViewController]];
}

- (void) updateMainViewControllers:(NSArray *)mainViewControllers
{
    UIViewController *mainViewController = [mainViewControllers objectAtIndex:0];
    mainViewController.navigationItem.leftBarButtonItem = self.menuBarButtonItem;
    
    BOOL animated = NO;
    for (UIViewController *vc in mainViewControllers) {
        if ([self.rootNavViewController.viewControllers containsObject:vc]) {
            animated = YES;
            break;
        }
    }
    
    [self.rootNavViewController setViewControllers:mainViewControllers animated:animated];
}

- (void) pushMainViewController:(UIViewController *)mainViewController
{
    [self.rootNavViewController pushViewController:mainViewController animated:YES];
}

#pragma mark - Panning

- (void)setupPanGestureForView:(UIView *)view
{
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    pan.maximumNumberOfTouches = 1;
    self.panGesture = pan;
    [view addGestureRecognizer:pan];
    [pan release];
}

- (void)panGesture:(UIPanGestureRecognizer *)gesture
{
    if( gesture.state == UIGestureRecognizerStateBegan )
    {
        self.previousLocation = CGPointZero;
    }
    else if( gesture.state == UIGestureRecognizerStateChanged )
    {
        // Calculate position offset
        CGPoint locationInView = [gesture translationInView:self.view];
        CGFloat deltaX = locationInView.x - self.previousLocation.x;
        
        // Decide, which view controller should be revealed
        if (self.mainViewController.view.frame.origin.x == 0.0f) {
            if( deltaX < 0.0f ) {// left
                [self.view sendSubviewToBack:self.leftViewController.view]; // showing right
                [self.rightViewController viewWillAppear:YES];
                [self.rightViewController viewDidAppear:YES];
            } else if (deltaX > 0.0f) {
                [self.view sendSubviewToBack:self.rightViewController.view]; // showing left
                [self.leftViewController viewWillAppear:YES];
                [self.leftViewController viewDidAppear:YES];
            }
        }
        
        // Update view frame
        CGRect newFrame = self.mainViewController.view.frame;
        newFrame.origin.x +=deltaX;
        if (newFrame.origin.x > 0 && !self.leftViewController) {
            newFrame.origin.x = 0;
        } else if (newFrame.origin.x < 0 && !self.rightViewController) {
            newFrame.origin.x = 0;
        }
        
        self.mainViewController.view.frame = newFrame;
        
        self.previousLocation = locationInView;
    }
    else if( (gesture.state == UIGestureRecognizerStateEnded) || (gesture.state == UIGestureRecognizerStateCancelled) )
    {
        CGFloat xOffset = self.mainViewController.view.frame.origin.x;

        // snap to zero
        if( (xOffset <= (self.mainViewController.view.frame.size.width/2)) && (xOffset >= (-self.mainViewController.view.frame.size.width/2)) )
        {
            [self showMainViewController:nil];
        }
        // reveal right view controller
        else if( xOffset < (-self.mainViewController.view.frame.size.width/2) )
        {
            [self showRightViewController:nil];
        }
        // reveal left view controller
        else
        {
            [self showLeftViewController:nil];
        }
        
        self.previousLocation = CGPointZero;
    }
}

#pragma mark - Tappable View Overlay

- (void)addTapViewOverlay
{
    if( self.mainTapView == nil )
    {
        _mainTapView = [[UIView alloc] initWithFrame:self.mainViewController.view.bounds];
        self.mainTapView.backgroundColor = [UIColor clearColor];
        
        // Tap Gesture
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMainViewController:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        
        [self.mainTapView addGestureRecognizer:tap];
        [tap release];
        
        // Pan Gesture
        [self setupPanGestureForView:self.mainTapView];
    }
    else
        self.mainTapView.frame = self.mainViewController.view.bounds;
    
    [self.mainViewController.view addSubview:self.mainTapView];
}

- (void)removeTapViewOverlay
{
    if( self.mainTapView != nil )
        [self.mainTapView removeFromSuperview];
}

#pragma mark - Slide Actions

- (IBAction)showLeftViewController:(id)sender
{
    [self.view sendSubviewToBack:self.rightViewController.view];
    
    [self.leftViewController viewWillAppear:YES];
    
    [UIView animateWithDuration:kSlideSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^(void){

        CGRect theFrame = self.mainViewController.view.frame;

//        CGSize scales = CGSizeMake(.5, .5);
//        CGPoint offset = CGPointMake(CGRectGetMidX(theFrame) - CGRectGetMidX(theFrame), CGRectGetMidY(theFrame) - CGRectGetMidY(theFrame));
//        CGAffineTransform transform = CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y);
//        self.mainViewController.view.transform = transform;
        
        theFrame = self.mainViewController.view.frame;
        theFrame.origin.x = self.leftViewController.view.frame.size.width - kSlideOverlapWidth;
//        self.mainViewController.view.frame = transformedFrame;
        theFrame.origin.x = theFrame.size.width - kSlideOverlapWidth;
        self.mainViewController.view.frame = theFrame;
    } completion:^(BOOL finished) {
        [self addTapViewOverlay];
        [self.leftViewController viewDidAppear:YES];
    }];
}

- (IBAction)showRightViewController:(id)sender
{
    [self.view sendSubviewToBack:self.leftViewController.view];  // FIXME: Correct timing, when sending to back
    
    [UIView animateWithDuration:kSlideSpeed animations:^{
        CGRect theFrame = self.mainViewController.view.frame;
        theFrame.origin.x = -theFrame.size.width + kSlideOverlapWidth;
        self.mainViewController.view.frame = theFrame;
    } completion:^(BOOL finished) {
        [self addTapViewOverlay];
    }];
}

- (IBAction)showMainViewController:(id)sender
{
    if( self.mainViewController.view.frame.origin.x != CGPointZero.x )
    {
        [UIView animateWithDuration:kSlideSpeed delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^(void){
            CGRect fromRect = self.mainViewController.view.frame;
            //            theFrame.origin = CGPointZero;
            CGRect viewRect = self.originalFrame;
            
            //            CGSize scales = CGSizeMake(viewRect.size.width/fromRect.size.width, viewRect.size.height/fromRect.size.height);
            CGSize scales = CGSizeMake(1, 1);
            CGPoint offset = CGPointMake(CGRectGetMidX(viewRect) - CGRectGetMidX(fromRect), CGRectGetMidY(viewRect) - CGRectGetMidY(fromRect));
            CGAffineTransform transform = CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y);
            
            self.mainViewController.view.transform = transform;
            self.mainViewController.view.frame = self.originalFrame; //theFrame;
        } completion:^(BOOL finished) {
            [self removeTapViewOverlay];
        }];
    } else {
        //fade transition
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.mainViewController.view.layer addAnimation:transition forKey:nil];

    }
}

@end
