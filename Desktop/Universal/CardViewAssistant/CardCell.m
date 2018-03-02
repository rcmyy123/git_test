//
//  CardCell.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//  Implements Copyright (c) 2014 Audrey Manzano. All rights reserved.
//

#import "CardCell.h"
#import "NSString+HTML.h"
#import "UIViewController+PresentActions.h"
#import "AppDelegate.h"

@implementation CardCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
       ///
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _photoView.image = nil;
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

- (IBAction)open:(id)sender {
    [AppDelegate openUrl:_shareUrl withNavigationController:self.parentController.navigationController];
}

- (IBAction)share:(id)sender
{
    NSString *text = _shareUrl;
    NSArray *activityItems = [NSArray arrayWithObjects:text,  nil];
    
    [_parentController presentActions:activityItems sender:sender];
}

- (void)updateImageAspectRatio
{
    [_photoView updateAspectRatio];
    
    // in current implementation the cell will be reloaded anyway
    // [self setNeedsUpdateConstraints];
    // [self setNeedsLayout];
}

@end
