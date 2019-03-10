//
//  DataSetModel.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

struct DataSetPoint {
  
  let x: CGFloat
  let y: CGFloat
  
}

extension Array where Element == DataSetPoint {
  
  var maxX: CGFloat {
    return map{$0.x}.max() ?? 0
  }
  
  var maxY: CGFloat {
    return map{$0.y}.max() ?? 0
  }
  
  var minX: CGFloat {
    return map{$0.x}.min() ?? 0
  }
  
  var minY: CGFloat {
    return map{$0.y}.min() ?? 0
  }
  
}

extension Array where Element == NormalizedDataSetPoint {
  
  var maxX: CGFloat {
    return map{$0.x}.max() ?? 0
  }
  
  var maxY: CGFloat {
    return map{$0.y}.max() ?? 0
  }
  
  var minX: CGFloat {
    return map{$0.x}.min() ?? 0
  }
  
  var minY: CGFloat {
    return map{$0.y}.min() ?? 0
  }
  
}

struct NormalizedDataSetPoint {
  /// X value between 0.0 and 1.0
  let x: CGFloat
  
  /// Y value between 0.0 and 1.0
  let y: CGFloat
  
  init(x: CGFloat, y: CGFloat) {
    self.x = max(min(1, x), 0)
    self.y = max(min(1, y), 0)
  }
}

struct NormalizedDataSet {
  let points: [NormalizedDataSetPoint]
  
  var maxX: CGFloat {
    return points.maxX
  }
  
  var maxY: CGFloat {
    return points.maxY
  }
  
  var minX: CGFloat {
    return points.minX
  }
  
  var minY: CGFloat {
    return points.minY
  }
}

struct DataSet {
  let points: [DataSetPoint]
  
  var maxX: CGFloat {
    return points.maxX
  }
  
  var maxY: CGFloat {
    return points.maxY
  }
  
  var minX: CGFloat {
    return points.minX
  }
  
  var minY: CGFloat {
    return points.minY
  }
}

extension Array where Element == DataSet {
  
  var maxX: CGFloat {
    return map{$0.maxX}.max() ?? 0
  }
  
  var maxY: CGFloat {
    return map{$0.maxY}.max() ?? 0
  }
  
  var minX: CGFloat {
    return map{$0.minX}.min() ?? 0
  }
  
  var minY: CGFloat {
    return map{$0.minY}.min() ?? 0
  }
  
}
