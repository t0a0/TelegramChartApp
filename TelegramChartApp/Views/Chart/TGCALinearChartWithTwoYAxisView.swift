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
      if !animBlocks.isEmpty || !removalBlocks.isEmpty {
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
  }
  
  override func configure(with chart: LinearChart, hiddenIndicies: Set<Int>, displayRange: ClosedRange<CGFloat>? = nil) {
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
    
    var newDrawings = [Drawing]()
    for i in 0..<drawings.drawings.count {
      
      let drawing = drawings.drawings[i]
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      newDrawings.append(Drawing(shapeLayer: drawing.shapeLayer, yPositions: yVector))
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
    self.drawings = ChartDrawings(drawings: newDrawings, xPositions: xVector)
  }
  
  //MARK: - Axes
  
  private var leftAxisLabelColor: CGColor! = UIColor.black.cgColor
  private var rightAxisLabelColor: CGColor! = UIColor.black.cgColor
  
  private var horizontalAxes: [HorizontalAxis]!
  
  private func valuesForLeftAxis() -> [CGFloat] {
    let distanceInYRange = leftYValueRange.upperBound - leftYValueRange.lowerBound
    let distanceInBounds = capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes)
    var retVal = [CGFloat]()
    for i in 0..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i+1)) + leftYValueRange.lowerBound)
    }
    return retVal
  }
  
  private func valuesForRightAxis() -> [CGFloat] {
    let distanceInYRange = rightYValueRange.upperBound - rightYValueRange.lowerBound
    let distanceInBounds = capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes)
    var retVal = [CGFloat]()
    for i in 0..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i+1)) + rightYValueRange.lowerBound)
    }
    return retVal
  }
  
  override func addHorizontalAxes() {
    
    let boundsRight = bounds.origin.x + bounds.width
    
    var newAxis = [HorizontalAxis]()
    
    let leftValues = valuesForLeftAxis()
    let rightValues = valuesForRightAxis()
    let leftTexts = leftValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    let rightTexts = rightValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    for i in 0..<horizontalAxesDefaultYPositions.count {
      let position = horizontalAxesDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: position), to: CGPoint(x: boundsRight, y: position))
      let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      lineLayer.opacity = ChartViewConstants.axisLineOpacity
      
      let leftTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: leftTexts[i], color: leftAxisLabelColor)
      let rightTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: rightTexts[i], color: rightAxisLabelColor)
      rightTextLayer.frame.origin.x = boundsRight - rightTextLayer.frame.width
      rightTextLayer.alignmentMode = .right
      axisLayer.addSublayer(lineLayer)
      axisLayer.addSublayer(leftTextLayer)
      axisLayer.addSublayer(rightTextLayer)
      newAxis.append(HorizontalAxis(lineLayer: lineLayer, leftTextLayer: leftTextLayer, rightTextLayer: rightTextLayer, leftValue: leftValues[i], rightValue: rightValues[i]))
    }
    horizontalAxes = newAxis
  }
  
  typealias AxisAnimationBlocks = (animationBlocks: [()->()], removalBlocks: [()->()])
  
  private func updateLeftHorizontalAxes() -> AxisAnimationBlocks {
    
    let leftValues = valuesForLeftAxis()
    let leftTexts = leftValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    let coefficients = (0..<leftValues.count).map{
      leftValues[$0] / horizontalAxes[$0].leftValue
    }
    var blocks = [()->()]()
    var removalBlocks = [()->()]()
    var newAxes = [HorizontalAxis]()

    for i in 0..<horizontalAxes.count {
      let ax = horizontalAxes[i]
      let coefficient = coefficients[i]
      let coefIsZero = coefficient == 0
      let coefIsInf = coefficient == CGFloat.infinity
      let position = horizontalAxesDefaultYPositions[i]
      
      let oldTextLayerTargetPosition = CGPoint(x: ax.leftTextLayer.position.x, y: coefIsZero ? chartBoundsBottom : (coefficient > 1 ? ax.leftTextLayer.position.y * coefficient : ax.leftTextLayer.position.y - ax.leftTextLayer.position.y * coefficient))
      
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: leftTexts[i], color: leftAxisLabelColor)
      newTextLayer.opacity = 0
      axisLayer.addSublayer(newTextLayer)
      let newTextLayerTargetPosition = newTextLayer.position
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: coefIsInf ? chartBounds.origin.y :  (coefficient > 1 ? newTextLayer.position.y / coefficient : newTextLayer.position.y * coefficient))
      newAxes.append(HorizontalAxis(lineLayer: ax.lineLayer, leftTextLayer: newTextLayer, rightTextLayer: ax.rightTextLayer, leftValue: leftValues[i], rightValue: ax.rightValue))
      
      blocks.append {
        ax.leftTextLayer.position = oldTextLayerTargetPosition
        ax.leftTextLayer.opacity = 0
        
        newTextLayer.position = newTextLayerTargetPosition
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        ax.leftTextLayer.removeFromSuperlayer()
      }
    }
    
    self.horizontalAxes = newAxes
    return (blocks, removalBlocks)
  }
  
  private func updateRightHorizontalAxes() -> AxisAnimationBlocks {
    let boundsRight = bounds.origin.x + bounds.width

    let rightValues = valuesForRightAxis()
    let rightTexts = rightValues.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    let coefficients = (0..<rightValues.count).map{
      rightValues[$0] / horizontalAxes[$0].rightValue
    }
    var blocks = [()->()]()
    var removalBlocks = [()->()]()
    var newAxes = [HorizontalAxis]()
    
    for i in 0..<horizontalAxes.count {
      let ax = horizontalAxes[i]
      let coefficient = coefficients[i]
      let coefIsZero = coefficient == 0
      let coefIsInf = coefficient == CGFloat.infinity
      let position = horizontalAxesDefaultYPositions[i]
      
      let oldTextLayerTargetPosition = CGPoint(x: ax.rightTextLayer.position.x, y: coefIsZero ? chartBoundsBottom : (coefficient > 1 ? ax.rightTextLayer.position.y * coefficient : ax.rightTextLayer.position.y - ax.rightTextLayer.position.y * coefficient))
      
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: rightTexts[i], color: rightAxisLabelColor)
      newTextLayer.frame.origin.x = boundsRight - newTextLayer.frame.width
      newTextLayer.alignmentMode = .right
      newTextLayer.opacity = 0
      axisLayer.addSublayer(newTextLayer)
      let newTextLayerTargetPosition = newTextLayer.position
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: coefIsInf ? chartBounds.origin.y :  (coefficient > 1 ? newTextLayer.position.y / coefficient : newTextLayer.position.y * coefficient))
      newAxes.append(HorizontalAxis(lineLayer: ax.lineLayer, leftTextLayer: ax.leftTextLayer, rightTextLayer: newTextLayer, leftValue: ax.leftValue, rightValue: rightValues[i]))
      
      blocks.append {
        ax.rightTextLayer.position = oldTextLayerTargetPosition
        ax.rightTextLayer.opacity = 0
        
        newTextLayer.position = newTextLayerTargetPosition
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        ax.rightTextLayer.removeFromSuperlayer()
      }
    }
    
    self.horizontalAxes = newAxes
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
  
  private struct HorizontalAxis {
    let lineLayer: CAShapeLayer
    let leftTextLayer: CATextLayer
    let rightTextLayer: CATextLayer
    let leftValue: CGFloat
    let rightValue: CGFloat
  }
  
  //MARK: - Helper Methods
  
  private func getSeparatelyNormalizedYVectors() -> SeparatlyNormalizedYVectors{
    return chart.separatlyNormalizedYVectorsFromLocalMinimum(in: currentXIndexRange)
  }
  
}
