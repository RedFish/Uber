//
//  AppDelegate.swift
//  Uber
//
//  Created by Richard Guerci on 05/10/2015.
//  Copyright © 2015 Richard Guerci. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Enable storing and querying data from Local Datastore.
		// Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
		Parse.enableLocalDatastore()
		
		// ****************************************************************************
		// Uncomment this line if you want to enable Crash Reporting
		// ParseCrashReporting.enable()
		//
		// Uncomment and fill in with your Parse credentials:
		Parse.setApplicationId("yDZO3W0Qln3T84PKkDxOrbqUFviBse4QzrUe2tv1",
			clientKey: "Qb1WDWWQMaAb20MOxYxLrFy6Dl08Gk0yJvQROJil")
		//
		// If you are using Facebook, uncomment and add your FacebookAppID to your bundle's plist as
		// described here: https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/
		// Uncomment the line inside ParseStartProject-Bridging-Header and the following line here:
		//PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
		// ****************************************************************************
		
		PFUser.enableAutomaticUser()
		
		let defaultACL = PFACL();
		
		// If you would like all objects to be private by default, remove this line.
		defaultACL.setPublicReadAccess(true)
		
		PFACL.setDefault(defaultACL, withAccessForCurrentUser:true)
		
		if application.applicationState != UIApplicationState.background {
			// Track an app open here if we launch with a push, unless
			// "content_available" was used to trigger a background push (introduced in iOS 7).
			// In that case, we skip tracking here to avoid double counting the app-open.
			
			let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
			let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
			var noPushPayload = false;
			if let options = launchOptions {
				noPushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] != nil;
			}
			if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
				PFAnalytics.trackAppOpened(launchOptions: launchOptions)
			}
		}
		
		//
		//  Swift 1.2
		//
		//        if application.respondsToSelector("registerUserNotificationSettings:") {
		//            let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
		//            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
		//            application.registerUserNotificationSettings(settings)
		//            application.registerForRemoteNotifications()
		//        } else {
		//            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Alert | UIRemoteNotificationType.Sound
		//            application.registerForRemoteNotificationTypes(types)
		//        }
		
		//
		//  Swift 2.0
		//
		//        if #available(iOS 8.0, *) {
		//            let types: UIUserNotificationType = [.Alert, .Badge, .Sound]
		//            let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
		//            application.registerUserNotificationSettings(settings)
		//            application.registerForRemoteNotifications()
		//        } else {
		//            let types: UIRemoteNotificationType = [.Alert, .Badge, .Sound]
		//            application.registerForRemoteNotificationTypes(types)
		//        }
		
		return true//FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
	}
	
	//--------------------------------------
	// MARK: Push Notifications
	//--------------------------------------
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let installation = PFInstallation.current()
		installation.setDeviceTokenFrom(deviceToken)
		installation.saveInBackground()
		
		PFPush.subscribeToChannel(inBackground: "") { (succeeded: Bool, error: Error?) in
			if succeeded {
				print("ParseStarterProject successfully subscribed to push notifications on the broadcast channel.\n");
			} else {
				print("ParseStarterProject failed to subscribe to push notifications on the broadcast channel with error = %@.\n", error?.localizedDescription ?? "Unknow")
			}
		}
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		if (error as NSError?)?.code == 3010 {
			print("Push notifications are not supported in the iOS Simulator.\n")
		} else {
			print("application:didFailToRegisterForRemoteNotificationsWithError: %@\n", error)
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
		PFPush.handle(userInfo)
		if application.applicationState == UIApplicationState.inactive {
			PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
		}
	}
	
	///////////////////////////////////////////////////////////
	// Uncomment this method if you want to use Push Notifications with Background App Refresh
	///////////////////////////////////////////////////////////
	// func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
	//     if application.applicationState == UIApplicationState.Inactive {
	//         PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
	//     }
	// }
	
	//--------------------------------------
	// MARK: Facebook SDK Integration
	//--------------------------------------

	/*
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
		return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
	}
	
	
	//Make sure it isn't already declared in the app delegate (possible redefinition of func error)
	func applicationDidBecomeActive(application: UIApplication) {
		FBSDKAppEvents.activateApp()
	}
	*/
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	
}

