//
// AssistTableFooterView.h
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//
// Implements: STTableViewController
// Copyright (C) 2011 by BJ Basañes, http://shikii.net under MIT
//

#import <UIKit/UIKit.h>


@interface AssistTableFooterView : UIView {
    
  UIActivityIndicatorView *activityIndicator;
  UILabel *infoLabel;
}

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UILabel *infoLabel;

@end
