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
  
  override func getPathsToDraw(with points: [[CGPoint]]) -> [CGPath] {
    return points.map{squareBezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
  }
  
  override func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      filledShapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor)
    }
  }
  
  //MARK: - Annotations
  
  private var chartAnnotationMaskColor = UIApplication.myDelegate.currentTheme.foregroundColor.withAlphaComponent(0.75).cgColor
  
  override func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    addSubview(chartAnnotation.annotationView)
    lineLayer.addSublayer(chartAnnotation.leftMask)
    lineLayer.addSublayer(chartAnnotation.rightMask)
  }
  
  override func generateChartAnnotation(for index: Int, with annotationView: TGCAChartAnnotationView) -> ChartAnnotationProtocol {
    let (leftPath, rightPath) = getPathsForChartAnnotation(at: index)
    let leftMask = filledShapeLayer(withPath: leftPath, color: chartAnnotationMaskColor)
    let rightMask = filledShapeLayer(withPath: rightPath, color: chartAnnotationMaskColor)
    
    
    //TODO: THis is a workaround against visible borders
    leftMask.lineWidth = 0.5
    leftMask.strokeColor = chartAnnotationMaskColor
    rightMask.lineWidth = 0.5
    rightMask.strokeColor = chartAnnotationMaskColor
    
    annotationView.layer.zPosition = zPositions.Annotation.view.rawValue
    
    return ChartAnnotation(leftMask: leftMask, annotationView: annotationView, rightMask: rightMask, displayedIndex: index)
  }
  
  override func performUpdatesForMovingChartAnnotation(to index: Int, with chartAnnotation: ChartAnnotationProtocol, animated: Bool) {
    guard let currentChartAnnotation = currentChartAnnotation as? ChartAnnotation else {
      return
    }
    let (leftPath, rightPath) = getPathsForChartAnnotation(at: index)
    
    currentChartAnnotation.leftMask.path = leftPath
    currentChartAnnotation.rightMask.path = rightPath
  }
  
  override func removeChartAnnotation() {
    if let annotation = currentChartAnnotation as? ChartAnnotation {
      annotation.leftMask.removeFromSuperlayer()
      annotation.rightMask.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      currentChartAnnotation = nil
    }
  }

  
  private func getPathsForChartAnnotation(at index: Int) -> (leftPath: CGPath, rightPath: CGPath) {
    let nonHiddenMaximumIndex = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}.sorted().max()!
    let yPositions = drawings.yVectorData.yVectors[nonHiddenMaximumIndex]
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
  
  //MARK: - Configuration
  
  override func configureChartBounds() {
    chartBounds = CGRect(x: bounds.origin.x,
                         y: bounds.origin.y,
                         width: bounds.width,
                         height: bounds.height
                          - (shouldDisplayAxesAndLabels ? ChartViewConstants.sizeForGuideLabels.height : 0))
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
