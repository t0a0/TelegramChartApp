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
  
  // MARK: - Annotation
  
  override func getChartAnnotationViewConfiguration(for index: Int) -> TGCAChartAnnotationView.AnnotationViewConfiguration {
    let includedIndicies = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    let percentages = chart.percentages(at: index, includedIndicies: includedIndicies).map{"\($0)%"}
    var coloredValues = [TGCAChartAnnotationView.ColoredValue]()
    for i in 0..<includedIndicies.count {
      let idx = includedIndicies[i]
      let yVector = chart.yVectors[idx]
      coloredValues.append(TGCAChartAnnotationView.ColoredValue(title: yVector.metaData.name, value: yVector.vector[index], color: yVector.metaData.color, prefix: percentages[i]))
    }
    coloredValues.sort { (left, right) -> Bool in
      return left.value >= right.value
    }
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: true, mode: .Date, showsLeftColumn: true, coloredValues: coloredValues)
  }
  
  override func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    addSubview(chartAnnotation.annotationView)
    layer.addSublayer(chartAnnotation.lineLayer)
  }
  
  override func generateChartAnnotation(for index: Int, with annotationView: TGCAChartAnnotationView) -> ChartAnnotationProtocol {
    let xPoint = drawings.xPositions[index]
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotationView.frame.origin.y + annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.annotationLineWidth)
    
    lineLayer.zPosition = zPositions.Annotation.lineShape.rawValue
    annotationView.layer.zPosition = zPositions.Annotation.view.rawValue
    
    return ChartAnnotation(lineLayer: lineLayer, annotationView: annotationView, displayedIndex: index)
  }
  
  override func performUpdatesForMovingChartAnnotation(to index: Int, with chartAnnotation: ChartAnnotationProtocol, animated: Bool) {
    guard let annotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    let xPoint = drawings.xPositions[index]
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotation.annotationView.frame.origin.y + annotation.annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    
    annotation.lineLayer.path = line.cgPath
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
  
  // MARK: COnfiguration
  
  override func configureChartBounds() {
    chartBounds = CGRect(x: bounds.origin.x,
                         y: bounds.origin.y,
                         width: bounds.width,
                         height: bounds.height
                          - (shouldDisplayAxesAndLabels ? ChartViewConstants.sizeForGuideLabels.height : 0))
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
