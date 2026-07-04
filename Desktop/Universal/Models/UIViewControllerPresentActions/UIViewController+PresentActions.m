//
//  UIViewController+Share.m
//  Universal
//
//  Created by Mu-Sonic on 13/11/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIViewController+PresentActions.h"

@implementation UIViewController (PresentActions)

- (void)presentActions:(NSArray *)activityItems sender:(id)sender {
    //-- initialising the activity view controller
    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:activityItems
                                     applicationActivities:nil];

    //-- define the activity view completion handler
    avc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
        if (completed) {
            NSLog(@"Selected activity was performed.");
        } else {
            if (activityType == NULL) {
                NSLog(@"User dismissed the view controller without making a selection.");
            } else {
                NSLog(@"Activity was not performed.");
            }
        }
    };
    
    if ([avc respondsToSelector:@selector(popoverPresentationController)]) {
        // adaptive popover (iOS8+)
        avc.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popPC = avc.popoverPresentationController;
        if ([sender class] == [UIBarButtonItem class]) {
            popPC.barButtonItem = sender;
        } else {
            UIView *sourceView = sender;
            if (!sourceView) return;

            popPC.sourceView = sourceView;
            popPC.sourceRect = sourceView.frame;
        }
        popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
        [self presentViewController:avc animated:YES completion:nil];
    }
    else
    {   // legacy pre-iOS8 popover
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            // display modally in iPhone
            [self presentViewController:avc animated:YES completion:nil];
        } else {
            // display in a popover on iPad
            avc.modalPresentationStyle = UIModalPresentationPopover;
            avc.popoverPresentationController.sourceView = sender;
            [self presentViewController:avc animated:YES completion:nil];
        }
    }
}

@end
