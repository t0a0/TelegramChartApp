//
//  TGCARangeInBounds.swift
//  TelegramChartApp
//
//  Created by Igor on 12/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

struct CGFloatRangeInBounds {
  
  static let ZeroToOne = CGFloatRangeInBounds(range: 0...1.0, bounds: 0...1.0)

  
  let range: ClosedRange<CGFloat>
  let bounds: ClosedRange<CGFloat>

  var scale: CGFloat {
    return (bounds.upperBound - bounds.lowerBound) / (range.upperBound - range.lowerBound)
  }
  
  var offset: CGFloat {
    return range.lowerBound / (bounds.upperBound - bounds.lowerBound)
  }
  
  func mapTo(newBounds: ClosedRange<CGFloat>) -> CGFloatRangeInBounds {
    let oldBoundsRange = bounds.upperBound - bounds.lowerBound
    let newBoundsRange = newBounds.upperBound - newBounds.lowerBound
    
    let newLowerBound = (((range.lowerBound - bounds.lowerBound) * newBoundsRange) / oldBoundsRange) + newBounds.lowerBound
    let newUpperBound = (((range.upperBound - bounds.lowerBound) * newBoundsRange) / oldBoundsRange) + newBounds.lowerBound
    
    return CGFloatRangeInBounds(range: newLowerBound...newUpperBound, bounds: newBounds)
  }
  
//  func integer(forValueInRange valueInRange: CGFloat, integerBounds: ClosedRange<Int>) -> Int {
//    
//    let oldBoundsRange = bounds.upperBound - bounds.lowerBound
//    let newBoundsRange = CGFloat(integerBounds.upperBound - integerBounds.lowerBound)
//    
//    let newValue = (((range.lowerBound - bounds.lowerBound) * newBoundsRange) / oldBoundsRange) + CGFloat(integerBounds.lowerBound)
//    return Int(round(newValue))
//  }
  
  func integerRange(withBounds integerBounds: ClosedRange<Int>) -> ClosedRange<Int> {
    
    let oldBoundsRange = bounds.upperBound - bounds.lowerBound
    let newBoundsRange = CGFloat(integerBounds.upperBound - integerBounds.lowerBound)
    
    let newLowerBound = (((range.lowerBound - bounds.lowerBound) * newBoundsRange) / oldBoundsRange) + CGFloat(integerBounds.lowerBound)
    let newUpperBound = (((range.upperBound - bounds.lowerBound) * newBoundsRange) / oldBoundsRange) + CGFloat(integerBounds.lowerBound)

    return Int(round(newLowerBound))...Int(round(newUpperBound))
  }
  
}
