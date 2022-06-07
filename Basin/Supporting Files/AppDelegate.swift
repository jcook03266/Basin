//
//  AppDelegate.swift
//  Stuy Wash N Dry
//
//  Created by Justin Cook on 2/4/22.
//

import UIKit
import CoreData
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import IQKeyboardManagerSwift
import FBSDKCoreKit
import GoogleSignIn
import FirebaseAnalytics
import GoogleMaps
import GooglePlaces
import GoogleMobileAds
import Stripe
import FirebaseFunctions

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        /**Override point for customization after application launch.*/
        
        /** Test keys, please replace*/
        StripeAPI.defaultPublishableKey = stripeDefaultPublishableKey
        
        /** Google maps*/
        GMSServices.provideAPIKey(GMSAPIKey)
        GMSPlacesClient.provideAPIKey(GMSAPIKey)
        
        /** Mobile ads*/
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        /** Firebase*/
        FirebaseApp.configure()
        Auth.auth().languageCode = Locale.preferredLanguages[0]
        
        /** Firestore settings*/
        let settings = Firestore.firestore().settings
        /** Enable caching for offline querying*/
        settings.isPersistenceEnabled = true
        Firestore.firestore().settings = settings
        
        /** Keyboard manager settings*/
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.placeholderFont = getCustomFont(name: .Ubuntu_Regular, size: 14, dynamicSize: false)
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 5
        
        return true
    }
    
    /** Code initializes the Facebook SDK when your app launches, and allows the SDK handle results from the native Facebook app when you perform a Login or Share action.*/
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        
        /** Google sign-in*/
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    func applicationWillTerminate(_ application: UIApplication){
        
        /** Delete the current user if they're not done creating their account*/
        if accountCreationInProgress == true && Auth.auth().currentUser != nil{
            ///deleteCurrentUser()
            signOutCurrentUser()
            
            ///print("Temporary user deletion triggered")
        }
        
        /** Remove any cached users if they're from the sign up screen, haven't completed the account creation yet, and the internet is unavailable for them, the auth credentials for them will remain in the auth until they try to sign up again., this is to prevent the app from recognizing the cached user as a valid one due to the user linking one of the non primary auth credentials such as phone etc.*/
        if accountCreationInProgress == true && internetAvailable == false && Auth.auth().currentUser != nil{
            signOutCurrentUser()
            
            ///print("Temporary sign up user sign out triggered")
        }
    }
    
    // MARK: - Core Data stack
    
    /** Use this for persistence and light weight migration*/
    let coreDataManager = CoreDataManager(modelName: "Basin")
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Basin")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

