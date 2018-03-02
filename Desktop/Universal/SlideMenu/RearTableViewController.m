//
//  RearTableViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "RearTableViewController.h"
#import "RearViewCell.h"
#import "SWRevealViewController.h"
#import "KILabel.h"
#import "WBInAppHelper.h"

#import "ConfigParser.h"
#import "AppDelegate.h"
#import "Config.h"
#import "Section.h"
#import "Item.h"
#import "Tab.h"

#import "FrontNavigationController.h"
#import "FMNIIListTVC.h"

@interface RearTableViewController (){
    UIView *statusBarBackground;
}

@end

@implementation RearTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    //self.config = [Config config];
    
    if (![ABOUT_TEXT isEqual: @""]){
        
        //UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        [_aboutButton setTitle:NSLocalizedString(@"about_button", nil)
                      forState:UIControlStateNormal];
        [_aboutButton setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [_aboutButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_aboutButton sizeToFit];
        _aboutButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _aboutButton.layer.borderWidth = 1.0f;
        _aboutButton.layer.cornerRadius = 15.0f;
        [_aboutButton addTarget:self
                         action:@selector(launchAbout:)
               forControlEvents:UIControlEventTouchDown];
        self.tableView.tableFooterView = _footerView;
    }
    
    if (!APP_DRAWER_HEADER) {
        [self.tableView.tableHeaderView removeFromSuperview];
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), 1.0f)];
        [self.tableView reloadData];
    }
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    //Hacky way to set toolbar background
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    CGFloat height = MIN(statusBarSize.width, statusBarSize.height);
    if (!statusBarBackground) {
        statusBarBackground = [[UIView alloc] initWithFrame: CGRectMake ( 0, 0, self.view.frame.size.width, height)];
        statusBarBackground.backgroundColor = MENU_BACKGROUND_COLOR_1;
        statusBarBackground.alpha = 0.7;
        [self.navigationController.view addSubview:statusBarBackground];
    } else {
        [statusBarBackground setFrame:CGRectMake ( 0, 0, self.view.frame.size.width, height)];
    }
    
}

- (void) unlockAppDialog {
    
    NSString *price = [WBInAppHelper priceStringFromProductId:IN_APP_PRODUCT];
    
    NSString *buyLabel;
    if ([price isEqualToString:@"Error"]) {
#if TARGET_OS_SIMULATOR
        //Simulator
        buyLabel = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"buy", nil), @"(Test)"];
#else
        // Device
        buyLabel = @"IAP not available";
#endif
    } else {
        buyLabel = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"buy", nil), price];
    }
    
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"purchase_dialog_title", nil) message:NSLocalizedString(@"purchase_dialog_text", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:buyLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [WBInAppHelper payProduct:IN_APP_PRODUCT resBlock:^(BOOL success, NSError *err){
            if (success) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"purchase_dialog_title", nil) message:NSLocalizedString(@"purchase_dialog_text_thanks", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"purchase_dialog_title", nil) message:NSLocalizedString(@"purchase_dialog_text_fail", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            }
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"purchase_dialog_restore", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [WBInAppHelper restorePayments:^(BOOL success, NSError *err){
            if (success) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"purchase_dialog_title", nil) message:NSLocalizedString(@"purchase_dialog_restore_thanks", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"purchase_dialog_title", nil) message:NSLocalizedString(@"purchase_dialog_restore_fail", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            }
        }];
    }]];

    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void) launchAbout:(UIButton *)paramSender{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"about_dialog_title", nil) message:ABOUT_TEXT preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"about_open", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",ABOUT_URL]] options:@{} completionHandler:nil];
    }]];
    
    if ([IN_APP_PRODUCT length] > 0 && ![AppDelegate hasPurchased])
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"about_purchase", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self unlockAppDialog];
        }]];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

-(void)myItemsClicked{
}

-(void)settingBtnClicked {
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSInteger sections = [Config config].count;
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Section *sec = [[Config config] objectAtIndex: section];
    
    return [sec.items count];
}

// item view
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RearViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    Section *section = [[Config config] objectAtIndex: indexPath.section];
    Item *item = [section.items objectAtIndex:indexPath.row];
    
    cell.textLabel.text = item.name;
    
    if (item.icon != nil){
        cell.imageView.image = [UIImage imageNamed:item.icon];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual: self.selectedIndexPath]) {
        cell.backgroundColor = SELECTED_COLOR;
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
}

//table head view
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    
    UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 300, 40)];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.font = [UIFont systemFontOfSize:18];
    lbl.textColor = [UIColor lightTextColor];
    Section *sec = [[Config config] objectAtIndex: section];
    lbl.text = sec.name;
    
    [_headerView addSubview:lbl];
    
    return _headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([((Section* ) [[Config config]  objectAtIndex: section]).name  isEqual: @""])
        return CGFLOAT_MIN;
    
    return 35;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if ([identifier isEqualToString:@"showFeed"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Section *section = [[Config config] objectAtIndex: indexPath.section];
        Item *item = [section.items objectAtIndex:indexPath.row];
        
        Tab *firstTab = [item.tabs objectAtIndex: 0];
        if ([firstTab.type caseInsensitiveCompare:@"custom"] == NSOrderedSame){
            NSString *url = [firstTab.params objectAtIndex:0];
            [AppDelegate openUrl:url withNavigationController:nil];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
            return NO;
        }
        if (item.iap && [IN_APP_PRODUCT length] > 0 && ![AppDelegate hasPurchased]){
            [self unlockAppDialog];
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showFeed"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        FrontNavigationController *frontNav = (FrontNavigationController *)segue.destinationViewController;
        frontNav.selectedIndexPath = indexPath;
        
        RearTableViewController *rearVC = (RearTableViewController *)segue.sourceViewController;
        NSIndexPath *oldIndexPath = rearVC.selectedIndexPath;
        rearVC.selectedIndexPath = indexPath;
        
        [self.revealViewController revealToggle:nil];
        [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
