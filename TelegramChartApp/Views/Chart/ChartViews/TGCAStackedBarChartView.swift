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
    let translatedBounds = chart.translatedBounds(for: currentTrimRange)

    return chartConfiguration.valuesStartFromZero
      ? chart.normalizedStackedYVectorsFromZeroMinimum(in: translatedBounds, excludedIndicies: hiddenDrawingIndicies)
      : chart.normalizedStackedYVectorsFromLocalMinimum(in: translatedBounds, excludedIndicies: hiddenDrawingIndicies)
  }
  
  override func animateChartHide(at indexes: Set<Int>, originalHiddens: Set<Int>, newPaths: [CGPath]) {
    for i in 0..<drawings.shapeLayers.count {
      let shapeLayer = drawings.shapeLayers[i]
      
      var oldPath: Any?
      if let _ = shapeLayer.animation(forKey: "pathAnimation") {
        oldPath = shapeLayer.presentation()?.value(forKey: "path")
        shapeLayer.removeAnimation(forKey: "pathAnimation")
      }
      
      let positionChangeBlock = {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = oldPath ?? shapeLayer.path
        shapeLayer.path = newPaths[i]
        pathAnimation.toValue = shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      }
      
      if !chartConfiguration.isThumbnail {
        positionChangeBlock()
      } else {
        if !hiddenDrawingIndicies.contains(i) && !(originalHiddens.contains(i) && indexes.contains(i)) {
          positionChangeBlock()
        }
        if (originalHiddens.contains(i) && indexes.contains(i)) {
          shapeLayer.path = newPaths[i]
        }
      }
      
      if indexes.contains(i) {
        var oldOpacity: Any?
        if let _ = shapeLayer.animation(forKey: "opacityAnimation") {
          oldOpacity = shapeLayer.presentation()?.value(forKey: "opacity")
          shapeLayer.opacity = (oldOpacity as? Float) ?? shapeLayer.opacity
          shapeLayer.removeAnimation(forKey: "opacityAnimation")
        }
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        let targetOpacity: Float = originalHiddens.contains(i) ? 1 : 0
        
        opacityAnimation.values = [oldOpacity ?? shapeLayer.opacity, targetOpacity]
        shapeLayer.opacity = targetOpacity
        opacityAnimation.keyTimes = (chartConfiguration.isThumbnail || hiddenDrawingIndicies.count == chart.yVectors.count || (hiddenDrawingIndicies.count == chart.yVectors.count - 1 && originalHiddens.contains(i))) ? [0.0, 1.0] : (originalHiddens.contains(i) ? [0.0, 0.25] : [0.75, 1.0])
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  override func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.reversed().forEach{
      chartDrawingsLayer.addSublayer($0)
    }
  }

  override func getMaxPossibleLabelsCountForChartAnnotation() -> Int {
    return chart.yVectors.count + 1
  }
  
  override func getChartAnnotationViewConfiguration(for index: Int) -> TGCAChartAnnotationView.AnnotationViewConfiguration {
    let includedIndicies = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    var summ: CGFloat = 0
    var coloredValues: [TGCAChartAnnotationView.ColoredValue] = includedIndicies.map{
      let yVector = chart.yVectors[$0]
      summ += yVector.vector[index]
      return TGCAChartAnnotationView.ColoredValue(title: yVector.metaData.name, value: yVector.vector[index], color: yVector.metaData.color)
    }
    coloredValues.sort { (left, right) -> Bool in
      return left.value >= right.value
    }
    if includedIndicies.count > 1 {
      coloredValues.append(TGCAChartAnnotationView.ColoredValue(title: "All", value: summ, color: nil))
    }
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: !isUnderlying, mode: isUnderlying ? .Time : .Date, showsLeftColumn: false, coloredValues: coloredValues)
  }

}
