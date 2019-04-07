//
//  TGCASingleBarChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 07/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCASingleBarChartView: TGCAChartView {
  
  override func drawChart() {
    let normalizedYVectors = getNormalizedYVectors()
    let yVectors = normalizedYVectors.vectors.map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    currentYValueRange = normalizedYVectors.yRange
    
    var draws = [Drawing]()
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let squareLine = squareBezierLine(withPoints: points)
      let line = bezierArea(topPath: squareLine, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      let shape = filledShapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
      if hiddenDrawingIndicies.contains(i) {
        shape.opacity = 0
      }
      lineLayer.addSublayer(shape)
      draws.append(Drawing(shapeLayer: shape, yPositions: yVector))
    }
    drawings = ChartDrawings(drawings: draws, xPositions: xVector)
  }
  
  override func updateChart() {
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let normalizedYVectors = getNormalizedYVectors()
    
    let didYChange = currentYValueRange != normalizedYVectors.yRange
    
    currentYValueRange = normalizedYVectors.yRange
    
    var newDrawings = [Drawing]()
    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = mapToChartBoundsHeight(normalizedYVectors.vectors[i])
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      newDrawings.append(Drawing(shapeLayer: drawing.shapeLayer, yPositions: yVector))
      let squareLine = squareBezierLine(withPoints: points)
      let newPath = bezierArea(topPath: squareLine, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      
      if let oldAnim = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.presentation()?.value(forKey: "path") ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        if !didYChange {
          pathAnimation.beginTime = oldAnim.beginTime
        } else {
          pathAnimation.beginTime = CACurrentMediaTime()
        }
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      } else {
        if didYChange  {
          let pathAnimation = CABasicAnimation(keyPath: "path")
          pathAnimation.fromValue = drawing.shapeLayer.path
          drawing.shapeLayer.path = newPath.cgPath
          pathAnimation.toValue = drawing.shapeLayer.path
          pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
          pathAnimation.beginTime = CACurrentMediaTime()
          drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
        } else {
          drawing.shapeLayer.path = newPath.cgPath
        }
      }
    }
    self.drawings = ChartDrawings(drawings: newDrawings, xPositions: xVector)
  }
  
  override func updateChartByHiding(at index: Int, originalHidden: Bool) {
    let normalizedYVectors = getNormalizedYVectors()
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    currentYValueRange = normalizedYVectors.yRange
    
    var newDrawings = [Drawing]()
    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = mapToChartBoundsHeight(normalizedYVectors.vectors[i])
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let squareLine = squareBezierLine(withPoints: points)
      let newPath = bezierArea(topPath: squareLine, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      
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
          drawing.shapeLayer.removeAnimation(forKey: "opacityAnimation")
        }
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = oldOpacity ?? drawing.shapeLayer.opacity
        drawing.shapeLayer.opacity = originalHidden ? 1 : 0
        opacityAnimation.toValue = drawing.shapeLayer.opacity
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
      
      newDrawings.append(Drawing(shapeLayer: drawing.shapeLayer, yPositions: yVector))
    }
    drawings = ChartDrawings(drawings: newDrawings, xPositions: xVector)
  }
}
