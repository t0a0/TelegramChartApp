//
//  TGCADateRangeFormatterService.swift
//  TelegramChartApp
//
//  Created by Igor on 10/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCADateRangeFormatterService {
  
  private lazy var fullDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "EEEE, dd MMMM Y"
    return df
  }()
  
  private lazy var mediumDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    df.dateFormat = "dd MMMM Y"
    return df
  }()
  
  private lazy var calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US")
    if let timeZone = TimeZone(secondsFromGMT: 0) {
      calendar.timeZone = timeZone
    }
    return calendar
  }()
  
  func prettyDateStringFrom(left: Date, right: Date) -> String {
    
    if !calendar.isDate(left, inSameDayAs: right) {
      return mediumDateFormatter.string(from: left) + " - " + mediumDateFormatter.string(from: right)
    }
    return fullDateFormatter.string(from: left)
  }
  
}
