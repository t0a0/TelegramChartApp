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
    applyCurrentTheme()
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
  
  func applyCurrentTheme() {
    let theme = UIApplication.myDelegate.currentTheme
    setNeedsStatusBarAppearanceUpdate()
    UIView.animate(withDuration: ANIMATION_DURATION) { [weak self] in
      self?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.mainTextColor]
      self?.navigationBar.barTintColor = theme.foregroundColor
      self?.navigationBar.tintColor = theme.accentColor
      self?.navigationBar.layoutIfNeeded()
    }
  }
  
}
