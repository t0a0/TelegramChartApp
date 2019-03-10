//
//  TGCAJsonModels.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit


struct JsonCharts: Codable {
  private struct DummyCodable: Codable {}
  
  let charts: [JsonChart]
  
  init(from decoder: Decoder) throws {
    var charts = [JsonChart]()
    var container = try decoder.unkeyedContainer()
    while !container.isAtEnd {
      if let route = try? container.decode(JsonChart.self) {
        charts.append(route)
      } else {
        _ = try? container.decode(DummyCodable.self) // <-- TRICK
      }
    }
    self.charts = charts
  }
  
  struct JsonChart: Codable {
    
    let columns: [JsonColumn]
    let types: [String:String]
    let colors: [String:String]
    let names: [String:String]
    
    enum CodingKeys : String, CodingKey {
      case columns
      case types
      case colors
      case names
    }
    
    struct JsonColumn: Codable {
      var label: String
      let values: [CGFloat]
      
      init(from decoder: Decoder) throws {
        var vals = [CGFloat]()
        var label = "unknown"
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
          if let lbl = try? container.decode(String.self) {
            label = lbl
          } else if let value = try? container.decode(CGFloat.self){
            vals.append(value)
          } else {
            _ = try? container.decode(DummyCodable.self) // <-- TRICK
          }
        }
        self.label = label
        self.values = vals
      }
    }
    
  }
  
}



