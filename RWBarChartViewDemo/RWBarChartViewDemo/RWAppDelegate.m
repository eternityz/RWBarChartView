//
//  RWAppDelegate.m
//  RWBarChartViewDemo
//
//  Created by Zhang Bin on 14-03-08.
//  Copyright (c) 2014年 Zhang Bin. All rights reserved.
//

#import "RWAppDelegate.h"
#import "RWBarChartView.h"
#import "RWDemoViewController.h"

@implementation RWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    srandomdev();
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    RWDemoViewController *vc = [[RWDemoViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.translucent = NO;
    self.window.rootViewController = nav;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
