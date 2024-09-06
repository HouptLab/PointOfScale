//
//  AppDelegate.swift
//  PointOfScale
//
//  Created by Tom Houpt on 20/11/15.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth

@available(iOS 13.0, *)
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setDefaultsFromSettingsBundle()
        
        // TODO: confirm that user has set up settings with urls, email, and password
        // if not, can we throw to settings?
        
   //     let defaultValues = ["FirebaseURL": "","FirebaseEmail": "","FirebasePassword": ""]
   //     UserDefaults.standard.register(defaults: defaultValues)
        
        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        return true
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

func setDefaultsFromSettingsBundle() {
    //Read PreferenceSpecifiers from Root.plist in Settings.Bundle
    if let settingsURL = Bundle.main.url(forResource: "Root", withExtension: "plist", subdirectory: "Settings.bundle"),
        let settingsPlist = NSDictionary(contentsOf: settingsURL),
        let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] {

        for prefSpecification in preferences {

            if let key = prefSpecification["Key"] as? String, let value = prefSpecification["DefaultValue"] {

                //If key doesn't exists in userDefaults then register it, else keep original value
                if UserDefaults.standard.value(forKey: key) == nil {

                    UserDefaults.standard.set(value, forKey: key)
                    NSLog("registerDefaultsFromSettingsBundle: Set following to UserDefaults - (key: \(key), value: \(value), type: \(type(of: value)))")
                }
            }
        }
    } else {
        NSLog("registerDefaultsFromSettingsBundle: Could not find Settings.bundle")
    }
}
}

