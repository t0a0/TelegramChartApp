//
//  TGCAChartStructs.swift
//  TelegramChartApp
//
//  Created by Igor on 11/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

typealias ValueVector = [CGFloat]
typealias ChartValueVectorMetaData = (identifier: String, name: String, color: UIColor)
typealias NormalizedYVectors = (vectors: [ValueVector], yRange: ClosedRange<CGFloat>)
typealias SeparatlyNormalizedYVectors = [(vector: ValueVector, yRange: ClosedRange<CGFloat>)]
typealias PercentageYVectors = [ValueVector]

enum DataChartType: String {
  case linear
  case linearWith2Axes
  case singleBar
  case stackedBar
  case percentage
}

struct DataChart {
  
  let title: String?
  let type: DataChartType
  let yVectors: [ChartValueVector]
  let xVector: ValueVector
  let datesVector: [Date]
  let showsAxisLabelsOnBothSides = true
  let percentageYVectors: [ValueVector]
  
  init(yVectors: [ChartValueVector], xVector: ValueVector, type: DataChartType, title: String? = nil) {
    yVectors.forEach{
      assert($0.vector.count == xVector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    self.yVectors = yVectors
    self.xVector = xVector
    self.title = title
    self.type = type
    self.datesVector = xVector.map{Date(timeIntervalSince1970: TimeInterval($0 / 1000.0))}
    if type == .percentage {
      var percentVectors = [ValueVector]()
      var sums = [CGFloat]()
      let yVs = yVectors.map{$0.vector}

      yVs[0].forEach{sums.append($0)}
      for i in 1..<yVs.count {
        for j in 0..<yVs[i].count {
          sums[j] = sums[j] + yVs[i][j]
        }
      }
      yVs.forEach{percentVectors.append(zip($0, sums).map{$0 / $1})}
      
      self.percentageYVectors = percentVectors
    } else {
      self.percentageYVectors = []
    }
  }
  
  func normalizedYVectorsFromZeroMinimum(in xRange: ClosedRange<Int>, excludedIdxs: Set<Int>) -> NormalizedYVectors {

    let vectors = yVectors.map{$0.vector}
    
    let minimum: CGFloat = 0
    var maximum: CGFloat = 0
    for i in 0..<vectors.count {
      if !excludedIdxs.contains(i) {
        maximum = max(maximum, vectors[i][xRange].max() ?? 0)
      }
    }
    guard minimum != maximum else {
      return (vectors.map{$0.map{_ in 0}}, 0...0)
    }
    
    return (vectors.map{$0.map{(($0 - minimum) / (maximum - minimum))}}, minimum...maximum)
  }
  
  func normalizedYVectorsFromLocalMinimum(in xRange: ClosedRange<Int>, excludedIdxs: Set<Int>) -> NormalizedYVectors {
    
    let vectors = yVectors.map{$0.vector}
    
    var notExcludedVectors = [ValueVector]()
    for i in 0..<vectors.count {
      if !excludedIdxs.contains(i) {
        notExcludedVectors.append(vectors[i])
      }
    }
    let minimum = notExcludedVectors.map{$0[xRange].min() ?? 0}.min() ?? 0
    let maximum = notExcludedVectors.map{$0[xRange].max() ?? 0}.max() ?? 0
    
    guard minimum != maximum else {
      return (vectors.map{Array(repeating: 0, count: $0.count)}, 0...0)
    }
    return (vectors.map{$0.map{(($0 - minimum) / (maximum - minimum))}}, minimum...maximum)
  }
  
  func separatlyNormalizedYVectorsFromLocalMinimum(in xRange: ClosedRange<Int>) -> SeparatlyNormalizedYVectors {
    let vectors = yVectors.map{$0.vector}
    
    return vectors.map{
      let min = $0[xRange].min() ?? 0
      let max = $0[xRange].max() ?? 0
      guard min != max else {
        return (Array(repeating: 0, count: $0.count), 0...0)
      }
      return ($0.map{(($0 - min) / (max - min))}, min...max)
    }
  }
  
  /// Maps the value in range of 0...1 to an according index in the xVector
  func translatedIndex(for xRangePosition: CGFloat) -> Int {
    return Int(round(CGFloat(xVector.count - 1) * xRangePosition))
  }
  
  /// Maps the subrange of 0...1 to an according Int range of indexes of the xVector
  func translatedBounds(for xRange: ClosedRange<CGFloat>) -> ClosedRange<Int> {
    return translatedIndex(for: xRange.lowerBound)...translatedIndex(for: xRange.upperBound)
  }
  
  func normalizedXVector(in xRange: ClosedRange<Int>) -> ValueVector {
    let maxValue = xVector[xRange].max() ?? 0
    let minValue = xVector[xRange].min() ?? 0
    guard maxValue != minValue else {
      return xVector.map{_ in 0}
    }
    
    let normalizedVector = xVector.map{(($0 - minValue) / (maxValue - minValue))}
    return normalizedVector
  }
  
  func indexOfChartValueVector(withId identifier: String) -> Int? {
    for i in 0..<yVectors.count {
      if yVectors[i].metaData.identifier.elementsEqual(identifier) {
        return i
      }
    }
    return nil
  }
  
}

struct ChartValueVector {
  
  let metaData: ChartValueVectorMetaData
  let vector: ValueVector
  
  init(vector: ValueVector, metaData: ChartValueVectorMetaData) {
    self.metaData = metaData
    self.vector = vector
  }
  
}
