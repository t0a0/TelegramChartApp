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
  
  struct BarChartViewConstants {
    struct AnimationKeys {
      static let maskAnim = "maskAnim"
    }
  }
  
  override func getPathsToDraw(with points: [[CGPoint]]) -> [CGPath] {
    return points.map{squareBezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
  }
  
  override func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      filledShapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor)
    }
  }
  
  //MARK: - Annotations
  

  override func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    addSubview(chartAnnotation.annotationView)
    chartDrawingsLayer.addSublayer(chartAnnotation.leftMask)
    chartDrawingsLayer.addSublayer(chartAnnotation.rightMask)
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
    
    if animated {
      var oldLeftPath: Any?
      if let _ = currentChartAnnotation.leftMask.animation(forKey: BarChartViewConstants.AnimationKeys.maskAnim) {
        oldLeftPath = currentChartAnnotation.leftMask.presentation()?.value(forKey: "path")
        currentChartAnnotation.leftMask.removeAnimation(forKey: BarChartViewConstants.AnimationKeys.maskAnim)
      }
      
      let leftPathAnim = CABasicAnimation(keyPath: "path")
      leftPathAnim.fromValue = oldLeftPath ?? currentChartAnnotation.leftMask.path
      currentChartAnnotation.leftMask.path = leftPath
      leftPathAnim.toValue = currentChartAnnotation.leftMask.path
      
      
      
      var oldRightPath: Any?
      if let _ = currentChartAnnotation.rightMask.animation(forKey: BarChartViewConstants.AnimationKeys.maskAnim) {
        oldRightPath = currentChartAnnotation.rightMask.presentation()?.value(forKey: "path")
        currentChartAnnotation.rightMask.removeAnimation(forKey: BarChartViewConstants.AnimationKeys.maskAnim)
      }
      
      let rightPathAnim = CABasicAnimation(keyPath: "path")
      rightPathAnim.fromValue = oldRightPath ?? currentChartAnnotation.rightMask.path
      currentChartAnnotation.rightMask.path = rightPath
      rightPathAnim.toValue = currentChartAnnotation.rightMask.path
      
     
      leftPathAnim.duration = CHART_PATH_ANIMATION_DURATION
      rightPathAnim.duration = CHART_PATH_ANIMATION_DURATION
      
      currentChartAnnotation.leftMask.add(leftPathAnim, forKey: BarChartViewConstants.AnimationKeys.maskAnim)
      currentChartAnnotation.rightMask.add(rightPathAnim, forKey: BarChartViewConstants.AnimationKeys.maskAnim)

    } else {
      currentChartAnnotation.leftMask.path = leftPath
      currentChartAnnotation.rightMask.path = rightPath
    }

  }
  
  override func removeChartAnnotation() {
    if let annotation = currentChartAnnotation as? ChartAnnotation {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      annotation.leftMask.removeFromSuperlayer()
      annotation.rightMask.removeFromSuperlayer()
      CATransaction.commit()
      annotation.annotationView.removeFromSuperview()
      currentChartAnnotation = nil
    }
  }

  
  private func getPathsForChartAnnotation(at index: Int) -> (leftPath: CGPath, rightPath: CGPath) {
    let nonHiddenMaximumIndex = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}.sorted().max()!
    let yPositions = drawings.yVectorData.yVectors[nonHiddenMaximumIndex]
    let xPositions = drawings.xPositions
    return squareBezierMaskAreas(topPoints: convertToPoints(xVector: xPositions, yVector: yPositions), bottom: chartBoundsBottom, visibleIdx: index)
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
  
  //MARK: Theme
  
  private var chartAnnotationMaskColor = UIColor.black.cgColor

  override func applyColors() {
    super.applyColors()
    let theme = UIApplication.myDelegate.currentTheme
    chartAnnotationMaskColor = theme.chartMaskColor.cgColor
    axisXLabelColor = theme.xAxisLabelColorForFilledCharts.cgColor
    axisYLabelColor = theme.yAxisLabelColorForFilledCharts.cgColor
    axisColor = theme.axisColorForFilledCharts.cgColor
  }
  
  override func applyChanges() {
    (currentChartAnnotation as? ChartAnnotation)?.leftMask.fillColor = chartAnnotationMaskColor
    (currentChartAnnotation as? ChartAnnotation)?.rightMask.fillColor = chartAnnotationMaskColor
    (currentChartAnnotation as? ChartAnnotation)?.leftMask.strokeColor = chartAnnotationMaskColor
    (currentChartAnnotation as? ChartAnnotation)?.rightMask.strokeColor = chartAnnotationMaskColor
    super.applyChanges()
  }
  
}
