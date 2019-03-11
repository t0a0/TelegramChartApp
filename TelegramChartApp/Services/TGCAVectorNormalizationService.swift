//
//  TGCAVectorNormalizationService.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAVectorNormalizationService {
  
  let normalizationRange: ClosedRange<CGFloat>

  init() {
    self.normalizationRange = 0.0...1.0
  }

  init(normalizationRange: ClosedRange<CGFloat>) {
    self.normalizationRange = normalizationRange
  }
  
  func normalizeVectors(_ vectors: [[CGFloat]]) -> [[CGFloat]] {
    let normalizationDistance = normalizationRange.upperBound - normalizationRange.lowerBound
    let max = vectors.map{$0.max() ?? 0}.max() ?? 0
    let min = vectors.map{$0.min() ?? 0}.min() ?? 0
    guard max != min else {
      return vectors.map{$0.map{_ in (normalizationRange.upperBound - normalizationRange.lowerBound) / 2}}
    }
    return vectors.map{$0.map{(($0 - min) / (max - min)) * normalizationDistance + normalizationRange.lowerBound}}
  }
  
  func normalizeVector(_ vectors: [CGFloat]) -> [CGFloat] {
    let normalizationDistance = normalizationRange.upperBound - normalizationRange.lowerBound
    let max = vectors.max() ?? 0
    let min = vectors.min() ?? 0
    guard max != min else {
      return vectors.map{_ in (normalizationRange.upperBound - normalizationRange.lowerBound) / 2}
    }
    return vectors.map{(($0 - min) / (max - min)) * normalizationDistance + normalizationRange.lowerBound}
  }
  
}
