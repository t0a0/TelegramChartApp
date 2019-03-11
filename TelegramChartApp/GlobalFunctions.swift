//
//  GlobalFunctions.swift
//  TelegramChartApp
//
//  Created by Igor on 11/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

func normalizedVector(from vector: ValueVector, withNormalizationRange normalizationRange: ClosedRange<CGFloat> = ZORange) -> NormalizedValueVector {
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
