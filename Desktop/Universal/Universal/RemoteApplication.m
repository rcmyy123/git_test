//
//  RemoteApplication.m
//  Universal
//
//  Created by Mark on 05-12-15.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "RemoteApplication.h"
#import "AppDelegate.h"
#import <MediaPlayer/MPNowPlayingInfoCenter.h>


@implementation RemoteApplication

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        
        NSLog(@"Remove Event Received. Sending to appropiate view controller.");
        
        UIViewController *active = [appDelegate activePlayerController];
        if (active)
            [active remoteControlReceivedWithEvent:event];
        else
            NSLog(@"No controller to process action");
    }
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

@end
