//
//  MapsViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "MapsViewController.h"
#import "SWRevealViewController.h"
#import <MapKit/MapKit.h>
#import "AppDelegate.h"

#import "GMUGeoJSONParser.h"
#import "GMUGeometryRenderer.h"
#import "GMUGeometryContainer.h"
#import "GMUFeature.h"
#import "GMUPoint.h"

@implementation MapsViewController
{
    IBOutlet GMSMapView *mapView_;
    GMUGeoJSONParser *parser;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    mapView_.myLocationEnabled = YES;
    mapView_.settings.compassButton = YES;
    mapView_.delegate = self;
    
    if (![[_params objectAtIndex:0] hasPrefix:@"http"]) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:[_params objectAtIndex:0] ofType:@"geojson" inDirectory:@"Local"];
        NSURL *url = [NSURL fileURLWithPath:path];
        parser = [[GMUGeoJSONParser alloc] initWithURL:url];
        [self parseAndDisplay];
    } else {
        NSURL *url = [[NSURL alloc] initWithString:[_params objectAtIndex:0]];
        NSLog(@"Retrieving geojson from url: %@", [_params objectAtIndex:0]);
        
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.loadingIndicator startAnimating];
        self.navigationItem.titleView = self.loadingIndicator;
            
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:url
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.navigationItem.titleView = nil;
                            
                            if (error) {
                                NSLog(@"Error retreiving geojson: %@", error);
                                
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
                                
                                UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
                                [alertController addAction:ok];
                                [self presentViewController:alertController animated:YES completion:nil];
                            } else {
                                parser = [[GMUGeoJSONParser alloc] initWithData:data];
                                [self parseAndDisplay];
                            }
                        });
                        
                    }] resume];
        
    }
}

- (void)parseAndDisplay {
    [parser parse];
    GMUGeometryRenderer *renderer = [[GMUGeometryRenderer alloc] initWithMap:mapView_
                                                                  geometries:parser.features];
    [renderer render];
    
    //Copy the properties found in the parser to the GMS objects on the map
    NSArray<GMSOverlay *> *overlays = [renderer mapOverlays];
    for (GMSOverlay *overlay in overlays){
        GMUFeature *feature = [parser.features objectAtIndex: [overlays indexOfObject:overlay]];
        overlay.userData = feature.properties;
        if ([feature.properties valueForKey:@"name"] != nil)
            overlay.title = [feature.properties valueForKey:@"name"];
    }
    
    [self focusMapToShowAllMarkers];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    if ([marker.userData valueForKey:@"url"] != nil)
        [AppDelegate openUrl:[marker.userData valueForKey:@"url"] withNavigationController:self.navigationController];
}

- (void)mapView:(GMSMapView *)mapView didCloseInfoWindowOfMarker: (GMSMarker *)marker {
    self.navigationController.navigationBar.topItem.rightBarButtonItems = nil;
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    marker.appearAnimation = kGMSMarkerAnimationPop;
    [mapView_ setSelectedMarker:marker];
    if ([marker.userData valueForKey:@"snippet"] != nil)
       marker.snippet = [marker.userData valueForKey:@"snippet"];
    else if ([marker.userData valueForKey:@"description"] != nil)
        marker.snippet = [marker.userData valueForKey:@"description"];
    else if ([marker.userData valueForKey:@"popupContent"] != nil)
        marker.snippet = [marker.userData valueForKey:@"popupContent"];
    [mapView_ animateWithCameraUpdate:[GMSCameraUpdate setTarget:marker.position]];
    
    //Init navigationbar items
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn_navigate"] style:UIBarButtonItemStylePlain target:self action:@selector(navigateTo)];
    if ([marker.userData valueForKey:@"url"] != nil) {
        UIBarButtonItem *openButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"open", nil) style:UIBarButtonItemStylePlain target:self action:@selector(openUrl)];
        self.navigationController.navigationBar.topItem.rightBarButtonItems = @[searchButton, openButton];
    } else
        self.navigationController.navigationBar.topItem.rightBarButtonItem = searchButton;

    
    return true;
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay{
    //NSLog(@"Tapped overlay %@", overlay);
}

- (void)focusMapToShowAllMarkers
{
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
    
    for (GMUFeature *feature in parser.features) {
        if ([feature.geometry isKindOfClass:[GMUPoint class]])
            bounds = [bounds includingCoordinate:((GMUPoint *)feature.geometry).coordinate];
    }
    
    [mapView_ animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:100.0f]];
}

- (void)openUrl {
    [AppDelegate openUrl:[[mapView_ selectedMarker].userData valueForKey:@"url"] withNavigationController:self.navigationController];
}

- (void)navigateTo {
    CLLocationCoordinate2D coordinate = [mapView_ selectedMarker].position;
    
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)])
    {
        // Create an MKMapItem to pass to the Maps app
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                       addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:[mapView_ selectedMarker].title];
        // Pass the map item to the Maps app
        [mapItem openInMapsWithLaunchOptions:nil];
    }
}

//- (void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated] ;
//    [mapView_ clear];
//    [mapView_ removeFromSuperview] ;
//    mapView_ = nil ;
//    self.view=nil;
//}

//- (void)dealloc{
//    [mapView_ clear];
//    [mapView_ removeFromSuperview] ;
//    mapView_ = nil ;
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
