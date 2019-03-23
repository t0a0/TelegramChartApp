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
  
  var title: String?
  
  let yVectors: [ChartValueVector]
  let xVector: ValueVector

  init(yVectors: [ChartValueVector], xVector: ValueVector, title: String? = nil) {
    yVectors.forEach{
      assert($0.vector.count == xVector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    self.yVectors = yVectors
    self.xVector = xVector
    self.title = title
  }
  
  func labelSpacing(for count: Int) -> (spacing: Int, leftover: CGFloat) {
    var i = 1
    while i*6 < count {
      i *= 2
    }
    let extra = count % ((i/2)*6)
    let higherBound = i*6
    let leftover = 2.0 * CGFloat(extra) / CGFloat(higherBound)
    return (i, leftover)
  }
  
  func normalizedYVectorsFromZeroMinimum(in xRange: ClosedRange<CGFloat>, excludedIdxs: Set<Int>) -> NormalizedYVectors {

    let vectors = yVectors.map{$0.vector}
    let bounds = translatedBounds(for: xRange)
    
    let minimum: CGFloat = 0
    var maximum: CGFloat = 0
    for i in 0..<vectors.count {
      if !excludedIdxs.contains(i) {
        maximum = max(maximum, vectors[i][bounds].max() ?? 0)
      }
    }
    guard minimum != maximum else {
      return (vectors.map{$0.map{_ in 0}}, 0...0)
    }
    
    return (vectors.map{$0.map{(($0 - minimum) / (maximum - minimum))}}, minimum...maximum)
  }
  
  func normalizedYVectorsFromLocalMinimum(in xRange: ClosedRange<CGFloat>, excludedIdxs: Set<Int>) -> NormalizedYVectors {
    
    let vectors = yVectors.map{$0.vector}
    let bounds = translatedBounds(for: xRange)
    
    var notExcludedVectors = [ValueVector]()
    for i in 0..<vectors.count {
      if !excludedIdxs.contains(i) {
        notExcludedVectors.append(vectors[i])
      }
    }
    let minimum = notExcludedVectors.map{$0[bounds].min() ?? 0}.min() ?? 0
    let maximum = notExcludedVectors.map{$0[bounds].max() ?? 0}.max() ?? 0
    
    guard minimum != maximum else {
      return (vectors.map{$0.map{_ in 0}}, 0...0)
    }
    return (vectors.map{$0.map{(($0 - minimum) / (maximum - minimum))}}, minimum...maximum)
  }
  
  func translatedIndex(for xRangePosition: CGFloat) -> Int {
    return Int(round(CGFloat(xVector.count - 1) * xRangePosition))
  }
  
  func translatedBounds(for xRange: ClosedRange<CGFloat>) -> ClosedRange<Int> {
    return translatedIndex(for: xRange.lowerBound)...translatedIndex(for: xRange.upperBound)
  }
  
  func normalizedXVector(in xRange: ClosedRange<CGFloat>) -> ValueVector {
    let bounds = translatedBounds(for: xRange)
    let maxValue = xVector[bounds].max() ?? 0
    let minValue = xVector[bounds].min() ?? 0
    guard maxValue != minValue else {
      return xVector.map{_ in 0}
    }
    
    let normalizedVector = xVector.map{(($0 - minValue) / (maxValue - minValue))}
    return normalizedVector
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
