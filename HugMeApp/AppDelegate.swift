//
//  AppDelegate.swift
//  HugMeApp
//
//  Created by Özgün Yildiz on 10.08.22.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleSignIn
import FirebaseAuth
import FirebaseCore
import Kingfisher

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    
    
    static let screenHeight = UIScreen.main.bounds.height
    static let screenWidth = UIScreen.main.bounds.width
    
    var window: UIWindow?
    
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        var handled: Bool
//        
//        handled = GIDSignIn.sharedInstance.handle(url)
//        
//        if handled {
//            return true
//        }
//        
//        // Handle other custom URL types.
//        
//        // If not handled by this app, return false.
//        return false
//    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Use Kingfisher's default memory cache
        KingfisherManager.shared.cache.memoryStorage.config.totalCostLimit = 500 * 1024 * 1024 // Set a custom limit if needed
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        
        
        // MARK: - YOU MIGHT WANT TO LOOK INTO THIS IF ENCOUNTERING ANY WEIRD LOGIN BEHAVIOR
        
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if let _ = error {
                print("There was an error")
                return
            }
            guard success else {
                return
            }
            print("Success in APNS registry")
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        Messaging.messaging().isAutoInitEnabled = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.overrideUserInterfaceStyle = .dark
        window?.makeKeyAndVisible()
        if let _ = Auth.auth().currentUser {
               // There's a currently authenticated user
               
               let hasRegistered = UserDefaults.standard.bool(forKey: "HasRegistered")
               
               if hasRegistered {
                   // User has registered, set the root view controller to LoginVC
                   window?.rootViewController = LoginVC()
               } else {
                   // User has not registered, log them out and set the root view controller to WelcomeVC
                   do {
                       try Auth.auth().signOut()
                   } catch {
                       print("Error signing out: \(error.localizedDescription)")
                   }
                   UserDefaults.standard.set(false, forKey: "HasRegistered")
                   window?.rootViewController = WelcomeVC()
               }
           } else {
               // There's no currently authenticated user, set the root view controller to WelcomeVC
               window?.rootViewController = WelcomeVC()
           }
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken token: String?) {
        messaging.token { token, error in
            if let _ = error {
                print("There was an error")
                return
            }
            guard let token = token else {
                return
            }
            print("Token: \(token)")
        }
        
        UIApplication.shared.applicationIconBadgeNumber += 1
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reset the badge count to zero
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the notification, increment badge count
        if let aps = userInfo["aps"] as? [String: Any], let badge = aps["badge"] as? Int {
            UIApplication.shared.applicationIconBadgeNumber = badge
        }
        completionHandler(.noData) // Make sure to call the completion handler
    }
}

