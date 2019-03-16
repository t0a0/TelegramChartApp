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
  var maxValue = vector.max() ?? 0
  var minValue = vector.min() ?? 0
  guard maxValue != minValue else {
    return NormalizedValueVector(normalizedVector: vector.map{_ in 0}, normalizationRange: normalizationRange)
  }
  //we want to normalize positive vector
  let positiveVector = minValue >= 0 ? vector : vector.map{$0 - minValue}
  if minValue < 0 {
    minValue -= minValue
    maxValue -= minValue
  }
  let normalizedVector = positiveVector.map{
    (($0 - minValue) / (maxValue - minValue)) *
      (normalizationRange.upperBound - normalizationRange.lowerBound) +
      normalizationRange.lowerBound
  }
  return NormalizedValueVector(normalizedVector: normalizedVector, normalizationRange: normalizationRange)
}

func normalizedVectorGroup(from vectors: [ValueVector], withNormalizationRange normalizationRange: ClosedRange<CGFloat> = ZORange) -> NormalizedValueVectorGroup {
  var absMin = vectors.map{$0.min() ?? 0}.min() ?? 0
  var absMax = vectors.map{$0.max() ?? 0}.max() ?? 0
  //TODO: may be instead of calculating again use normalized vecotr method but pass the min max range
  guard absMax != absMin else {
    return NormalizedValueVectorGroup(vectors: vectors.map{$0.map{_ in 0}}, normalizationRange: normalizationRange)
  }
  let positiveVectors = absMin >= 0 ? vectors : vectors.map{$0.map{$0 - absMin}}
  if absMin < 0 {
    absMin -= absMin
    absMax -= absMax
  }
  let normalizedVectors = positiveVectors.map{$0.map{
    (($0 - absMin) / (absMax - absMin)) *
      (normalizationRange.upperBound - normalizationRange.lowerBound) +
      normalizationRange.lowerBound
    }}
  
  return NormalizedValueVectorGroup(vectors: normalizedVectors, normalizationRange: normalizationRange)
  
}

func oddlyNormalizedVectorGroup(from vectors: [ValueVector], skippingIndexes skipIdxs: [Int] = []) -> (oddGroup: OddlyNormalizedValueVectorGroup, yRange: ClosedRange<CGFloat> ) {
  let indexesToSkip = Set(skipIdxs).sorted() //remove duplicates and sort ascending. This is important!
  
  //  assert((indexesToSkip.max() ?? 0) < vectors.count && (indexesToSkip.min() ?? 0) < vectors.count, "Skipping indexes array contains value > vectors.count") TODO: this assert check is correct, but do i need it?
  
  var minimum: CGFloat = 0
  var maximum: CGFloat = 0
  for i in 0..<vectors.count {
    if indexesToSkip.contains(i) { continue }
    minimum = min(minimum, vectors[i].min() ?? 0)
    maximum = max(maximum, vectors[i].max() ?? 0)
  }
  
  guard minimum != maximum else {
    return (OddlyNormalizedValueVectorGroup(vectors: vectors.map{Array(repeating: 0.5, count: $0.count)}, excludedIdxs: skipIdxs), minimum...maximum*2)
  }
  var positiveVectors = minimum >= 0 ? vectors : vectors.map{$0.map{$0 - minimum}}
  if minimum < 0 {
    minimum -= minimum
    maximum -= minimum
  }
  
  // Present vectors are the ones that we don't skip. We normalize them together.
  var presentVectors = [ValueVector]()
  for i in 0..<positiveVectors.count {
    if indexesToSkip.contains(i) { continue }
    presentVectors.append(positiveVectors[i])
  }
  
  let allNormalized = normalizedVectorGroup(from: vectors)
  
  var maxxxGood:CGFloat = 0
  var minnnGood:CGFloat = 1
  for i in 0..<allNormalized.vectors.count {
    if !indexesToSkip.contains(i) {
      maxxxGood = max(maxxxGood, allNormalized.vectors[i].max()!)
      minnnGood = min(minnnGood, allNormalized.vectors[i].min()!)
    }
  }
  let normalizedPresentVectors = normalizedVectorGroup(from: presentVectors).vectors
  
  // Now we need to return an array of vectors with the same order that was given, where non-skipped vectors are normalized in 0...1 and skipped ones are scaled against newly calculated present vectors.
  var iterationIndexInNormalizedPresentVectors = 0
  for i in 0..<positiveVectors.count {
    if indexesToSkip.contains(i) {
      positiveVectors[i] = allNormalized.vectors[i].map {($0 - minnnGood) / (maxxxGood - minnnGood)}
    }
    else {
      positiveVectors[i] = normalizedPresentVectors[iterationIndexInNormalizedPresentVectors]
      // Keeping the correct order
      iterationIndexInNormalizedPresentVectors += 1
    }
  }
  //TODO: min max here are made to be positive, would be a problem if there werenegative values on the graph
  return (OddlyNormalizedValueVectorGroup(vectors: positiveVectors, excludedIdxs: indexesToSkip), minimum...maximum)
}
