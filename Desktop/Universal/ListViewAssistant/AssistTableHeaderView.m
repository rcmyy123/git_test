//
// AssistTableHeaderView.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//
// Implements: STTableViewController
// Copyright (C) 2011 by BJ Basañes, http://shikii.net under MIT
//

#import "AssistTableHeaderView.h"

@implementation AssistTableHeaderView

@synthesize title;
@synthesize activityIndicator;

- (void) awakeFromNib
{
    [super awakeFromNib];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];
}

@end
