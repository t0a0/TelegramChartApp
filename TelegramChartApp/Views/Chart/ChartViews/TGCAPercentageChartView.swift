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
  
  private struct PercentageYRangeData: YRangeDataProtocol {}
  
  override func prepareToDrawChart() {
    updateChartPercentageYVectors()
  }
  
  override func prepareToUpdateChartByHiding() {
    updateChartPercentageYVectors()
  }
  
  override func getCurrentVectorData() -> VectorDataProtocol {
    let yVectors = getPercentageYVectors().map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let points = (0..<yVectors.count).map{
      convertToPoints(xVector: xVector, yVector: yVectors[$0])
    }
    return VectorData(xVector: xVector, yVectors: yVectors, yRangeData: PercentageYRangeData(), points: points)
  }
  
  override func updateYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResultProtocol? {
    return nil
  }
  
  override func getPathsToDraw(with vectorData: VectorDataProtocol) -> [CGPath] {
    let vectorData = vectorData as! VectorData
    return vectorData.points.map{bezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
  }
  
  override func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      filledShapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor)
    }
  }
  
  override func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.reversed().forEach{
      lineLayer.addSublayer($0)
    }
  }
  
  override func animateChartUpdate(withYChangeResult yChangeResult: YRangeChangeResultProtocol?, paths: [CGPath]) {
    for i in 0..<drawings.drawings.count {
      drawings.drawings[i].shapeLayer.path = paths[i]
    }
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
        opacityAnimation.keyTimes = (!animatesPositionOnHide || hiddenDrawingIndicies.count == chart.yVectors.count || (hiddenDrawingIndicies.count == chart.yVectors.count - 1 && originalHidden)) ? [0.0, 1.0] : (originalHidden ? [0.0, 0.25] : [0.75, 1.0])
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  override func addChartAnnotation(for index: Int) {
    let xPoint = drawings.xPositions[index]
    var coloredValues = [(CGFloat, UIColor)]()
    let date = chart.datesVector[index]
    
    let visibleDrawingIndexes = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    for i in visibleDrawingIndexes {
      let yVector = chart.yVectors[i]
      coloredValues.append((yVector.vector[index], yVector.metaData.color))
    }
    
    let annotationView = TGCAChartAnnotationView(frame: CGRect.zero)
    let annotationSize = annotationView.configure(date: date, coloredValues: coloredValues)
    let xPos = min(bounds.origin.x + bounds.width - annotationSize.width / 2, max(bounds.origin.x + annotationSize.width / 2, xPoint))
    annotationView.center = CGPoint(x: xPos, y: bounds.origin.y + annotationSize.height / 2)
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotationView.frame.origin.y + annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.annotationLineWidth)
    lineLayer.opacity = ChartViewConstants.axisLineOpacity
    lineLayer.zPosition = zPositions.Annotation.lineShape.rawValue
    layer.addSublayer(lineLayer)
    annotationView.layer.zPosition = zPositions.Annotation.view.rawValue
    addSubview(annotationView)
    currentChartAnnotation = ChartAnnotation(lineLayer: lineLayer, annotationView: annotationView, displayedIndex: index)

  }
  
  override func moveChartAnnotation(to index: Int, animated: Bool = false) {
    guard let annotation = currentChartAnnotation as? ChartAnnotation else {
      return
    }
    let xPoint = drawings.xPositions[index]
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = chart.datesVector[index]
    
    let visibleDrawingIndexes = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    for i in visibleDrawingIndexes {
      let yVector = chart.yVectors[i]
      coloredValues.append((yVector.vector[index], yVector.metaData.color))
    }
    
    let annotationSize = annotation.annotationView.configure(date: date, coloredValues: coloredValues)
    let xPos = min(bounds.origin.x + bounds.width - annotationSize.width / 2, max(bounds.origin.x + annotationSize.width / 2, xPoint))
    annotation.annotationView.center = CGPoint(x: xPos, y: bounds.origin.y + annotationSize.height / 2)
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotation.annotationView.frame.origin.y + annotation.annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    (currentChartAnnotation as? ChartAnnotation)?.lineLayer.path = line.cgPath
    (currentChartAnnotation as? ChartAnnotation)?.updateDisplayedIndex(to: index)
    
  }
  
  override func removeChartAnnotation() {
    if let annotation = currentChartAnnotation as? ChartAnnotation {
      annotation.lineLayer.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      currentChartAnnotation = nil
    }
  }
  
  //MARK: - Get Y vectors
  
  private var chartPercentageYVectors: [ValueVector]!
  
  private func updateChartPercentageYVectors() {
    chartPercentageYVectors = chart.percentageYVectors(excludedIndicies: hiddenDrawingIndicies)
  }
  private func getPercentageYVectors() -> [ValueVector] {
    return chartPercentageYVectors
  }
  
  // MARK: Private structs and classes
  
  private class ChartAnnotation: BaseChartAnnotation {
    let lineLayer: CAShapeLayer
    
    init(lineLayer: CAShapeLayer, annotationView: TGCAChartAnnotationView, displayedIndex: Int) {
        self.lineLayer = lineLayer
      super.init(annotationView: annotationView, displayedIndex: displayedIndex)
    }
  }
  
}
