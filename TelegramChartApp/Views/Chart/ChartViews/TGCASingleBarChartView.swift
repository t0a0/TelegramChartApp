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
  
  override func getPathsToDraw(with vectorData: VectorDataProtocol) -> [CGPath] {
    let vectorData = vectorData as! VectorData
    return vectorData.points.map{squareBezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
  }
  
  override func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      filledShapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor)
    }
  }
  
  //MARK: - Annotations
  private var chartAnnotationMaskColor = UIApplication.myDelegate.currentTheme.foregroundColor.withAlphaComponent(0.75).cgColor
  
  override func addChartAnnotation(for index: Int) {
    let (leftPath, rightPath) = getPathsForChartAnnotation(at: index)
    let leftMask = filledShapeLayer(withPath: leftPath, color: chartAnnotationMaskColor)
    let rightMask = filledShapeLayer(withPath: rightPath, color: chartAnnotationMaskColor)

    
    //TODO: THis is a workaround against visible borders
    leftMask.lineWidth = 0.5
    leftMask.strokeColor = chartAnnotationMaskColor
    rightMask.lineWidth = 0.5
    rightMask.strokeColor = chartAnnotationMaskColor
    
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
    let nonHiddenMaximumIndex = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}.sorted().max()!
    let yPositions = drawings.drawings[nonHiddenMaximumIndex].yPositions
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
