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
  
  override func getCurrentYVectorData() -> YVectorDataProtocol {
    return YVectorData(yVectors: getPercentageYVectors().map{mapToLineLayerHeight($0)}, yRangeData: PercentageYRangeData())
  }
  
  override func updateYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResultProtocol {
    return PercentageChartYChangeResult()
  }
  
  override func getPathsToDraw(with points: [[CGPoint]]) -> [CGPath] {
    return points.map{bezierArea(topPoints: $0, bottom: chartBoundsBottom).cgPath}
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
  
  override func animateChartUpdate(withYChangeResult yChangeResult: YRangeChangeResultProtocol?, paths: [CGPath], event: DisplayRangeChangeEvent) {
    for i in 0..<drawings.shapeLayers.count {
      drawings.shapeLayers[i].path = paths[i]
    }
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
  
  // MARK: - Axes
  
  private var horizontalAxes: [PercentageHorizontalAxis]!
  
  private class PercentageHorizontalAxis {
    private(set) var lineLayer: CAShapeLayer
    private(set) var labelLayer: CATextLayer
    private(set) var value: CGFloat
    
    init(lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat) {
      self.lineLayer = lineLayer
      self.labelLayer = labelLayer
      self.value = value
    }
    
    func update(labelLayer: CATextLayer, value: CGFloat) {
      self.labelLayer = labelLayer
      self.value = value
    }
    
    func update(lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat) {
      self.lineLayer = lineLayer
      update(labelLayer: labelLayer, value: value)
    }
  }
  
  override func addHorizontalAxes() {
    
    let values: [CGFloat] = [0, 25, 50, 75, 100]
    let texts = values.map{chartLabelFormatterService.prettyValueString(from: $0)}

    let spacing = chartHeightBounds.upperBound / CGFloat(values.count-1)
    
    let positions = (0..<values.count).map{chartBoundsBottom - (CGFloat($0) * spacing)}

    
    var newAxis = [PercentageHorizontalAxis]()
    
    for i in 0..<positions.count {
      let position = positions[i]
      let line = bezierLine(from: CGPoint(x: axisLayer.frame.origin.x, y: 0), to: CGPoint(x: axisLayer.frame.origin.x + axisLayer.frame.width, y: 0))
      let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.axisLineWidth)
      lineLayer.position.y = position
      let labelLayer = textLayer(origin: CGPoint(x: axisLayer.frame.origin.x, y: position - 20), text: texts[i], color: axisYLabelColor)
      labelLayer.alignmentMode = .left
      //here i add not to axis layer because its gonna be clipped otherwise
      layer.addSublayer(lineLayer)
      layer.addSublayer(labelLayer)
      newAxis.append(PercentageHorizontalAxis(lineLayer: lineLayer, labelLayer: labelLayer, value: values[i]))
    }
    horizontalAxes = newAxis
  }
  
  override func removeHorizontalAxes() {
    horizontalAxes?.forEach{
      $0.labelLayer.removeFromSuperlayer()
      $0.lineLayer.removeFromSuperlayer()
    }
    horizontalAxes = nil
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
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: !isUnderlying, mode: isUnderlying ? .Time : .Date, showsLeftColumn: true, coloredValues: coloredValues)
  }
  
  override func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    addSubview(chartAnnotation.annotationView)
    lineLayer.addSublayer(chartAnnotation.lineLayer)
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
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      annotation.lineLayer.removeFromSuperlayer()
      CATransaction.commit()
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
  
  private struct PercentageChartYChangeResult: YRangeChangeResultProtocol {
    let didChange: Bool = false
  }
  
  //MARK: Theme
  
  override func applyColors() {
    super.applyColors()
    let theme = UIApplication.myDelegate.currentTheme
    axisXLabelColor = theme.xAxisLabelColorForFilledCharts.cgColor
    axisYLabelColor = theme.yAxisLabelColorForFilledCharts.cgColor
    axisColor = theme.axisColorForFilledCharts.cgColor
  }
  
  override func applyChanges() {
    (currentChartAnnotation as? ChartAnnotation)?.lineLayer.strokeColor = axisColor
    super.applyChanges()
    horizontalAxes?.forEach{
      $0.lineLayer.strokeColor = axisColor
      $0.labelLayer.foregroundColor = axisYLabelColor
    }
  }
  
  private class ChartAnnotation: BaseChartAnnotation {
    let lineLayer: CAShapeLayer
    
    init(lineLayer: CAShapeLayer, annotationView: TGCAChartAnnotationView, displayedIndex: Int) {
        self.lineLayer = lineLayer
      super.init(annotationView: annotationView, displayedIndex: displayedIndex)
    }
  }
  
}
