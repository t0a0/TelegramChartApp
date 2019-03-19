//
//  TGCAChartLabelFormatterService.swift
//  TelegramChartApp
//
//  Created by Igor on 19/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

protocol ChartLabelFormatterProtocol {
  
  func prettyValueString(from value: CGFloat) -> String
  
  func prettyDateString(from timeIntervalSince1970inMillis: CGFloat) -> String
  
}

struct TGCAChartLabelFormatterService: ChartLabelFormatterProtocol {
  
  private let dateFormatter: DateFormatter

  init() {
    let df = DateFormatter()
    df.locale = Locale.current
    df.timeZone = TimeZone.current
    df.dateFormat = "MMM dd"    
    self.dateFormatter = df
  }
  
  func prettyValueString(from value: CGFloat) -> String {
    return prettify(value: value)
  }
  
  func prettyDateString(from timeIntervalSince1970inMillis: CGFloat) -> String {
    return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timeIntervalSince1970inMillis / 1000.0)))
  }
  
  // MARK: Private
  
  private func prettify(value: CGFloat) -> String {
    let num = abs(value)
    let sign = (value < 0) ? "-" : ""
    
    switch num {
      
    case 1_000_000_000...:
      var formatted = num / 1_000_000_000
      formatted = truncate(value: formatted, places: 3)
      return "\(sign)\(formatted)B"
      
    case 1_000_000...:
      var formatted = num / 1_000_000
      formatted = truncate(value: formatted, places: 2)
      return "\(sign)\(formatted)M"
      
    case 1_000...:
      var formatted = num / 1_000
      formatted = truncate(value: formatted, places: 1)
      return "\(sign)\(formatted)K"
      
    case 0...:
      return "\(Int(round(value)))"
      
    default:
      return "\(sign)\(value)"
    }
  }
  
  private func truncate(value: CGFloat, places: Int) -> CGFloat {
    return CGFloat(floor(pow(10.0, CGFloat(places)) * value)/pow(10.0, CGFloat(places)))
  }
  
}
