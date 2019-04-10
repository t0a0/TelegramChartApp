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
  
  override func animateChartHide(at index: Int, originalHidden: Bool, newPaths: [CGPath]) {
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      
      var oldPath: Any?
      if let _ = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        oldPath = drawing.shapeLayer.presentation()?.value(forKey: "path")
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
      }
      
      let positionChangeBlock = {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = oldPath ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPaths[i]
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      }
      
      if animatesPositionOnHide {
        positionChangeBlock()
      } else {
        if !hiddenDrawingIndicies.contains(i) && !(originalHidden && i == index) {
          positionChangeBlock()
        }
        if (originalHidden && i == index) {
          drawing.shapeLayer.path = newPaths[i]
        }
      }
      
      if i == index {
        var oldOpacity: Any?
        if let _ = drawing.shapeLayer.animation(forKey: "opacityAnimation") {
          oldOpacity = drawing.shapeLayer.presentation()?.value(forKey: "opacity")
          drawing.shapeLayer.opacity = (oldOpacity as? Float) ?? drawing.shapeLayer.opacity
          drawing.shapeLayer.removeAnimation(forKey: "opacityAnimation")
        }
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        let targetOpacity: Float = originalHidden ? 1 : 0
        
        opacityAnimation.values = [oldOpacity ?? drawing.shapeLayer.opacity, targetOpacity]
        drawing.shapeLayer.opacity = targetOpacity
        opacityAnimation.keyTimes = (hiddenDrawingIndicies.count == chart.yVectors.count || (hiddenDrawingIndicies.count == chart.yVectors.count - 1 && originalHidden)) ? [0.0, 1.0] : (originalHidden ? [0.0, 0.25] : [0.75, 1.0])
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  override func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.reversed().forEach{
      lineLayer.addSublayer($0)
    }
  }

}
