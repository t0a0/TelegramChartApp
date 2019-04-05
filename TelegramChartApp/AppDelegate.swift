//
//  AppDelegate.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  func toggleTheme() {
    currentTheme = currentTheme.identifier == ThemeIdentifier.normal ? TGCAColorTheme.dark : TGCAColorTheme.normal
  }
  
  var currentTheme = TGCAColorTheme.dark {
    didSet {
      NotificationCenter.default.post(Notification(name: THEME_HAS_CHANGED_NOTIFICATION_NAME))
    }
  }
  
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }

}

extension UIApplication {
  
  static var myDelegate: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }
  
}
