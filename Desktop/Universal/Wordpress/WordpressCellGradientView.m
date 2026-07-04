//
//  WordpressCellGradientView.m
//  Universal
//
//  Created by Mu-Sonic on 27/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordpressCellGradientView : UIView
@end

@implementation WordpressCellGradientView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat[8]){0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.7f},
     (const CGFloat[2]){0.0f, 1.0f},
     2);
    
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)),
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)),
                                0);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    CGContextRestoreGState(context);
}

@end
