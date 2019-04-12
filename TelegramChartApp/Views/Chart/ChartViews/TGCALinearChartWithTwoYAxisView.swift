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
  
  private func updateCurrentYValueRanges(with yRangeData: YRangeDataProtocol) -> DoubleAxisYRangeChageResult {
    guard let yRangeData = (yRangeData as? DoubleAxisYRangeData) else {
      return DoubleAxisYRangeChageResult(leftChanged: false, rightChanged: false)
    }
    
    let leftChanged = yRangeData.leftYRange != leftYValueRange
    let rightChanged = yRangeData.rightYRange != rightYValueRange
    if !leftChanged && !rightChanged {
      return DoubleAxisYRangeChageResult(leftChanged: false, rightChanged: false)
    }
    
    leftYValueRange = yRangeData.leftYRange
    rightYValueRange = yRangeData.rightYRange
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
    return DoubleAxisYRangeChageResult(leftChanged: leftChanged, rightChanged: rightChanged)
  }
  
  override func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: ClosedRange<CGFloat>? = nil) {
    super.configure(with: chart, hiddenIndicies: hiddenIndicies, displayRange: displayRange)
    leftAxisLabelColor = chart.yVectors.first?.metaData.color.cgColor
    rightAxisLabelColor = chart.yVectors.last?.metaData.color.cgColor
  }
  
  override func getCurrentYVectorData() -> YVectorDataProtocol {
    let normalizedYVectors = getSeparatelyNormalizedYVectors()
    let yVectors = normalizedYVectors.map{mapToChartBoundsHeight($0.vector)}

    return YVectorData(yVectors: yVectors, yRangeData: DoubleAxisYRangeData(leftYRange: normalizedYVectors.first!.yRange, rightYRange: normalizedYVectors.last!.yRange))
  }

  override func updateYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResultProtocol {
    return updateCurrentYValueRanges(with: yRangeData)
  }
  
  //MARK: - Axes
  
  private var leftAxisLabelColor: CGColor! = UIColor.black.cgColor
  private var rightAxisLabelColor: CGColor! = UIColor.black.cgColor
  
  private var horizontalAxes: [HorizontalAxis]!
  
  private func valuesForLeftAxis() -> [CGFloat] {
    let distanceInYRange = leftYValueRange.upperBound - leftYValueRange.lowerBound
    let distanceInBounds = ChartViewConstants.capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes-1)
    var retVal = [leftYValueRange.lowerBound]
    for i in 1..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i)) + leftYValueRange.lowerBound)
    }
    return retVal
  }
  
  private func valuesForRightAxis() -> [CGFloat] {
    let distanceInYRange = rightYValueRange.upperBound - rightYValueRange.lowerBound
    let distanceInBounds = ChartViewConstants.capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes-1)
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
        $0.lineLayer.opacity = 1
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
  
  override func removeHorizontalAxes() {
    axisLayer.sublayers?.forEach{
      $0.removeFromSuperlayer()
    }
    horizontalAxes = nil
  }
  
  //MARK: - Private classes and structs
  
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
  
  private struct DoubleAxisYRangeData: YRangeDataProtocol {
    let leftYRange: ClosedRange<CGFloat>
    let rightYRange: ClosedRange<CGFloat>
  }
  
  private struct DoubleAxisYRangeChageResult: YRangeChangeResultProtocol {
    let leftChanged: Bool
    let rightChanged: Bool
    
    var didChange: Bool {
      return leftChanged || rightChanged
    }
  }
  
  //MARK: - Helper Methods
  
  private func getSeparatelyNormalizedYVectors() -> SeparatlyNormalizedYVectors{
    return chart.separatlyNormalizedYVectorsFromLocalMinimum(in: currentXIndexRange)
  }
  
}
