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
  
  override func getCurrentVectorData() -> VectorDataProtocol {
    let normalizedYVectors = chart.normalizedStackedYVectorsFromZeroMinimum(in: currentXIndexRange, excludedIndicies: hiddenDrawingIndicies)
    let yVectors = normalizedYVectors.vectors.map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let points = (0..<yVectors.count).map{
      convertToPoints(xVector: xVector, yVector: yVectors[$0])
    }
    return VectorData(xVector: xVector, yVectors: yVectors, yRangeData: YRangeData(yRange: normalizedYVectors.yRange), points: points)
  }
  
  override func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.reversed().forEach{
      lineLayer.addSublayer($0)
    }
  }

}
