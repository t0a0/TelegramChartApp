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

struct LinearChart {
  
  var title: String?
  
  let yVectors: [ChartValueVector]
  let xVector: ChartPositionVector
  
  init(yVectors: [ChartValueVector], xVector: ChartPositionVector, title: String? = nil) {
    for yVector in yVectors {
      assert(yVector.vector.count == xVector.vector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    self.yVectors = yVectors
    self.xVector = xVector
    self.title = title
  }
  
}

struct ChartPositionVector {
  
  let vector: ValueVector
  let normalizedVector: NormalizedValueVector
  
  let max: CGFloat
  let min: CGFloat
  
  init(vector: ValueVector) {
    self.vector = vector
    self.max = vector.max() ?? 0
    self.min = vector.min() ?? 0
    self.normalizedVector = normalizeVector(vector, for: 0...1.0)
  }
  
}

struct ChartValueVector {
  
  let metaData: ChartValueVectorMetaData
  
  let vector: ValueVector
  let normalizedVector: NormalizedValueVector
  
  let max: CGFloat
  let min: CGFloat
  
  init(vector: ValueVector, metaData: ChartValueVectorMetaData) {
    self.metaData = metaData
    self.vector = vector
    self.max = vector.max() ?? 0
    self.min = vector.min() ?? 0
    self.normalizedVector = normalizeVector(vector, for: 0...1.0)
  }
  
}

struct NormalizedValueVector {
  
  let vector: ValueVector
  let normalizationRange: ClosedRange<CGFloat>
  let max: CGFloat
  let min: CGFloat
  
  init(normalizedVector: ValueVector, normalizationRange: ClosedRange<CGFloat>) {
    self.vector = normalizedVector
    self.normalizationRange = normalizationRange
    self.max = normalizedVector.max() ?? 0
    self.min = normalizedVector.min() ?? 0
  }
  
}

func normalizeVector(_ vector: ValueVector, for normalizationRange: ClosedRange<CGFloat>) -> NormalizedValueVector {
  let maxValue = vector.max() ?? 0
  let minValue = vector.min() ?? 0
  guard maxValue != minValue else {
    return NormalizedValueVector(normalizedVector: vector.map{_ in 0}, normalizationRange: normalizationRange)
  }
  //we want to normalize positive vector
  let positiveVector = minValue >= 0 ? vector : vector.map{$0 - minValue}
  let normalizedVector = positiveVector.map{
    (($0 - minValue) / (maxValue - minValue)) *
      (normalizationRange.upperBound - normalizationRange.lowerBound) +
      normalizationRange.lowerBound
  }
  return NormalizedValueVector(normalizedVector: normalizedVector, normalizationRange: normalizationRange)
}
