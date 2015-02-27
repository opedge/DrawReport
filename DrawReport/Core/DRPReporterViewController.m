//
// HRPReporterViewController.m
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

#import "DRPReporterViewController.h"
#import "DRPDrawView.h"
#import "DRPNoteView.h"
#import "DRPReporter.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <QuartzCore/QuartzCore.h>

static NSTimeInterval const HRPReporterViewControllerShowBarsDelay = 4;

static CGFloat const HRPReporterViewControllerNoteBottomHeight = 44;

static CGFloat const HRPReporterViewControllerNoteViewWidthPercent = 80;
static CGFloat const HRPReporterViewControllerNoteViewHeightPercent = 20;

@interface DRPReporterViewController() <DRPDrawViewDelegate> {
    UIInterfaceOrientation _initialInterfaceOrientation;
    NSTimer *_showBarsTimer;
}

@property (nonatomic, weak) DRPDrawView *drawView;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) DRPNoteView *noteView;

@end

@implementation DRPReporterViewController

- (void)setupViews {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    _imageView = imageView;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeCenter;    
    
    CGRect drawRect;
    if (UIInterfaceOrientationIsPortrait(_initialInterfaceOrientation)) {
        drawRect = self.view.bounds;
    } else {
        drawRect = CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width);
    }
    
    DRPDrawView *drawView = [[DRPDrawView alloc] initWithFrame:drawRect];
    drawView.delegate = self;
    [self.view addSubview:drawView];
    _drawView = drawView;
    _drawView.contentMode = UIViewContentModeCenter;
    
    CGSize noteSize = CGSizeMake(self.view.bounds.size.width * HRPReporterViewControllerNoteViewWidthPercent / 100.0, self.view.bounds.size.height * HRPReporterViewControllerNoteViewHeightPercent / 100.0);
    DRPNoteView *noteView = [[DRPNoteView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - noteSize.width) / 2.0,
                                                                          self.view.frame.size.height - HRPReporterViewControllerNoteBottomHeight,
                                                                          noteSize.width,
                                                                          noteSize.height)];
    noteView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:noteView];
    _noteView = noteView;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.cancelsTouchesInView = YES;
    [self.drawView addGestureRecognizer:tap];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    // if noteview is shown - simply hide it to intial state
    if ([_noteView.textView isFirstResponder]) {
        [_noteView.textView resignFirstResponder];
        [self showNoteView];
    } else {
        UINavigationController *navigationController = self.navigationController;
        if (![navigationController isNavigationBarHidden]) {
            [navigationController setNavigationBarHidden:YES animated:YES];
            [self hideNoteView];
        } else {
            [navigationController setNavigationBarHidden:NO animated:YES];
            [self showNoteView];
        }
        
        [self resetShowBarsTimer];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self resetShowBarsTimer];
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect rect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = rect.size.height;
    
    CGFloat noteCenterY = (self.view.frame.size.height - keyboardHeight) / 2.0 + 30;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
        _noteView.center = CGPointMake(_noteView.center.x, noteCenterY);
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self showNoteView];
}

- (void)startShowBarsTimer {
    _showBarsTimer = [NSTimer scheduledTimerWithTimeInterval:HRPReporterViewControllerShowBarsDelay target:self selector:@selector(showBars) userInfo:nil repeats:NO];
}

- (void)resetShowBarsTimer {
    if (_showBarsTimer) {
        [_showBarsTimer invalidate];
        _showBarsTimer = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED < 70000)
    self.wantsFullScreenLayout = YES;
#endif
    
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)
    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        [self setAutomaticallyAdjustsScrollViewInsets:NO];
    }
#endif
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.title = @"Report";
    
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonClicked)];
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonClicked:)];
    self.navigationItem.rightBarButtonItem = shareButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleShake:) name:DRPReporterShakeNotification object:nil];
    
    _initialInterfaceOrientation = self.interfaceOrientation;
    
    [self setupViews];
    [_imageView setImage:_image];
    
    if (_drawColor) {
        _drawView.lineColor = _drawColor;
    }
    
    if (_drawLineWidth > 0) {
        _drawView.lineWidth = _drawLineWidth;
    }
}

- (void)dealloc {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:DRPReporterShakeNotification object:nil];
    [defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleShake:(NSNotification *)notification {
    [_drawView clearDrawing];
}

- (void)showBars {
    UINavigationController *navigationController = self.navigationController;
    if ([navigationController isNavigationBarHidden]) {
        [navigationController setNavigationBarHidden:NO animated:YES];
        [self showNoteView];
    }
}

- (void)shareButtonClicked:(id)sender {
    [self resetShowBarsTimer];
    
    [self.view endEditing:YES];
    UIImage *backgroundImage = self.image;
    
    UIGraphicsBeginImageContextWithOptions(backgroundImage.size, YES, 0);
    [backgroundImage drawAtPoint:CGPointZero];
    
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000)
    if ([self.drawView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self.drawView drawViewHierarchyInRect:(CGRect){ CGPointZero, backgroundImage.size } afterScreenUpdates:NO];
    } else {
        [self.drawView.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
#else
    [self.drawView.layer renderInContext:UIGraphicsGetCurrentContext()];
#endif
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.delegate reporterViewController:self didFinishDrawingImage:resultImage withNoteText:self.noteView.textView.text];
}

- (void)hideNoteView {
    if ([_noteView.textView isFirstResponder]) {
        [_noteView.textView resignFirstResponder];
    }
    
    CGRect frame = _noteView.frame;
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
        _noteView.frame = CGRectMake(frame.origin.x,
                                     self.view.frame.size.height,
                                     frame.size.width,
                                     frame.size.height);
    } completion:nil];
}

- (void)showNoteView {
    CGRect frame = _noteView.frame;
    [UIView animateWithDuration:0.25f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         _noteView.frame = CGRectMake(frame.origin.x,
                                                      self.view.frame.size.height - HRPReporterViewControllerNoteBottomHeight,
                                                      frame.size.width,
                                                      frame.size.height);
                     }
                     completion:nil];
}

- (void)cancelButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (CGFloat)angleFromInitialOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return M_PI_2;
            
        case UIInterfaceOrientationLandscapeRight:
            return -M_PI_2;
        
        case UIDeviceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
            return 0;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGFloat angle = [self angleFromInitialOrientation:_initialInterfaceOrientation];
    
    CGAffineTransform transform;
    switch (toInterfaceOrientation) {
        case UIDeviceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
            transform = CGAffineTransformMakeRotation(-angle);
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2 - angle);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2 - angle);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI - angle);
            break;
    }
    
    _imageView.transform = transform;
    _imageView.center = self.view.center;
    
    _drawView.transform = transform;
    _drawView.center = self.view.center;
}

#pragma mark - DRPDrawViewDelegate methods
- (void)didStartDrawingInView:(DRPDrawView *)drawView {
    [self resetShowBarsTimer];
    UINavigationController *navigationController = self.navigationController;
    if (![navigationController isNavigationBarHidden]) {
        [navigationController setNavigationBarHidden:YES animated:YES];
        [self hideNoteView];
    }
}

- (void)didStopDrawingInView:(DRPDrawView *)drawView {
    [self startShowBarsTimer];
}

@end
