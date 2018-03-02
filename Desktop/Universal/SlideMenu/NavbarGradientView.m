//
//  NavbarGradientView.m
//  Universal
//
//  Created by Mu-Sonic on 29/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "NavbarGradientView.h"

//IB_DESIGNABLE
@implementation NavbarGradientView
{
    BOOL isTransparent;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat[8]){0.0f, 0.0f, 0.0f, 0.7f, 0.0f, 0.0f, 0.0f, 0.0f},
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

- (void)turnTransparencyOn:(BOOL)on animated:(BOOL)animated
{
    if (on == isTransparent) {
        return; // already in that state
    }

    isTransparent = on;
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _plainView.alpha = on ? 0 : 1;
        } completion:^(BOOL finished) {
        }];
    } else {
        _plainView.alpha = on ? 0 : 1;
    }
}

@end
