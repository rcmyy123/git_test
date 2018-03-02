//
//  NavbarGradientView.h
//  Universal
//
//  Created by Mu-Sonic on 29/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavbarGradientView : UIView

@property (strong, nonatomic) IBOutlet UIView *plainView;

- (void)turnTransparencyOn:(BOOL)on animated:(BOOL)animated;

@end
