//
//  TumblrViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#define iPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)

#import "TumblrViewController.h"
#import "TumblrViewCell.h"
#import "TumblrImageViewController.h"
#import "UIImageView+WebCache.h"
#import "SWRevealViewController.h"
#import "FooterView.h"
#import "AppDelegate.h"

#define LOADING_CELL_IDENTIFIER @"LoadingItemCell"
#define ITEMS_PAGE_SIZE 4


int StartNumber = 0;

@interface TumblrViewController ()
{
    IBOutlet UIScrollView *scrollViewImage;
    IBOutlet UIView *viewImage;
    IBOutlet UIImageView *largeImageView;
    
    int fooIndex;
    bool reachedEnd;
    NSString *stringImage;
}
@end

@implementation TumblrViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    

    
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];

    // fetch data
    StartNumber = 0;
    [self fetchDataWithNumber:StartNumber];
    StartNumber += 30;
}


- (void)viewDidLayoutSubviews
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    FooterView *footer = nil;
    
    if([kind isEqual:UICollectionElementKindSectionFooter])
    {
        footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        
        [footer.activityIndicator startAnimating];
    }
    
    return footer;
}

// do not forget header & footer size

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    //header size
    if (!reachedEnd){
        CGSize size = {self.collectionView.bounds.size.width,50};
        return size;
    } else {
        CGSize size = {self.collectionView.bounds.size.width,0};
        return size;
    }
}

-(void)fetchDataWithNumber:(int)number{
    
    NSString *strUrl=[NSString stringWithFormat:@"https://%@.tumblr.com/api/read/json?num=30&start=%i",self.params[0],number] ;
    NSLog(@"Url: %@", strUrl);
    
    NSURL *url = [[NSURL alloc]initWithString:strUrl];
    
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc]initWithURL:url];
    
    [req setHTTPMethod:@"GET"];
    
    //    [req setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:req
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                if (data == nil) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    reachedEnd = true;
                    
                    [self.collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:0]];
                    
                    return ;
                } else {
                    
                    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    //NSLog(@"Response data = %@", str);
                    
                    // NSString *newString = [str substringToIndex:[str length]-1];
                    
                    NSMutableString *strrrrr = [NSMutableString stringWithString:str];
                    
                    NSString *stringWithoutSpaces = [strrrrr
                                                     stringByReplacingOccurrencesOfString:@"var tumblr_api_read = " withString:@""];
                    stringWithoutSpaces = [stringWithoutSpaces
                                           stringByReplacingOccurrencesOfString:@"]}]};" withString:@"]}]}"];
                    
                    NSData *dataNew = [stringWithoutSpaces dataUsingEncoding:NSUTF8StringEncoding];
                    
                    id jsonFecth=[NSJSONSerialization JSONObjectWithData:dataNew options:0 error:nil];
                    
                    json = jsonFecth;
                    
                    if (!imagesArray){
                        imagesArray=[[NSMutableArray alloc]init];
                        //imagesArray = [jsonFecth valueForKey:@"posts"];
                    }
                    for (id result in [jsonFecth valueForKey:@"posts"]) {
                        [imagesArray addObject:result];
                    }
                    
                    NSLog(@"ARRAY COUNT %lu ",(unsigned long)imagesArray.count);
                    
                    [self.collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                }

                
            }] resume];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return imagesArray.count ;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TumblrViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    {
        cell.backgroundColor = [UIColor whiteColor];
        
        UIImageView *image = cell.cellImage;
        image.contentMode = UIViewContentModeScaleAspectFill;
        image.clipsToBounds = YES;
        image.tag = indexPath.row;
        
        //  [images setImageWithURL:[NSURL URLWithString:[[imagesArray objectAtIndex:indexPath.row]valueForKey:@"photo-url-100"]] placeholderImage:nil];
        NSString *url;
        
        @try {
            url=[[imagesArray objectAtIndex:indexPath.row]valueForKey:@"photo-url-1280"];
            [image sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"wf.png"]];
        }
        @catch (NSException *exception)
        {
            url=[[imagesArray objectAtIndex:indexPath.row]valueForKey:@"photo-url-500"];
            [image sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"wf.png"]];
            
        }
        @finally { }
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TumblrImageViewController *imageVC = (TumblrImageViewController *)((UINavigationController *)segue.destinationViewController).topViewController;
    imageVC.imagesArray = imagesArray;
    imageVC.fooIndex = ((TumblrViewCell *)sender).cellImage.tag;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize screen = [UIScreen mainScreen].bounds.size;
    NSInteger boxSize = ( MIN(screen.width, screen.height) - 20 ) / 3;
    return CGSizeMake(boxSize, boxSize);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height)
    {
        
        NSString *str= [json valueForKey:@"posts-total"];
        
        int value=(int)[str integerValue];
        if (StartNumber < value) {
            reachedEnd = false;
            [self fetchDataWithNumber:StartNumber];
        } else {
            reachedEnd = true;
            [self.collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:0]];
        }
        
        StartNumber = StartNumber + 30;
        
        // we are at the end
    }
}

@end
