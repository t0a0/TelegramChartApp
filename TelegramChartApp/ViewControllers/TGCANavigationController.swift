//
//  TGCANavigationController.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCANavigationController: UINavigationController, ThemeChangeObserving {
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIApplication.myDelegate.currentTheme.statusBarStyle
  }
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    applyCurrentTheme()
    navigationBar.isTranslucent = false
    interactivePopGestureRecognizer?.isEnabled = false
    subscribe()
  }
  
  deinit {
    unsubscribe()
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      setNeedsStatusBarAppearanceUpdate()
      navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.mainTextColor]
      navigationBar.barTintColor = theme.foregroundColor
      navigationBar.tintColor = theme.accentColor
      navigationBar.layoutIfNeeded()
    }
    
    if animated {
      UIView.animate(withDuration: ANIMATION_DURATION) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
    
  }
  
}
