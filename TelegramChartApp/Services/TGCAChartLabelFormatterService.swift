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
  
  func string(from value: CGFloat) -> String
  
}

struct TGCAChartLabelFormatterService: ChartLabelFormatterProtocol {
  
  func string(from value: CGFloat) -> String {
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
