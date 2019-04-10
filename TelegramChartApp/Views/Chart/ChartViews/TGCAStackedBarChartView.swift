//
//  TGCAStackedBarChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAStackedBarChartView: TGCASingleBarChartView {
  
  override func getNormalizedYVectors() -> NormalizedYVectors {
    return valuesStartFromZero
      ? chart.normalizedStackedYVectorsFromZeroMinimum(in: currentXIndexRange, excludedIndicies: hiddenDrawingIndicies)
      : chart.normalizedStackedYVectorsFromLocalMinimum(in: currentXIndexRange, excludedIndicies: hiddenDrawingIndicies)
  }
  
  override func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.reversed().forEach{
      lineLayer.addSublayer($0)
    }
  }

}
