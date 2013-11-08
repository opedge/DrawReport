//
// HRPDrawView.m
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

#import "DRPDrawView.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const HRPDrawViewDefaultLineWidth = 3.0;
static NSUInteger const HRPDrawViewMaxCurvesInPath = 100;

#define HRPDrawViewDefaultLineColor [UIColor redColor]

@interface DRPDrawView() {
    CGPoint _lastPoint;
    CGPoint _prePreviousPoint;
    CGPoint _previousPoint;
    UIBezierPath *_drawingPath;
    NSUInteger _currentCurvesCount;
    BOOL _isTouchesBegan;
}

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation DRPDrawView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:imageView];
    _backgroundImageView = imageView;
    _backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundImageView.contentMode = UIViewContentModeCenter;
    
    self.backgroundColor = [UIColor clearColor];
    
    // defaults
    _lineWidth = HRPDrawViewDefaultLineWidth;
    _lineColor = HRPDrawViewDefaultLineColor;
    
    _drawingPath = [UIBezierPath bezierPath];
    [_drawingPath setLineWidth:_lineWidth];
    [_drawingPath setLineCapStyle:kCGLineCapRound];
}

- (void)flushDrawingPath {
    _currentCurvesCount = 0;
    [_drawingPath removeAllPoints];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _isTouchesBegan = YES;
    [self flushDrawingPath];
    UITouch *touch = [touches anyObject];
    _previousPoint = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isTouchesBegan) {
        if (self.delegate) {
            [self.delegate didStartDrawingInView:self];
        }
        _isTouchesBegan = NO;
    }
    
    UITouch *touch = [touches anyObject];
    
    _prePreviousPoint = _previousPoint;
    _previousPoint = [touch previousLocationInView:self];
    CGPoint currentPoint = [touch locationInView:self];
    
    CGPoint mid1 = [self calculateMidPointForPoint:_previousPoint andPoint:_prePreviousPoint];
    CGPoint mid2 = [self calculateMidPointForPoint:currentPoint andPoint:_previousPoint];
    _currentCurvesCount += 1;
    
    [_drawingPath moveToPoint:mid1];
    [_drawingPath addQuadCurveToPoint:mid2 controlPoint:_previousPoint];
    
    _lastPoint = mid2;
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self cacheCurrentDrawing];    
    if (self.delegate) {
        [self.delegate didStopDrawingInView:self];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self cacheCurrentDrawing];
}

- (void)cacheCurrentDrawing {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    [_backgroundImageView setImage:viewImage];
    UIGraphicsEndImageContext();
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    
    [_lineColor setStroke];
    [_drawingPath stroke];
    
    if (_currentCurvesCount > HRPDrawViewMaxCurvesInPath) {
        [self cacheCurrentDrawing];
        [self flushDrawingPath];
    }
}

- (CGPoint)calculateMidPointForPoint:(CGPoint)p1 andPoint:(CGPoint)p2 {
    return CGPointMake((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0);
}

- (void)clearDrawing {
    [_backgroundImageView setImage:nil];
    [self flushDrawingPath];
    [self setNeedsDisplay];
}

@end
