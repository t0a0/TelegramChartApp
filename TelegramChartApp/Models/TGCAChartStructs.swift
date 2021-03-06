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

enum DataChartType: String {
  case linear
  case linearWith2Axes
  case singleBar
  case stackedBar
  case percentage
  case threeDaysComparison
  case pie
}

struct DataChart {
  
  let title: String?
  let type: DataChartType
  let yVectors: [ChartValueVector]
  let xVector: ValueVector
  let datesVector: [Date]
  let showsAxisLabelsOnBothSides = true
  let normalizedXPositions: [CGFloat]
  
  init(yVectors: [ChartValueVector], xVector: ValueVector, type: DataChartType, title: String? = nil) {
    yVectors.forEach{
      assert($0.vector.count == xVector.count, "Trying to init Chart with unmatching (X,Y) points count.")
    }
    
    self.yVectors = yVectors
    self.xVector = xVector
    self.normalizedXPositions = (0..<xVector.count).map{(CGFloat($0)/CGFloat(xVector.count - 1))}
    self.title = title
    self.type = type
    self.datesVector = xVector.map{Date(timeIntervalSince1970: TimeInterval($0 / 1000.0))}
  }
  
  func normalizedYVectorsFromZeroMinimum(in xRange: ClosedRange<Int>, excludedIdxs: Set<Int>) -> NormalizedYVectors {

    let vectors = yVectors.map{$0.vector}
    
    var maximum: CGFloat = 0
    for i in 0..<vectors.count {
      if !excludedIdxs.contains(i) {
        maximum = max(maximum, vectors[i][xRange].max() ?? 0)
      }
    }
    guard 0 != maximum else {
      return (vectors.map{$0.map{_ in 0}}, 0...0)
    }
    
    return (vectors.map{$0.map{$0 / maximum}}, 0...maximum)
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
        return (Array(repeating: 0.0, count: $0.count), 0...0)
      }
      return ($0.map{(($0 - min) / (max - min))}, min...max)
    }
  }
  
  /// For stacked bar chart
  func normalizedStackedYVectorsFromZeroMinimum(in xRange: ClosedRange<Int>, excludedIndicies: Set<Int>) -> NormalizedYVectors {
    guard excludedIndicies.count != yVectors.count else {
      return (Array(repeating: Array(repeating: 0.0, count: xVector.count), count: yVectors.count), 0...0)
    }
    
    let includedIdxs = (0..<yVectors.count).filter{!excludedIndicies.contains($0)}.sorted()
    
    let stacked = stackedVectors(includedIdxs.map{yVectors[$0].vector})
    let max = stacked.last![xRange].max()!
    
    let normalizedStacked = stacked.map{$0.map{$0/max}}
    var retVal = [ValueVector]()
    var j = 0
    for i in 0..<yVectors.count {
      if includedIdxs.contains(i) {
        retVal.append(normalizedStacked[j])
        j += 1
      } else {
        if i == 0 {
          retVal.append(Array(repeating: 0.0, count: xVector.count))
        } else {
          retVal.append(retVal[i-1])
        }
      }
    }
    
    return (retVal, 0...max)
  }
  
  func normalizedStackedYVectorsFromLocalMinimum(in xRange: ClosedRange<Int>, excludedIndicies: Set<Int>) -> NormalizedYVectors {
    guard excludedIndicies.count != yVectors.count else {
      return (Array(repeating: Array(repeating: 0.0, count: xVector.count), count: yVectors.count), 0...0)
    }
    
    let includedIdxs = (0..<yVectors.count).filter{!excludedIndicies.contains($0)}.sorted()
    
    let stacked = stackedVectors(includedIdxs.map{yVectors[$0].vector})
    let max = stacked.last![xRange].max()!
    let min = stacked.first![xRange].min()!
    
    let normalizedStacked = stacked.map{$0.map{($0-min)/(max-min)}}
    var retVal = [ValueVector]()
    var j = 0
    for i in 0..<yVectors.count {
      if includedIdxs.contains(i) {
        retVal.append(normalizedStacked[j])
        j += 1
      } else {
        if i == 0 {
          retVal.append(Array(repeating: 0.0, count: xVector.count))
        } else {
          retVal.append(retVal[i-1])
        }
      }
    }
    
    return (retVal, min...max)
  }
  
  /// For percentage chart
  func percentageYVectors(excludedIndicies: Set<Int>) -> [ValueVector] {
    let includedIdxs = (0..<yVectors.count).filter{!excludedIndicies.contains($0)}.sorted()
    guard let firstIncludedIdx = includedIdxs.first else {
      //for animation
      return Array(repeating: Array(repeating: 1.0, count: xVector.count), count: yVectors.count)
    }
    if includedIdxs.count == 1 {
      //for animatiom
      var a: [ValueVector] = Array(repeating: Array(repeating: 0.0, count: xVector.count), count: firstIncludedIdx)
      a.append(contentsOf: Array(repeating: Array(repeating: 1.0, count: xVector.count), count: yVectors.count - firstIncludedIdx))
      return a
    }
    
    let stacked = stackedVectors(includedIdxs.map{yVectors[$0].vector})
    let maximums = stacked.last!
    let percentage = stacked.map{zip($0, maximums).map{$0 / $1}}

    
    var retVal = [ValueVector]()
    var j = 0
    for i in 0..<yVectors.count {
      if includedIdxs.contains(i) {
        retVal.append(percentage[j])
        j += 1
      } else {
        //this is for hiding animation
        if i == 0 {
          retVal.append(Array(repeating: 0.0, count: xVector.count))
        } else if i == yVectors.count - 1 {
          retVal.append(Array(repeating: 1.0, count: xVector.count))
        } else {
          retVal.append(retVal[i-1])
        }
      }
    }
    return retVal
  }
  
  //returns only included indexes
  func percentages(at index: Int, includedIndicies: [Int]) -> [Int] {
    let arrayNum = includedIndicies.map{yVectors[$0].vector[index]}
    let sum = arrayNum.reduce(0, +)
    return arrayNum.map{Int(($0 * 100 / sum).rounded())}
  }
  
  ///returns all indexes even hidden, they are zero
  func percentages(at indexes: [Int], includedIndicies: [Int]) -> [Int] {
    let arrayNum = includedIndicies.map{ValueVector(yVectors[$0].vector[indexes.first!...indexes.last!]).sum()}
    let sum = arrayNum.reduce(0, +)
    let percentages = arrayNum.map{Int(($0 * 100 / sum).rounded())}
    
    var retVal = [Int]()
    var j = 0
    for i in 0..<yVectors.count {
      if includedIndicies.contains(i) {
        retVal.append(percentages[j])
        j += 1
      } else {
        retVal.append(0)
      }
    }
    return retVal
  }
  
  func sums(at indexes: [Int], includedIndicies: [Int]) -> [CGFloat] {
    if includedIndicies.count == 0 {
      return (0..<yVectors.count).map{ValueVector(yVectors[$0].vector[indexes.first!...indexes.last!]).sum()}
    }
    let sums =  includedIndicies.map{ValueVector(yVectors[$0].vector[indexes.first!...indexes.last!]).sum()}
    var retVal = [CGFloat]()
    var j = 0
    for i in 0..<yVectors.count {
      if includedIndicies.contains(i) {
        retVal.append(sums[j])
        j += 1
      } else {
        retVal.append(0)
      }
    }
    return retVal
  }
  
  func translatedBounds(for xRange: CGFloatRangeInBounds) -> ClosedRange<Int> {
    return xRange.integerRange(withBounds: 0...(xVector.count-1))
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
  
  /// Pass minimum 2 vectors
  private func stackedVectors(_ vectors: [ValueVector]) -> [ValueVector] {
    var stacked = [vectors[0]]
    for i in 1..<vectors.count {
      stacked.append(zip(vectors[i], stacked[i-1]).map{$0 + $1})
    }
    return stacked
  }
  
  func generatePieChart(for date: Date) -> DataChart? {
    guard type == .percentage, let index = datesVector.firstIndex(of: date) else {
      return nil
    }
    
    var indexes = [Int]()
    
    if index < 3 {
      indexes = (0...6).map{$0}
    } else if index > datesVector.count - 4 {
      indexes = ((datesVector.count-7)...(datesVector.count-1)).map{$0}
    } else {
      indexes = ((index - 3)...(index + 3)).map{$0}
    }
    
    let yVs = yVectors.map{ChartValueVector(vector: ValueVector($0.vector[indexes.first!...indexes.last!]), metaData: $0.metaData)}
    return DataChart(yVectors: yVs, xVector: ValueVector(xVector[indexes.first!...indexes.last!]), type: .pie, title: title)
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
