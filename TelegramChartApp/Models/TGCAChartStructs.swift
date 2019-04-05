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

struct LinearChart {
  
  let title: String?
  
  let yVectors: [ChartValueVector]
  let xVector: ValueVector
  let datesVector: [Date]
  
  init(yVectors: [ChartValueVector], xVector: ValueVector, title: String? = nil) {
    yVectors.forEach{
      assert($0.vector.count == xVector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    self.yVectors = yVectors
    self.xVector = xVector
    self.title = title
    self.datesVector = xVector.map{Date(timeIntervalSince1970: TimeInterval($0 / 1000.0))}
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
      return (vectors.map{$0.map{_ in 0}}, 0...0)
    }
    return (vectors.map{$0.map{(($0 - minimum) / (maximum - minimum))}}, minimum...maximum)
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
