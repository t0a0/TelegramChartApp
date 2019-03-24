//
//  TGCANavigationController.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCANavigationController: UINavigationController, ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    applyCurrentTheme()
    navigationBar.isTranslucent = false
    subscribe()
  }
  
  deinit {
    unsubscribe()
  }
  
  func applyCurrentTheme() {
    let theme = UIApplication.myDelegate.currentTheme
    navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.mainTextColor]
    navigationBar.barTintColor = theme.foregroundColor
    navigationBar.tintColor = theme.accentColor
  }
}
