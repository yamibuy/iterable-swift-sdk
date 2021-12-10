//
//  DeepLinkHandler.m
//  objc-sample-app
//
//  Created by Tapash Majumder on 6/21/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

#import "DeepLinkHandler.h"
#import "CoffeeType.h"
#import "CoffeeViewController.h"
#import "CoffeeListTableViewController.h"

@implementation DeepLinkHandler

+ (BOOL)handleURL:(NSURL *)url {
    NSString *page = url.lastPathComponent.lowercaseString;
    
    if ([page isEqualToString:@"mocha"]) {
        [DeepLinkHandler showCoffee:CoffeeType.mocha];
        return YES;
    } else if ([page isEqualToString:@"latte"]) {
        [DeepLinkHandler showCoffee:CoffeeType.latte];
        return YES;
    } else if ([page isEqualToString:@"cappuccino"]) {
        [DeepLinkHandler showCoffee:CoffeeType.cappuccino];
        return YES;
    } else if ([page isEqualToString:@"black"]) {
        [DeepLinkHandler showCoffee:CoffeeType.black];
        return YES;
    } else if ([page isEqualToString:@"coffee"]) {
        NSString *query = [DeepLinkHandler parseQueryFromURL: url];
        [DeepLinkHandler showCoffeeListWithQuery: query];
        return YES;
    } else {
        [UIApplication.sharedApplication openURL: url options: @{} completionHandler: nil];
        return NO;
    }
}

+ (void)showCoffee:(CoffeeType *)coffeeType {
    UINavigationController *rootNav = (UINavigationController *) UIApplication.sharedApplication.keyWindow.rootViewController;
    if (rootNav != nil) {
        [rootNav popToRootViewControllerAnimated: false];

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        CoffeeViewController *viewController = (CoffeeViewController *) [storyboard instantiateViewControllerWithIdentifier: @"CoffeeViewController"];
        viewController.coffeeType = coffeeType;
        
        [rootNav pushViewController: viewController animated: true];
    }
}

+ (void)showCoffeeListWithQuery:(NSString *)query {
    UINavigationController *rootNav = (UINavigationController *) UIApplication.sharedApplication.keyWindow.rootViewController;

    if (rootNav != nil) {
        [rootNav popToRootViewControllerAnimated: true];
        CoffeeListTableViewController *coffeeListVC = (CoffeeListTableViewController *) rootNav.viewControllers[0];
        if (coffeeListVC != nil) {
            coffeeListVC.searchTerm = query;
        }
    }
}

+ (NSString *)parseQueryFromURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL: url resolvingAgainstBaseURL: false];
    
    if (components == nil || components.queryItems == nil) {
        return nil;
    }
    
    NSUInteger index = [components.queryItems indexOfObjectPassingTest:^BOOL(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.name isEqualToString: @"q"];
    }];
    
    if (index == NSNotFound) {
        return nil;
    } else {
        return components.queryItems[index].value;
    }
}
@end
