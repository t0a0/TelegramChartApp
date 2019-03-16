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
  
  /// TODO: comment
  let nyVectorGroup: NormalizedValueVectorGroup

  init(yVectors: [ChartValueVector], xVector: ChartPositionVector, title: String? = nil) {
    for yVector in yVectors {
      assert(yVector.vector.count == xVector.vector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    self.yVectors = yVectors
    self.xVector = xVector
    self.title = title
    self.nyVectorGroup = normalizedVectorGroup(from: yVectors.map{$0.vector})
  }
  
  func oddlyNormalizedYVectors(in xRange: ClosedRange<CGFloat>, excludedIdxs: [Int]) -> (resultingVectors: [ValueVector], originalCutVectors: [ValueVector], resltingYRange: ClosedRange<CGFloat>) {
    let lowerBoundIdx = Int(xRange.lowerBound * CGFloat(xVector.vector.count-1))
    let upperBoundIdx = Int(xRange.upperBound * CGFloat(xVector.vector.count-1))
    
    let cutOffYVectors = yVectors.map{Array($0.vector[lowerBoundIdx...upperBoundIdx])}
    let grp = oddlyNormalizedVectorGroup(from: cutOffYVectors, skippingIndexes: excludedIdxs)
    var resultingVectors = [ValueVector]()
    //    return (grp.vectors, yVectors.map{Array($0.vector[lowerBoundIdx...upperBoundIdx])})
    for i in 0..<yVectors.count {
      let a = Array(repeating: 0.5, count: lowerBoundIdx) + grp.oddGroup.vectors[i] + Array(repeating: 0.5, count: xVector.vector.count - 1 - upperBoundIdx)
      //      print(a.count)
      //      print(a)
      resultingVectors.append(a)
    }
    return (resultingVectors, cutOffYVectors, grp.yRange)
  }
  
  
  func translatedBounds(for xRange: ClosedRange<CGFloat>) -> ClosedRange<Int> {
    assert(ZORange ~= xRange.lowerBound && ZORange ~= xRange.upperBound, "Only subranges of 0...1 are allowed to use in this method")
    return Int(xRange.lowerBound * CGFloat(xVector.vector.count-1))...Int(xRange.upperBound * CGFloat(xVector.vector.count-1))
  }
  
  /// xRange - subRange of 0...1.0.
  func normalizedYVectors(in xRange: ClosedRange<CGFloat>, outOfRangeSubstitionValue: CGFloat = 0.5) -> ([ValueVector], [ValueVector]) {
    assert(ZORange ~= xRange.lowerBound && ZORange ~= xRange.upperBound, "Only subranges of 0...1 are allowed to use in this method")
    let lowerBoundIdx = Int(xRange.lowerBound * CGFloat(xVector.vector.count-1))
    let upperBoundIdx = Int(xRange.upperBound * CGFloat(xVector.vector.count-1))
    let grp = normalizedVectorGroup(from: yVectors.map{Array($0.vector[lowerBoundIdx...upperBoundIdx])})
    var resultingVectors = [ValueVector]()
//    return (grp.vectors, yVectors.map{Array($0.vector[lowerBoundIdx...upperBoundIdx])})
    for i in 0..<yVectors.count {
      let a = Array(repeating: 0.5, count: lowerBoundIdx) + grp.vectors[i] + Array(repeating: 0.5, count: xVector.vector.count - 1 - upperBoundIdx)
//      print(a.count)
//      print(a)
      resultingVectors.append(a)
    }
    return (resultingVectors, yVectors.map{Array($0.vector[lowerBoundIdx...upperBoundIdx])})
  }
  
  func normalizedXVector(in xRange: ClosedRange<CGFloat>) -> ValueVector {
    assert(ZORange ~= xRange.lowerBound && ZORange ~= xRange.upperBound, "Only subranges of 0...1 are allowed to use in this method")
    let lowerBoundIdx = Int(xRange.lowerBound * CGFloat(xVector.vector.count-1)) //33
    let upperBoundIdx = Int(xRange.upperBound * CGFloat(xVector.vector.count-1)) //66
    return Array(repeating: -1, count: lowerBoundIdx) + normalizedVector(from: Array(xVector.vector[lowerBoundIdx...upperBoundIdx])).vector + Array(repeating: 2, count: xVector.vector.count - 1 - upperBoundIdx)
  }
  
  func normalizedYVectors(for bounds: ClosedRange<Int>) -> [ValueVector] {
    let grp = normalizedVectorGroup(from: yVectors.map{Array($0.vector[bounds])})
    var resultingVectors = [ValueVector]()
    return grp.vectors
    for i in 0..<yVectors.count {
      let a = Array(repeating: 0.5, count: bounds.lowerBound) + grp.vectors[i] + Array(repeating: 0.5, count: xVector.vector.count - 1 - bounds.upperBound)
      //      print(a.count)
      //      print(a)
      resultingVectors.append(a)
    }
    return resultingVectors
  }
  
  func normalizedXVector(for bounds: ClosedRange<Int>) -> ValueVector {
    return normalizedVector(from: Array(xVector.vector[bounds])).vector
  }
}

struct ChartPositionVector {
  
  let vector: ValueVector
  let nVector: NormalizedValueVector
  
  let max: CGFloat
  let min: CGFloat
  
  init(vector: ValueVector) {
    self.vector = vector
    self.max = vector.max() ?? 0
    self.min = vector.min() ?? 0
    self.nVector = normalizedVector(from: vector)
  }
  
}

struct ChartValueVector {
  
  let metaData: ChartValueVectorMetaData
  
  let vector: ValueVector
  let nVector: NormalizedValueVector
  
  let max: CGFloat
  let min: CGFloat
  
  init(vector: ValueVector, metaData: ChartValueVectorMetaData) {
    self.metaData = metaData
    self.vector = vector
    self.max = vector.max() ?? 0
    self.min = vector.min() ?? 0
    self.nVector = normalizedVector(from: vector)
  }
  
}

struct NormalizedValueVector {
  
  let vector: ValueVector
  let normalizationRange: ClosedRange<CGFloat>

  init(normalizedVector: ValueVector, normalizationRange: ClosedRange<CGFloat>) {
    self.vector = normalizedVector
    self.normalizationRange = normalizationRange
  }
  
}

struct NormalizedValueVectorGroup {
  let vectors: [ValueVector]
  let normalizationRange: ClosedRange<CGFloat>
}


struct OddlyNormalizedValueVectorGroup {
  let vectors: [ValueVector]
  let excludedIdxs: [Int]
}
