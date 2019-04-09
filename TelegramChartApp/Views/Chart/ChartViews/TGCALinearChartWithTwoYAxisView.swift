//
//  TGCALinearChartWithTwoYAxisView.swift
//  TelegramChartApp
//
//  Created by Igor on 07/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit


class TGCALinearChartWithTwoYAxisView: TGCAChartView {
  
  private var leftYValueRange: ClosedRange<CGFloat> = 0...0
  private var rightYValueRange: ClosedRange<CGFloat> = 0...0
  
  func updateCurrentYValueRanges(left: ClosedRange<CGFloat>, right: ClosedRange<CGFloat>) {
    let leftChanged = leftYValueRange != left
    let rightChanged = rightYValueRange != right
    if !leftChanged && !rightChanged {
      return
    }
    leftYValueRange = left
    rightYValueRange = right
    if horizontalAxes != nil {
      var animBlocks = [()->()]()
      var removalBlocks = [()->()]()
      if leftChanged {
        let blocks = updateLeftHorizontalAxes()
        animBlocks.append(contentsOf: blocks.animationBlocks)
        removalBlocks.append(contentsOf: blocks.removalBlocks)
      }
      if rightChanged {
        let blocks = updateRightHorizontalAxes()
        animBlocks.append(contentsOf: blocks.animationBlocks)
        removalBlocks.append(contentsOf: blocks.removalBlocks)
      }
      DispatchQueue.main.async {
        CATransaction.flush()
        CATransaction.begin()
        CATransaction.setAnimationDuration(AXIS_ANIMATION_DURATION)
        CATransaction.setCompletionBlock{
          for r in removalBlocks {
            r()
          }
        }
        for ab in animBlocks {
          ab()
        }
        CATransaction.commit()
      }
    }
  }
  
  override func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: ClosedRange<CGFloat>? = nil) {
    super.configure(with: chart, hiddenIndicies: hiddenIndicies, displayRange: displayRange)
    leftAxisLabelColor = chart.yVectors.first?.metaData.color.cgColor
    rightAxisLabelColor = chart.yVectors.last?.metaData.color.cgColor
  }
  
  override func drawChart() {
    let normalizedYVectors = getSeparatelyNormalizedYVectors()
    let yVectors = normalizedYVectors.map{mapToChartBoundsHeight($0.vector)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    updateCurrentYValueRanges(left: normalizedYVectors.first!.yRange, right: normalizedYVectors.last!.yRange)
    
    var draws = [Drawing]()
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let line = bezierLine(withPoints: points)
      let shape = shapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
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
    let normalizedYVectors = getSeparatelyNormalizedYVectors()
    let yVectors = normalizedYVectors.map{mapToChartBoundsHeight($0.vector)}

    let leftChanged = leftYValueRange != normalizedYVectors.first!.yRange
    let rightChanged = rightYValueRange != normalizedYVectors.last!.yRange
    updateCurrentYValueRanges(left: normalizedYVectors.first!.yRange, right: normalizedYVectors.last!.yRange)
    
    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      drawing.yPositions = yVector
      let newPath = bezierLine(withPoints: points)
      
      if let oldAnim = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.presentation()?.value(forKey: "path") ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        if (i == 0 && !leftChanged) || (i == 1 && !rightChanged){
          pathAnimation.beginTime = oldAnim.beginTime
        } else {
          pathAnimation.beginTime = CACurrentMediaTime()
        }
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      } else {
        if (i == 0 && leftChanged) || (i == 1 && rightChanged) {
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
    let normalizedYVectors = getSeparatelyNormalizedYVectors()
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let yVectors = normalizedYVectors.map{mapToChartBoundsHeight($0.vector)}

    updateCurrentYValueRanges(left: normalizedYVectors.first!.yRange, right: normalizedYVectors.last!.yRange)
    
    for i in 0..<drawings.drawings.count {
      let yVector = yVectors[i]
      let drawing = drawings.drawings[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let newPath = bezierLine(withPoints: points)
      
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
    drawings.xPositions = xVector
  }
  
  //MARK: - Axes
  
  private var leftAxisLabelColor: CGColor! = UIColor.black.cgColor
  private var rightAxisLabelColor: CGColor! = UIColor.black.cgColor
  
  private var horizontalAxes: [HorizontalAxis]!
  
  private func valuesForLeftAxis() -> [CGFloat] {
    let distanceInYRange = leftYValueRange.upperBound - leftYValueRange.lowerBound
    let distanceInBounds = capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes-1)
    var retVal = [leftYValueRange.lowerBound]
    for i in 1..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i)) + leftYValueRange.lowerBound)
    }
    return retVal
  }
  
  private func valuesForRightAxis() -> [CGFloat] {
    let distanceInYRange = rightYValueRange.upperBound - rightYValueRange.lowerBound
    let distanceInBounds = capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes-1)
    var retVal = [rightYValueRange.lowerBound]
    for i in 1..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i)) + rightYValueRange.lowerBound)
    }
    return retVal
  }
  
  override func addHorizontalAxes() {
    
    let boundsRight = bounds.origin.x + bounds.width
    
    let leftValues = valuesForLeftAxis()
    let rightValues = valuesForRightAxis()
    let leftTexts = leftValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    let rightTexts = rightValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    var newAxis = [HorizontalAxis]()

    for i in 0..<horizontalAxesDefaultYPositions.count {
      let position = horizontalAxesDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: 0), to: CGPoint(x: boundsRight, y: 0))
      let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.axisLineWidth)
      lineLayer.position.y = position
      lineLayer.opacity = ChartViewConstants.axisLineOpacity
      
      let leftTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: leftTexts[i], color: leftAxisLabelColor)
      let rightTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: rightTexts[i], color: rightAxisLabelColor)
      leftTextLayer.alignmentMode = .left
      rightTextLayer.frame.origin.x = boundsRight - rightTextLayer.frame.width
      rightTextLayer.alignmentMode = .right
      axisLayer.addSublayer(lineLayer)
      axisLayer.addSublayer(leftTextLayer)
      axisLayer.addSublayer(rightTextLayer)
      newAxis.append(HorizontalAxis(lineLayer: lineLayer, leftTextLayer: leftTextLayer, rightTextLayer: rightTextLayer, leftValue: leftValues[i], rightValue: rightValues[i]))
    }
    horizontalAxes = newAxis
  }
  
  private func updateLeftHorizontalAxes() -> AxisAnimationBlocks {
    
    let leftValues = valuesForLeftAxis()
    let leftTexts = leftValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    //diffs between new values and old values
    let diffs: [CGFloat] = zip(leftValues, horizontalAxes.map{$0.leftValue}).map{ arg in
      let (new, old) = arg
      let result = new - old
      if result > 0 {
        return horizontalAxesSpacing
      } else if result < 0 {
        return -horizontalAxesSpacing
      }
      return 0
    }
    
    var blocks = [()->()]()
    var removalBlocks = [()->()]()

    for i in 0..<horizontalAxes.count {
      let ax = horizontalAxes[i]

      if diffs[i] == 0 {
        continue
      }
      
      let position = horizontalAxesDefaultYPositions[i]
      
      let oldTextLayerTargetPosition = CGPoint(x: ax.leftTextLayer.position.x, y: ax.leftTextLayer.position.y + diffs[i])
      
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: leftTexts[i], color: leftAxisLabelColor)
      newTextLayer.opacity = 0
      axisLayer.addSublayer(newTextLayer)
      let newTextLayerTargetPosition = newTextLayer.position
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: newTextLayer.position.y - diffs[i])
      
      let oldTextLayer = ax.leftTextLayer
      
      ax.update(leftTextLayer: newTextLayer, leftValue: leftValues[i])
      
      blocks.append {
        oldTextLayer.position = oldTextLayerTargetPosition
        oldTextLayer.opacity = 0
        
        newTextLayer.position = newTextLayerTargetPosition
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        oldTextLayer.removeFromSuperlayer()
      }
    }
    
    return (blocks, removalBlocks)
  }
  
  private func updateRightHorizontalAxes() -> AxisAnimationBlocks {
    let boundsRight = bounds.origin.x + bounds.width

    let rightValues = valuesForRightAxis()
    let rightTexts = rightValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    //diffs between new values and old values
    let diffs: [CGFloat] = zip(rightValues, horizontalAxes.map{$0.rightValue}).map{ arg in
      let (new, old) = arg
      let result = new - old
      if result > 0 {
        return horizontalAxesSpacing
      } else if result < 0 {
        return -horizontalAxesSpacing
      }
      return 0
    }
    
    var blocks = [()->()]()
    var removalBlocks = [()->()]()
    
    for i in 0..<horizontalAxes.count {
      let ax = horizontalAxes[i]
      
      if diffs[i] == 0 {
        continue
      }
      
      let position = horizontalAxesDefaultYPositions[i]
      
      let oldTextLayerTargetPosition = CGPoint(x: ax.rightTextLayer.position.x, y: ax.rightTextLayer.position.y + diffs[i])
      
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: rightTexts[i], color: rightAxisLabelColor)
      newTextLayer.frame.origin.x = boundsRight - newTextLayer.frame.width
      newTextLayer.alignmentMode = .right
      newTextLayer.opacity = 0
      axisLayer.addSublayer(newTextLayer)
      let newTextLayerTargetPosition = newTextLayer.position
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: newTextLayer.position.y - diffs[i])
      
      let oldTextLayer = ax.rightTextLayer
      
      ax.update(rightTextLayer: newTextLayer, rightValue: rightValues[i])
      
      blocks.append {
        oldTextLayer.position = oldTextLayerTargetPosition
        oldTextLayer.opacity = 0
        
        newTextLayer.position = newTextLayerTargetPosition
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        oldTextLayer.removeFromSuperlayer()
      }
    }
    
    return (blocks, removalBlocks)
  }
  
  private func hideLeftAxisLabels() {
    
  }
  
  private func hideRightAxisLabels() {
    
  }
  
  private func showLeftAxisLabels() {
    
  }
  
  private func showRightAxisLabels() {
    DispatchQueue.main.async { [weak self] in
      CATransaction.flush()
      CATransaction.begin()
      CATransaction.setAnimationDuration(AXIS_ANIMATION_DURATION)
      self?.horizontalAxes?.forEach{
        $0.lineLayer.opacity = ChartViewConstants.axisLineOpacity
        $0.leftTextLayer.opacity = 1
        $0.rightTextLayer.opacity = 1
      }
      CATransaction.commit()
    }
  }
  
  private func hideHorizontalAxis() {
    DispatchQueue.main.async { [weak self] in
      CATransaction.flush()
      CATransaction.begin()
      CATransaction.setAnimationDuration(AXIS_ANIMATION_DURATION)
//      CATransaction.setCompletionBlock{
//        horizontalAxes?.forEach{
//          $0.lineLayer.removeFromSuperlayer()
//          $0.leftTextLayer.removeFromSuperlayer()
//          $0.rightTextLayer.removeFromSuperlayer()
//        }
//      }
      self?.horizontalAxes?.forEach{
        $0.lineLayer.opacity = 0
        $0.leftTextLayer.opacity = 0
        $0.rightTextLayer.opacity = 0
      }
      CATransaction.commit()
    }
  }
  
  private func showHorizontalAxis() {
    
  }
  
  override func removeAxes() {
    axisLayer.sublayers?.forEach{
      $0.removeFromSuperlayer()
    }
    horizontalAxes = nil
  }
  
  private class HorizontalAxis {
    let lineLayer: CAShapeLayer
    private(set) var leftTextLayer: CATextLayer
    private(set) var rightTextLayer: CATextLayer
    private(set) var leftValue: CGFloat
    private(set) var rightValue: CGFloat
    
    init(lineLayer: CAShapeLayer, leftTextLayer: CATextLayer, rightTextLayer: CATextLayer, leftValue: CGFloat, rightValue: CGFloat) {
      self.lineLayer = lineLayer
      self.leftTextLayer = leftTextLayer
      self.rightTextLayer = rightTextLayer
      self.leftValue = leftValue
      self.rightValue = rightValue
    }
    
    func update(leftTextLayer: CATextLayer, leftValue: CGFloat) {
      self.leftTextLayer = leftTextLayer
      self.leftValue = leftValue
    }
    
    func update(rightTextLayer: CATextLayer, rightValue: CGFloat) {
      self.rightTextLayer = rightTextLayer
      self.rightValue = rightValue
    }
  }
  
  //MARK: - Helper Methods
  
  private func getSeparatelyNormalizedYVectors() -> SeparatlyNormalizedYVectors{
    return chart.separatlyNormalizedYVectorsFromLocalMinimum(in: currentXIndexRange)
  }
  
}
