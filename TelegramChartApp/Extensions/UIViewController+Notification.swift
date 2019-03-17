//
//  UIViewController+Notification.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

@objc protocol ThemeChangeObserving {
  
  @objc func handleThemeChangedNotification()
  
}

extension ThemeChangeObserving {
  
  func subscribe() {
    NotificationCenter.default.addObserver(self, selector: #selector(ThemeChangeObserving.handleThemeChangedNotification), name: THEME_HAS_CHANGED_NOTIFICATION_NAME, object: nil)
  }
  
  func unsubscribe() {
    NotificationCenter.default.removeObserver(self, name: THEME_HAS_CHANGED_NOTIFICATION_NAME, object: nil)
  }
  
}

