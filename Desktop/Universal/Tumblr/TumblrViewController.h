//
//  TumblrViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TumblrViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    NSMutableArray *imagesArray;
    NSInteger _currentPage;
    id json;
}

@property(strong,nonatomic)NSArray *params;

@end
