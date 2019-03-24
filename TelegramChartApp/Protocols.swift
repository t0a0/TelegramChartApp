//
//  UIViewController+Notification.swift
//  TelegramChartApp
//
//  Created by Igor on 16/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

// MARK: Theme

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

// MARK: - IoC protocols

protocol JsonParserServiceProtocol {
  
  func parseJson(named resourceName: String) -> [LinearChart]?
  
}

protocol ChartLabelFormatterProtocol {
  
  func prettyValueString(from value: CGFloat) -> String
  
  func prettyDateString(from timeIntervalSince1970inMillis: CGFloat) -> String
  
}

protocol LinearChartDisplaying {
  
  func configure(with chart: LinearChart)
  func toggleHidden(identifier: String)
  func toggleHidden(at index: Int)
  func trimDisplayRange(to newRange: ClosedRange<CGFloat>, with event: DisplayRangeChangeEvent)
  func reset(alsoResetHidden: Bool)
  
}
