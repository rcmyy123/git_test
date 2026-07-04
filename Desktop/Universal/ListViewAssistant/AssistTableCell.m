//
//  AssistTableCell.m
//  Universal
//
//  Created by Mu-Sonic on 27/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "AssistTableCell.h"

@implementation AssistTableCell
{
    BOOL noImage;
    IBOutlet NSLayoutConstraint *constraintImageRight;
    IBOutlet NSLayoutConstraint *constraintImageBottom;
}

- (void)prepareForReuse
{
    _image.image = nil;
    _lblTitle.text = @"";
    _lblSummary.text = @"";
    _lblDate.text = @"";
    noImage = NO;
    [super prepareForReuse];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // we need to deactivate constraints (i.e. remove image) here to preserve cell layout on rotation
    [self updateImageConstraints];
}

- (void)setNoImage:(BOOL)value {
    noImage = value;
    [self updateImageConstraints];
}

- (void)updateImageConstraints {
    // ensure constraints has been loaded first
    if (!constraintImageRight || !constraintImageBottom)
        return;
    
    if (noImage) {
        [NSLayoutConstraint deactivateConstraints:@[constraintImageRight, constraintImageBottom]];
    } else {
        [NSLayoutConstraint activateConstraints:@[constraintImageRight, constraintImageBottom]];
    }
    _image.hidden = noImage;
}

@end
