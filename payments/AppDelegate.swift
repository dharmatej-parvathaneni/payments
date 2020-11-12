//
//  AppDelegate.swift
//  payments
//
//  Created by Dharmatej Parvathaneni on 4/24/20.
//  Copyright © 2020 twinspires. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configure FirebaseApp
        FirebaseApp.configure()
        
        // Delegates for Messaging and Notifications
        Messaging.messaging().delegate = self
        
        
        // Request Notification Permissions from Device User.
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
           options: authOptions,
           completionHandler: {_, _ in })
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("didReceiveRemoteNotification Message ID: \(messageID)")
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }

        // Print full message.
        print(userInfo)
    }
    
    // Declare below to receive FIRMessaging messages
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                       fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("didReceiveRemoteNotification fetchCompletionHandler Message ID: \(messageID)")
            Messaging.messaging().appDidReceiveMessage(userInfo)
        }

        // Print full message.
        print(userInfo)
        
        // Send Notification to ViewController
        if application.applicationState == .active {
            NotificationCenter.default.post(name: Notification.Name("DataMsgBackEnd"), object: nil, userInfo: userInfo)
        }
        
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // set APNSToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(String(describing: deviceToken))")
        
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate : MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {

        print("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict:[String: String] = ["token": fcmToken ]

        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
  }

}
