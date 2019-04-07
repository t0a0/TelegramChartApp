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
  
  override func configure(with chart: LinearChart, hiddenIndicies: Set<Int>, displayRange: ClosedRange<CGFloat>? = nil) {
    super.configure(with: chart, hiddenIndicies: hiddenIndicies, displayRange: displayRange)
    leftAxisLabelColor = chart.yVectors.first?.metaData.color.cgColor
    rightAxisLabelColor = chart.yVectors.last?.metaData.color.cgColor
  }
  
  private func getSeparatelyNormalizedYVectors() -> SeparatlyNormalizedYVectors{
    return chart.separatlyNormalizedYVectorsFromLocalMinimum(in: currentXIndexRange)
  }
  
  override func drawChart() {
    let normalizedYVectors = getSeparatelyNormalizedYVectors()
    let yVectors = normalizedYVectors.map{mapToChartBoundsHeight($0.vector)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    
    leftYValueRange = normalizedYVectors.first!.yRange
    rightYValueRange = normalizedYVectors.last!.yRange
    
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
      lineLayer.opacity = 0.75
      
      let leftTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: leftTexts[i], color: leftAxisLabelColor)
      let rightTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: rightTexts[i], color: rightAxisLabelColor)
      rightTextLayer.frame.origin.x = boundsRight - rightTextLayer.frame.width
      rightTextLayer.alignmentMode = .right
      axisLayer.addSublayer(lineLayer)
      axisLayer.addSublayer(leftTextLayer)
      axisLayer.addSublayer(rightTextLayer)
      newAxis.append(HorizontalAxis(lineLayer: lineLayer, leftTextLayer: leftTextLayer, rightTextLayer: rightTextLayer))
    }
    horizontalAxes = newAxis
  }
  
  override func animateHorizontalAxesChange(fromPreviousRange previousRange: ClosedRange<CGFloat>, toNewRange newRange: ClosedRange<CGFloat>) {
    
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
  }
  
}
