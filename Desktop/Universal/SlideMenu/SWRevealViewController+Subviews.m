//
//  SWRevealViewController+Subviews.m
//  Universal
//
//  Created by Mu-Sonic on 28/11/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "SWRevealViewController+Subviews.h"

@implementation SWRevealViewController (SWRevealViewController_Subviews)

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.frontOverlayView) {
        self.frontOverlayView.frame = self.frontViewController.view.bounds;
        for (UIView *subview in self.frontOverlayView.subviews) {
            subview.frame = self.frontOverlayView.bounds;
        }
    }
}

@end
