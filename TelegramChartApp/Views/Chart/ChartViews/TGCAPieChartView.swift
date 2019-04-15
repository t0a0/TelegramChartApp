//
//  TGCAPieChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 15/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAPieChartView: TGCAChartView {
  
  override func commonInit() {
    
  }
  
  override func layoutSubviews() {
    
  }
  
  override func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: CGFloatRangeInBounds) {
    
  }
  
  override func trimDisplayRange(to newRange: CGFloatRangeInBounds, with event: DisplayRangeChangeEvent) {
    
  }
  
  override func toggleHidden(at indexes: Set<Int>) {
    
  }
  
  
  private struct PieSlice {
    let value: CGFloat
    let percentage: CGFloat
    let text: String
  }
  
  func pieSliceShapeLayer(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, fillColor: CGColor) -> CAShapeLayer{
    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    let layer = CAShapeLayer()
    layer.path = path.cgPath
    layer.fillColor = fillColor
    layer.contentsScale = UIScreen.main.scale
    return layer
  }
  
}
