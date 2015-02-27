//
// HRPReporter.m
//
// Copyright (c) 2013 Oleg Poyaganov (opedge@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DRPReporter.h"
#import "DRPReporterViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface DRPReporter()

@end

@interface DRPReporter()

@end

@implementation DRPReporter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceQueue;
    static DRPReporter *reporter = nil;
    
    dispatch_once(&onceQueue, ^{
        reporter = [[self alloc] init];
    });
    return reporter;
}

+ (void)startListeningShake {
    [[self sharedInstance] registerShakeEvents];
}

+ (void)stopListeningShake {
    [[self sharedInstance] unregisterShakeEvents];
}

- (void)registerShakeEvents {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShake:) name:DRPReporterShakeNotification object:nil];
    _listeningShake = YES;
}

- (void)unregisterShakeEvents {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DRPReporterShakeNotification object:nil];
    _listeningShake = NO;
}

+ (void)registerReporterViewControllerDelegate:(id<DRPReporterViewControllerDelegate>)reporterViewControllerDelegate {
    [[self sharedInstance] setReporterViewControllerDelegate:reporterViewControllerDelegate];
}

+ (void)setReporterDrawColor:(UIColor *)drawColor {
    [[self sharedInstance] setDrawColor:drawColor];
}

+ (void)setReporterDrawLineWidth:(CGFloat)drawLineWidth {
    [[self sharedInstance] setDrawLineWidth:drawLineWidth];
}

- (void)handleShake:(NSNotification *)notification {
    UIImage *screenshotImage = [self takeScreenshot];    
    DRPReporterViewController *viewController = [[DRPReporterViewController alloc] init];
    
    if (self.reporterViewControllerDelegate) {
        viewController.delegate = self.reporterViewControllerDelegate;
    } else {
        viewController.delegate = self;
    }
    
    [viewController setImage:screenshotImage];
    
    if (_drawColor) {
        viewController.drawColor = _drawColor;
    }
    
    if (_drawLineWidth > 0) {
        viewController.drawLineWidth = _drawLineWidth;
    }
    
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *presented = root;
    while (presented.presentedViewController) {
        presented = presented.presentedViewController;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    if ([presented isKindOfClass:[UINavigationController class]]) {
        UINavigationController *presentedNavVC = (UINavigationController *)presented;
        UIViewController *rootVC = presentedNavVC.viewControllers[0];
        if (![rootVC isKindOfClass:[DRPReporterViewController class]]) {
            [presented presentViewController:navController animated:YES completion:nil];
        }
    } else if (![presented isKindOfClass:[DRPReporterViewController class]]) {
        [presented presentViewController:navController animated:YES completion:nil];
    }
}

- (UIImage *)takeScreenshot {
    CGSize imageSize = CGSizeZero;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        imageSize = [UIScreen mainScreen].bounds.size;
    } else {
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:context];
        }
#else
        [window.layer renderInContext:context];
#endif
        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    BOOL isOS8OrGreater = ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending);
    if (isOS8OrGreater) {
        
        UIImageOrientation imageOrientation;
        switch (orientation) {
            case UIInterfaceOrientationUnknown:
            case UIInterfaceOrientationPortrait:
                imageOrientation = UIImageOrientationUp;
                break;
            
            case UIInterfaceOrientationLandscapeLeft:
                imageOrientation = UIImageOrientationLeft;
                break;
            
            case UIInterfaceOrientationLandscapeRight:
                imageOrientation = UIImageOrientationRight;
                break;
            
            case UIInterfaceOrientationPortraitUpsideDown:
                imageOrientation = UIImageOrientationDown;
                break;
        }
        
        image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:imageOrientation];
    }
    
    return image;
}

#pragma mark - HRPReporterViewControllerDelegate methods
- (void)reporterViewController:(DRPReporterViewController *)reporterViewController didFinishDrawingImage:(UIImage *)image withNoteText:(NSString *)noteText {
    [self showActivityViewControllerForReporterViewController:reporterViewController withImage:image noteText:noteText];
}

- (void)showActivityViewControllerForReporterViewController:(DRPReporterViewController *)reporterViewController withImage:(UIImage *)image noteText:(NSString *)text {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[ image, text ] applicationActivities:nil];
    [activityVC setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (completed) {
            [reporterViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [reporterViewController presentViewController:activityVC animated:YES completion:nil];
}

@end
