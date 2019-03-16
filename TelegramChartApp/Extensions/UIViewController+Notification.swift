//
//  UIViewController+Notification.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

protocol ThemeChangeObserving {
  
  func handleThemeChangedNotification()
  
}

extension ThemeChangeObserving where Self: UIViewController {
  
  func subscribe() {
    NotificationCenter.default.addObserver(forName: THEME_HAS_CHANGED_NOTIFICATION_NAME, object: nil, queue: OperationQueue.main) { _ in
      self.handleThemeChangedNotification()
    }
  }
  
  func unsubscribe() {
    NotificationCenter.default.removeObserver(self, name: THEME_HAS_CHANGED_NOTIFICATION_NAME, object: nil)
  }
  
}

