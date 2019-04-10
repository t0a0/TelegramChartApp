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
    
    updateCurrentYValueRange(with: normalizedYVectors.yRange)

    var draws = [Drawing]()
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let squareLine = squareBezierLine(withPoints: points)
      let line = bezierArea(topPath: squareLine, bottomPath: bezierLine(from: CGPoint(x: points[0].x, y: chartBoundsBottom), to: CGPoint(x: points.last!.x, y: chartBoundsBottom)))
      let shape = filledShapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor)
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
    
    updateCurrentYValueRange(with: normalizedYVectors.yRange)

    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = mapToChartBoundsHeight(normalizedYVectors.vectors[i])
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      drawing.yPositions = yVector
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
    drawings.xPositions = xVector
  }
  
  override func updateChartByHiding(at index: Int, originalHidden: Bool) {
    let normalizedYVectors = getNormalizedYVectors()
    let xVector = drawings.xPositions
    
    updateCurrentYValueRange(with: normalizedYVectors.yRange)

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
      
      drawing.yPositions = yVector
    }
  }
  
  //MARK: - Annotations
  private var chartAnnotationMaskColor = UIApplication.myDelegate.currentTheme.backgroundColor.withAlphaComponent(0.75).cgColor
  
  override func addChartAnnotation(for index: Int) {
    let (leftPath, rightPath) = getPathsForChartAnnotation(at: index)
    let leftMask = filledShapeLayer(withPath: leftPath, color: chartAnnotationMaskColor)
    let rightMask = filledShapeLayer(withPath: rightPath, color: chartAnnotationMaskColor)

    lineLayer.addSublayer(leftMask)
    lineLayer.addSublayer(rightMask)
    
    currentChartAnnotation = ChartAnnotation(leftMask: leftMask, annotationView: TGCAChartAnnotationView(), rightMask: rightMask, displayedIndex: index)
  }
  
  override func moveChartAnnotation(to index: Int, animated: Bool = false) {
    guard let currentChartAnnotation = currentChartAnnotation as? ChartAnnotation else {
      return
    }
    let (leftPath, rightPath) = getPathsForChartAnnotation(at: index)

    currentChartAnnotation.leftMask.path = leftPath
    currentChartAnnotation.rightMask.path = rightPath
    currentChartAnnotation.updateDisplayedIndex(to: index)
  }
  
  override func removeChartAnnotation() {
    if let annotation = currentChartAnnotation {
      (currentChartAnnotation as? ChartAnnotation)?.leftMask.removeFromSuperlayer()
      (currentChartAnnotation as? ChartAnnotation)?.rightMask.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      currentChartAnnotation = nil
    }
  }
  
  private func getPathsForChartAnnotation(at index: Int) -> (leftPath: CGPath, rightPath: CGPath) {
    let yPositions = drawings.drawings[0].yPositions
    let xPositions = drawings.xPositions
    
    var rightPath = CGPath(rect: CGRect.zero, transform: nil)
    
    if index != xPositions.count - 1 {
      let rightYvector = Array(yPositions[(index+1)..<yPositions.count])
      let rightXvector = Array(xPositions[(index+1)..<yPositions.count])
      let rightPoints = convertToPoints(xVector: rightXvector, yVector: rightYvector)
      rightPath = squareBezierArea(topPoints: rightPoints, bottom: chartBoundsBottom).cgPath
    }
    
    let leftYvector = Array(yPositions[0...index])
    let leftXvector = Array(xPositions[0...index])
    let leftPoints = convertToPoints(xVector: leftXvector, yVector: leftYvector)
    let leftPath = squareBezierArea(topPoints: leftPoints, bottom: chartBoundsBottom).cgPath
    
    return (leftPath, rightPath)
  }
  
  //MARK: - Classes and structs
  
  private class ChartAnnotation: BaseChartAnnotation {
    let leftMask: CAShapeLayer
    let rightMask: CAShapeLayer
    
    init(leftMask: CAShapeLayer, annotationView: TGCAChartAnnotationView, rightMask: CAShapeLayer, displayedIndex: Int){
      self.leftMask = leftMask
      self.rightMask = rightMask
      super.init(annotationView: annotationView, displayedIndex: displayedIndex)
    }

  }
  
}
