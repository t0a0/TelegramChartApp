//
//  ClosedRange+Distance.swift
//  TelegramChartApp
//
//  Created by Igor on 19/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

extension ClosedRange where Bound == CGFloat {
  
  var distance: CGFloat {
    return upperBound - lowerBound
  }

}

extension ClosedRange where Bound == Int {
  
  var distance: Int {
    return upperBound - lowerBound
  }
  
}
