//
//  TumblrImageViewController.m
//  Universal
//
//  Created by Mu-Sonic on 10/11/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "TumblrImageViewController.h"
#import "UIViewController+PresentActions.h"

@interface TumblrImageViewController ()

@end

@implementation TumblrImageViewController
{
    IBOutlet UIScrollView *scrollViewImage;
    IBOutlet UIImageView *largeImageView;

    bool reachedEnd;
    NSString *stringImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // set up gesture recognizers
    UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeHandle:)];
    rightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [largeImageView addGestureRecognizer:rightRecognizer];
    
    // Left Gesture
    UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeHandle:)];
    leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [largeImageView addGestureRecognizer:leftRecognizer];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.delegate = self;
    //    [largeImageView setUserInteractionEnabled:YES];
    [largeImageView addGestureRecognizer:singleTap];

    // display selected image
    stringImage = [[_imagesArray objectAtIndex:_fooIndex] valueForKey:@"photo-url-1280"];
    [largeImageView sd_setImageWithURL:[NSURL URLWithString:stringImage] placeholderImage:[UIImage imageNamed:@"wf.png"]];
}

#pragma mark - Left & Right UISwipeGestures

- (void) rightSwipeHandle:(UISwipeGestureRecognizer *)gestureRecognizer
{

    if (_fooIndex + 1 >= [_imagesArray count])
    {

    }
    else
    {
        _fooIndex = _fooIndex + 1;
        [self animationStart];

        NSLog(@"FooIndex %ld", _fooIndex);
        stringImage = [NSString stringWithFormat:@"%@", [[_imagesArray objectAtIndex:_fooIndex] valueForKey:@"photo-url-1280"]];
        NSLog(@"%lu", (unsigned long)[_imagesArray count]);
        [largeImageView sd_setImageWithURL:[NSURL URLWithString:stringImage] placeholderImage:[UIImage imageNamed:@"wf.png"]];

    }

}

- (void) leftSwipeHandle:(UISwipeGestureRecognizer *) gestureRecognizer
{
    if (_fooIndex > 0){
           [self animationStartFromLeft];
    }

    if (_fooIndex < 0)
    {
        _fooIndex = 0;
    }
    else if (_fooIndex > [_imagesArray count])
    {
        //        fooIndex = _fooIndex - 2;
        _fooIndex = (int)[_imagesArray count] - 1;

        stringImage = [NSString stringWithFormat:@"%@", [[_imagesArray objectAtIndex:_fooIndex] valueForKey:@"photo-url-1280"]];

        [largeImageView sd_setImageWithURL:[NSURL URLWithString:stringImage] placeholderImage:[UIImage imageNamed:@"wf.png"]];
    }
    else
    {
        if (_fooIndex == 0) {

        }
        else
        {
            _fooIndex = _fooIndex - 1;
        }

        stringImage = [NSString stringWithFormat:@"%@", [[_imagesArray objectAtIndex:_fooIndex] valueForKey:@"photo-url-1280"]];

        [largeImageView sd_setImageWithURL:[NSURL URLWithString:stringImage] placeholderImage:[UIImage imageNamed:@"wf.png"]];
    }
}

- (void) animationStart
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.2;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromRight; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    
    [scrollViewImage.layer addAnimation:transition forKey:nil];
}

- (void) animationStartFromLeft
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.2;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    
    [scrollViewImage.layer addAnimation:transition forKey:nil];
}

- (void)tapDetected {
    NSLog(@"single Tap on imageview");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)close:(id)sender {
    [self tapDetected];
}

- (IBAction)btnShare:(id)sender {
    NSArray *activityItems = [NSArray arrayWithObjects:largeImageView.image,  nil];
    
    [self presentActions:activityItems sender:sender];
}

- (IBAction)btnSave:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"message", nil) message:NSLocalizedString(@"image_save_succesfull", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImageWriteToSavedPhotosAlbum(largeImageView.image, nil, nil, nil);
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
