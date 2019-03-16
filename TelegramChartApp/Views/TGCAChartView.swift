//
//  TGCAChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit
import QuartzCore

protocol TGCAChartViewDelegate: class {
  
  func chartView(_ chartView: TGCAChartView, requestsChartLabelDataForPoint point: CGPoint) -> TGCAChartAnnotation
  
}

class TGCAChartView: UIView {
  @IBOutlet var contentView: UIView!
  //MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit () {
    Bundle.main.loadNibNamed("TGCAChartView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    layer.masksToBounds = true
    isMultipleTouchEnabled = false
  }
  
  override var bounds: CGRect {
    didSet {
      chartBounds = CGRect(x: bounds.origin.x + graphLineWidth,
                           y: bounds.origin.y + graphLineWidth,
                           width: bounds.width - graphLineWidth * 2,
                           height: bounds.height - graphLineWidth * 2)
    }
  }
  
  var graphLineWidth: CGFloat = 2.0
  var shouldDisplaySupportAxis = false
  
  private let numOfSupportAxis = 5
  private var supportAxisCapHeight: CGFloat {
    return bounds.height * 0.95
  }
  
  
  private var chartBounds: CGRect = CGRect.zero {
    didSet {
      let chart = self.chart
      self.chart = chart
    }
  }

  private struct Drawing {
    let identifier: String
    let line: UIBezierPath
    let shapeLayer: CAShapeLayer
    private(set) var points: [CGPoint]
    
    mutating func update(withPoints points: [CGPoint]) {
      self.points = points
    }
  }
  weak var delegate: TGCAChartViewDelegate?

  
  var lastYRange: ClosedRange<CGFloat> = 0...0 {
    didSet {
    }
  }
  
  /// From 0 to 1.0.
  var displayRange: ClosedRange<CGFloat> = ZORange {
    didSet {
      guard var drawings = drawings, let chart = chart else {
        return
      }

      var excluded = [Int]()
      for i in 0..<hiddens.count {
        if hiddens[i] {excluded.append(i)}
      }
      let normalizedYVectors = chart.oddlyNormalizedYVectors(in: displayRange, excludedIdxs: excluded)
      let normalizedXVector = chart.normalizedXVector(in: displayRange)
      
      let newYrange = normalizedYVectors.resltingYRange
      if lastYRange != newYrange {
        if shouldDisplaySupportAxis {
          animateSupportAxisChange(fromMaxValue: lastYRange.upperBound, toMaxValue: newYrange.upperBound)
        }
        lastYRange = newYrange
      }
      
      for i in 0..<drawings.count {
        var drawing = drawings[i]
        
        
        let yVector = normalizedYVectors.resultingVectors[i].map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}
        let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
        
        func point(for j: Int) -> CGPoint {
          return CGPoint(x: xVector[j], y: yVector[j])
        }
        var points = [CGPoint]()
        for k in 0..<xVector.count {
          points.append(point(for: k))
        }
        drawing.update(withPoints: points)
        
        let newPath = bezierLine(xVector: xVector, yVector: yVector)
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = 0.25
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
        self.drawings![i] = drawing
    }
    }
  }
  
  private var yValueRange: ClosedRange<CGFloat> = 0...0
  private var hiddens: [Bool]!
  
  private var chart: LinearChart! {
    didSet {
      let yVectors = chart.nyVectorGroup.vectors.map{$0.map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}}
      let xVector = chart.xVector.nVector.vector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
      var draws = [Drawing]()
      
      for i in 0..<yVectors.count {
        let yVector = yVectors[i]
        
        
        func point(for j: Int) -> CGPoint {
          return CGPoint(x: xVector[j], y: yVector[j])
        }
        var points = [CGPoint]()
        for k in 0..<xVector.count {
          points.append(point(for: k))
        }
        
        
        let line = bezierLine(xVector: xVector, yVector: yVector)
        let sp = shapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
        layer.addSublayer(sp)
        draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, line: line, shapeLayer: sp, points: points))
      }
      self.drawings = draws
      self.hiddens = Array(repeating: false, count: chart.yVectors.count)
    }
  }
  private var drawings: [Drawing]!

  func hide(at index: Int) {
    let originalHidden = hiddens[index]
    hiddens[index].toggle()
    var excluded = [Int]()
    for i in 0..<hiddens.count {
      if hiddens[i] {excluded.append(i)}
    }
    let normalizedYVectors = chart.oddlyNormalizedYVectors(in: displayRange, excludedIdxs: excluded)
    let normalizedXVector = chart.normalizedXVector(in: displayRange)
    for i in 0..<drawings.count {
      let drawing = drawings[i]
      let yVector = normalizedYVectors.resultingVectors[i].map{chartBounds.size.height + chartBounds.origin.y - ($0 * chartBounds.size.height)}
      let newPath = bezierLine(xVector: normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}, yVector: yVector)
      let pathAnimation = CABasicAnimation(keyPath: "path")
      pathAnimation.fromValue = drawing.shapeLayer.path
      drawing.shapeLayer.path = newPath.cgPath
      pathAnimation.toValue = drawing.shapeLayer.path
      pathAnimation.duration = 0.25
      pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
      drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      
      if i == index {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = drawing.shapeLayer.opacity
        drawing.shapeLayer.opacity = originalHidden ? 1 : 0
        opacityAnimation.toValue = drawing.shapeLayer.opacity
        opacityAnimation.duration = 0.25
        // TODO: LOOK INTO FADING TIME
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)

        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  
  func configure(with chart: LinearChart) {
    self.chart = chart
    
    if(shouldDisplaySupportAxis) {
      self.addXAxisLayers()
    }
  }
  
  
  
  typealias SupportAxis = (lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat)
  
  var supportAxis: [SupportAxis]!
  
  private var supportAxisDefaultYPositions: [CGFloat] {
    let space = supportAxisCapHeight / CGFloat(numOfSupportAxis)
    var retVal = [CGFloat]()
    for i in 0..<numOfSupportAxis {
      retVal.append(bounds.height - (CGFloat(i) * space + space))
    }
    return retVal
  }
  
  func addXAxisLayers() {
    var layers = [SupportAxis]()
    
    for i in supportAxisDefaultYPositions {
      let line = UIBezierPath()
      line.move(to: CGPoint(x: bounds.origin.x, y: i))
      line.addLine(to: CGPoint(x: bounds.size.width, y: i))
      let shapeLater = shapeLayer(withPath: line.cgPath, color: UIColor.lightGray.withAlphaComponent(0.75).cgColor, lineWidth: 0.5)
      let textLayerr = textLayer(position: CGPoint(x: bounds.origin.x, y: i - 10), text: "\(i)")
      layer.addSublayer(shapeLater)
      layer.addSublayer(textLayerr)
      layers.append((shapeLater, textLayerr, i))
    }
    self.supportAxis = layers
  }
  
  func animateSupportAxisChange(fromMaxValue: CGFloat, toMaxValue: CGFloat) {
    let coefficient = fromMaxValue/toMaxValue
    for (lineLayer, labelLayer, _) in supportAxis {
      let newLinePosition = CGPoint(x: lineLayer.position.x, y: lineLayer.position.y - supportAxisCapHeight * coefficient)
      let newTextPosition = CGPoint(x: labelLayer.position.x, y: labelLayer.position.y - supportAxisCapHeight * coefficient)
      
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
      CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
      CATransaction.setCompletionBlock{
        lineLayer.removeFromSuperlayer()
        labelLayer.removeFromSuperlayer()
      }
      labelLayer.position = newTextPosition
      lineLayer.position = newLinePosition
      CATransaction.commit()
      CATransaction.flush()
      
    }
    
    addXAxisLayers()
    
    for (lineLayer, labelLayer, _) in supportAxis {
      let oL = lineLayer.position
      let oT = labelLayer.position
      let newLinePosition = CGPoint(x: lineLayer.position.x, y: lineLayer.position.y + supportAxisCapHeight * coefficient)
      let newTextPosition = CGPoint(x: labelLayer.position.x, y: labelLayer.position.y + supportAxisCapHeight * coefficient)
      print(oT)
      print(newTextPosition)
      labelLayer.position = newTextPosition
      lineLayer.position = newLinePosition
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
      CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
//      CATransaction.setCompletionBlock{
//        lineLayer.removeFromSuperlayer()
//        labelLayer.removeFromSuperlayer()
//      }
      labelLayer.position = oT
      lineLayer.position = oL
      CATransaction.commit()
      CATransaction.flush()

      
    }
    
  }
  
  func bezierLine(xVector: ValueVector, yVector: ValueVector) -> UIBezierPath {
    let line = UIBezierPath()
    
    func point(for i: Int) -> CGPoint {
      return CGPoint(x: xVector[i], y: yVector[i])
    }
    
    let firstPoint = point(for: 0)
    line.move(to: firstPoint)
    
    for i in 1..<xVector.count {
      line.addLine(to: point(for: i))
    }
    return line
  }
  
  func bezierLine(from fromPoint: CGPoint, to toPoint: CGPoint) -> UIBezierPath {
    let line = UIBezierPath()
    line.move(to: fromPoint)
    line.addLine(to: toPoint)
    return line
  }
  
  func bezierCircle(at point: CGPoint) -> UIBezierPath {
    let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
    return UIBezierPath(ovalIn: rect)
  }
  
  func shapeLayer(withPath path: CGPath, color: CGColor, lineWidth: CGFloat = 2, fillColor: CGColor? = nil) -> CAShapeLayer{
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path
    shapeLayer.strokeColor = color
    shapeLayer.lineWidth = lineWidth
    shapeLayer.lineJoin = .round
    shapeLayer.lineCap = .round
    shapeLayer.fillColor = fillColor
    return shapeLayer
  }
  
  func textLayer(position: CGPoint, text: String) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = "Helvetica" as CFTypeRef
    textLayer.fontSize = 10.0
    textLayer.string = text
    textLayer.frame = CGRect(origin: position, size: CGSize(width: 100, height: 20))
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.foregroundColor = UIColor.blue.cgColor
    return textLayer
  }
  
  // MARK: - Touches
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard
      let touchLocation = touches.first?.location(in: self),
      chartBounds.contains(touchLocation)
      else {
        return
    }
    
    //TODO: Something wrong with calculation, on the right part of the screen index is + 1 from the touched one
    
    func closestIndex(for touchLocation: CGPoint) -> Int {
      let xPositionInChartBounds = touchLocation.x - chartBounds.origin.x
      let translatedToDisplayRange = (displayRange.upperBound - displayRange.lowerBound) * (xPositionInChartBounds / chartBounds.width) + displayRange.lowerBound
      let index = round(CGFloat(chart.xVector.vector.count - 1) * translatedToDisplayRange)
      print(index)
      return Int(index)
    }
    
//    func xLocationInChartBounds(of index: Int) -> CGFloat {
//      let displayRangeLocation = (CGFloat(index) / CGFloat(chart.xVector.vector.count - 1))
//      let currentDisplayRangeLocation = (displayRangeLocation - displayRange.lowerBound)/(displayRange.upperBound - displayRange.lowerBound)
//      return (chartBounds.width * currentDisplayRangeLocation) + chartBounds.origin.x
//    }
//
    let index = closestIndex(for: touchLocation)
    
    
    for i in 0..<drawings.count {
      let drawing = drawings[i]
      let point = drawing.points[index]
     
      
      let line = bezierLine(from: CGPoint(x: point.x, y: chartBounds.origin.y + chartBounds.height), to: CGPoint(x: point.x, y: chartBounds.origin.y))
      let shapeLayerr = shapeLayer(withPath: line.cgPath, color: UIColor.blue.cgColor, lineWidth: 1.0)
      layer.addSublayer(shapeLayerr)
      
      let circle = bezierCircle(at: point)
      let circleShape = shapeLayer(withPath: circle.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth, fillColor: UIApplication.myDelegate.currentTheme.foregroundColor.cgColor)
      layer.addSublayer(circleShape)
    }
  }
  
  
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    print("moved")
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    print("ended")
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    print("cancelled")
  }
}
