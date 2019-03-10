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
    
    var xColumn: JsonColumn {
      let filter = columns.filter{$0.identifier.elementsEqual("x")}
      guard let xc = filter.first else {
        fatalError("Could not find \"x\" column in chart")
      }
      return xc
    }
    
    var yColumns: [JsonColumn] {
      let cols = columns.filter{!$0.identifier.elementsEqual("x")}
      assert(cols.count > 0, "No \"y\" columns found in chart")
      return cols
    }
    
    func name(forIdentifier identifier: String) -> String? {
      return names[identifier]
    }
    
    func color(forIdentifier identifier: String) -> UIColor? {
      guard let colorHex = colors[identifier] else {
        return nil
      }
      return UIColor(hex: colorHex)
    }
    
    enum CodingKeys : String, CodingKey {
      case columns
      case types
      case colors
      case names
    }
    
    struct JsonColumn: Codable {
      let identifier: String
      let values: [CGFloat]
      
      init(from decoder: Decoder) throws {
        //TODO: make prettier
        var vals = [CGFloat]()
        var container = try decoder.unkeyedContainer()
        var la: String? = nil
        if let lbl = try? container.decode(String.self) {
          la = lbl
        }
        while !container.isAtEnd {
          if let value = try? container.decode(CGFloat.self){
            vals.append(value)
          } else {
            _ = try? container.decode(DummyCodable.self) // <-- TRICK
          }
        }
        self.identifier = la!
        self.values = vals
      }
    }
    
  }
  
}



