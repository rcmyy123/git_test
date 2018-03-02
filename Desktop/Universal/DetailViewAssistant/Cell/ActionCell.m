//
//  ActionCell.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  Implements TGFoursquareLocationDetail-Demo
//  Copyright (c) 2013 Thibault Guégan. All rights reserved.
//

#import "ActionCell.h"
#import "AppDelegate.h"

@implementation ActionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        //Btn share
        _btnSave.layer.borderColor = self.tintColor.CGColor;
        _btnSave.layer.borderWidth = 1.0f;
        _btnSave.layer.cornerRadius = 15.0f;
        
        //Btn checkin
        _btnOpen.layer.borderColor = self.tintColor.CGColor;
        _btnOpen.layer.borderWidth = 1.0f;
        _btnOpen.layer.cornerRadius = 15.0f;
    }
    return self;
}

- (void)awakeFromNib
{
    //Btn save
    _btnSave.layer.borderColor = self.tintColor.CGColor;
    _btnSave.layer.borderWidth = 1.0f;
    _btnSave.layer.cornerRadius = 15.0f;
    
    //Btn save
    _btnOpen.layer.borderColor = self.tintColor.CGColor;
    _btnOpen.layer.borderWidth = 1.0f;
    _btnOpen.layer.cornerRadius = 15.0f;
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)share:(id)sender{
    if(!_disableDefaultSaveAction)
        [_actionDelegate share:_btnSave];
}

- (IBAction)open:(id)sender {
    [_actionDelegate open];
}

@end
