//
//  TGCASquarePercentageChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 14/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCASquarePercentageChartView: TGCAPercentageChartView {
  
  override func getPathsToDraw(with points: [[CGPoint]]) -> [CGPath] {
    return points.map{squareBezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
  }
  
}
