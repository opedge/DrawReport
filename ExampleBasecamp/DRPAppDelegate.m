//
//  DRPAppDelegate.m
//  DrawReportBasecamp
//
//  Created by Oleg Poyaganov on 12.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPAppDelegate.h"
#import <DrawReport/DRPReporter.h>
#import "DRPBasecamp.h"

@implementation DRPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DRPBasecamp *basecamp = [DRPBasecamp sharedInstance];
    [basecamp configureWithClientId:@"YOUR_CLIENT_ID"
                       clientSecret:@"YOUR_CLIENT_SECRET"
                        redirectURL:[NSURL URLWithString:@"YOUR_REDIRECT_URI"]];
    [DRPReporter registerReporterViewControllerDelegate:basecamp];
    [DRPReporter startListeningShake];
    return YES;
}

@end
