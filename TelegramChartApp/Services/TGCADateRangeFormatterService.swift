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
  
  func prettyDateStringFrom(left: Date, right: Date?) -> String {
    if let right = right {
      return mediumDateFormatter.string(from: left) + " - " + mediumDateFormatter.string(from: right)
    }
    return fullDateFormatter.string(from: left)
  }
  
}
