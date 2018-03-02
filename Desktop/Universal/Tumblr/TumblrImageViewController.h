//
//  TumblrImageViewController.h
//  Universal
//
//  Created by Mu-Sonic on 10/11/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

@interface TumblrImageViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray *imagesArray;
@property long fooIndex;

@end
