//
//  Created by Tapash Majumder on 1/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

@testable import IterableSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        IterableAPI.initialize(apiKey: "undefined")
        IterableAPI.email = "user@example.com"
        return true
    }

}

