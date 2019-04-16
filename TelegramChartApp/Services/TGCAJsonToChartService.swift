//
//  TGCAJsonToChartService.swift
//  TelegramChartApp
//
//  Created by Igor on 11/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

struct TGCAJsonToChartService/*: JsonParserServiceProtocol*/ {
  
  func parseJson(named resourceName: String, subDir: String) -> [DataChart]? {
    guard
      let url = Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: subDir),
      let data = try? Data(contentsOf: url),
      let charts = try? JSONDecoder().decode(JsonCharts.self, from: data) else {
        return nil
    }
    
    return charts.charts.map{jsonChartToLinearChart($0)}
  }
  
  private func jsonChartToLinearChart(_ jsonChart: JsonCharts.JsonChart) -> DataChart {
    //TODO: Sorting might be required
    let yVectors: [ChartValueVector] = jsonChart.yColumns.map{
      let identifier = $0.identifier
      return ChartValueVector(vector: $0.values, metaData: ChartValueVectorMetaData(identifier, jsonChart.name(forIdentifier: identifier), jsonChart.color(forIdentifier: identifier)))
    }
    
    var type: DataChartType = .linear
    let jsonChartType = jsonChart.types["y0"]!
    if jsonChartType == "line" {
      if jsonChart.y_scaled ?? false {
        type = .linearWith2Axes
      }
    } else if jsonChartType == "bar" {
      if jsonChart.stacked ?? false {
        type = .stackedBar
      } else {
        type = .singleBar
      }
    } else {
      type = .percentage
    }
    if type == .linear && yVectors.count == 3 {
      type = .threeDaysComparison
    }
    return DataChart(yVectors: yVectors,
                      xVector: jsonChart.xColumn.values,
                      type: type,
                      title: jsonChart.title)
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
      let percentage: Bool?
      let stacked: Bool?
      let y_scaled: Bool?
      let title: String?
      
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
        case percentage
        case stacked
        case y_scaled
        case title
      }
      
      struct JsonColumn: Codable {
        let identifier: String
        let values: [CGFloat]
        
        init(from decoder: Decoder) throws {
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
