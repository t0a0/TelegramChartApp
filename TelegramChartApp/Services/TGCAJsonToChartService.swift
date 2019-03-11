//
//  TGCAJsonToChartService.swift
//  TelegramChartApp
//
//  Created by Igor on 11/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAJsonToChartService {
  
  func parse() -> [LinearChart]? {
    guard
      let url = Bundle.main.url(forResource: "chart_data", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let charts = try? JSONDecoder().decode(JsonCharts.self, from: data).charts else {
        return nil
    }
    
    return charts.map{jsonChartToChart($0)}
  }
  
  private func jsonChartToChart(_ jsonChart: JsonCharts.JsonChart) -> LinearChart {
    //TODO: may be do sorting?
    let yVectors: [ChartValueVector] = jsonChart.yColumns.map{
      let identifier = $0.identifier
      return ChartValueVector(vector: $0.values, metaData: ChartValueVectorMetaData(identifier, jsonChart.name(forIdentifier: identifier), jsonChart.color(forIdentifier: identifier)))
    }
    return LinearChart(yVectors: yVectors,
                      xVector: ChartPositionVector(vector: jsonChart.xColumn.values),
                      title: nil)
  }
  
  private struct JsonCharts: Codable {
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
      
      func name(forIdentifier identifier: String) -> String {
        return names[identifier] ?? "unknown"
      }
      
      func color(forIdentifier identifier: String) -> UIColor {
        //TODO: REDO
        guard let colorHex = colors[identifier] else {
          return .black
        }
        return UIColor(hex: colorHex) ?? .black
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
  
}
