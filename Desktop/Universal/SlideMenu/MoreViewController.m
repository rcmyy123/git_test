//
//  MoreViewController.h
//  Universal
//
//  Created by Mu-Sonic on 25/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "MoreViewController.h"
#import "FrontNavigationController.h"
#import "Tab.h"

@interface MoreViewController ()

@property (nonatomic) NSArray *timeZoneNames;

@end

@implementation MoreViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *MyIdentifier = @"MyIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }

	// Set up the cell.
    Tab *item = self.items[indexPath.row];
	NSString *controllerTitle = item.name;
	cell.textLabel.text = controllerTitle;

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tab *item = self.items[indexPath.row];
    UIViewController *controller = [FrontNavigationController createViewController:item withStoryboard:self.storyboard];
    
    [self.navigationController pushViewController:controller animated:YES];
}

@end
