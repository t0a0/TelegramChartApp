//
//  TGCAPercentageChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 07/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAPercentageChartView: TGCAChartView {
  
  override func drawChart() {
    updateChartPercentageYVectors()
    
    let yVectors = getPercentageYVectors().map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    updateCurrentYValueRange(with: 0...100)
    
    var draws = [Drawing]()
    var shapes = [CAShapeLayer]()
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let line = bezierLine(withPoints: points)
      let area = bezierArea(topPath: line, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      let shape = filledShapeLayer(withPath: area.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
      if hiddenDrawingIndicies.contains(i) {
        shape.opacity = 0
      }
      shapes.append(shape)
      draws.append(Drawing(shapeLayer: shape, yPositions: yVector))
    }
    shapes.reversed().forEach{
      lineLayer.addSublayer($0)
    }
    drawings = ChartDrawings(drawings: draws, xPositions: xVector)
  }
  
  override func updateChart() {
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let yVectors = getPercentageYVectors().map{mapToChartBoundsHeight($0)}
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      drawing.yPositions = yVector
      let line = bezierLine(withPoints: points)
      let newPath = bezierArea(topPath: line, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      drawing.shapeLayer.path = newPath.cgPath
    }
    drawings.xPositions = xVector
  }
  
  override func updateChartByHiding(at index: Int, originalHidden: Bool) {
    updateChartPercentageYVectors()
    let yVectors = getPercentageYVectors().map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let line = bezierLine(withPoints: points)
      let newPath = bezierArea(topPath: line, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      
      var oldPath: Any?
      if let _ = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        oldPath = drawing.shapeLayer.presentation()?.value(forKey: "path")
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
      }
      
      let positionChangeBlock = {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = oldPath ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
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
          drawing.shapeLayer.path = newPath.cgPath
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
      
      drawing.yPositions = yVector
    }
    drawings.xPositions = xVector
  }
  
  //MARKL - Get Y vectors
  
  private var chartPercentageYVectors: [ValueVector]!
  private func updateChartPercentageYVectors() {
    chartPercentageYVectors = chart.percentageYVectors(excludedIndicies: hiddenDrawingIndicies)
  }
  private func getPercentageYVectors() -> [ValueVector] {
    return chartPercentageYVectors
  }
  
}
