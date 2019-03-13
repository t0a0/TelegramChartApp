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
  private struct Drawing {
    let identifier: String
    let line: UIBezierPath
    let shapeLayer: CAShapeLayer
  }
  weak var delegate: TGCAChartViewDelegate?
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    layer.masksToBounds = true
  }
  
  @IBOutlet var contentView: UIView!
  
  var lastYRange: ClosedRange<CGFloat> = 0...0
  
  /// From 0 to 1.0.
  var displayRange: ClosedRange<CGFloat> = ZORange {
    didSet {
      guard let drawings = drawings, let chart = chart else {
        return
      }

//      let bounds = chart.translatedBounds(for: displayRange)
//      let normalizedYVectors = chart.normalizedYVectors(in: displayRange)
//      let normalizedXVector = chart.normalizedXVector(in: displayRange)

//      let max = normalizedYVectors.1.map{$0.max() ?? 0}.max() ?? 0
//      let min = normalizedYVectors.1.map{$0.min() ?? 0}.min() ?? 0
//      let newRange = min...max
//      if lastYRange == newRange {
//        return
//      }
//      lastYRange = newRange
//      for i in 0..<drawings.count {
//        let drawing = drawings[i]
//        let yVector = normalizedYVectors.0[i].map{300 - ($0 * 300)}
//        let newPath = bezierLine(xVector: normalizedXVector.map{$0 * 375}, yVector: yVector)
//        let pathAnimation = CABasicAnimation(keyPath: "path")
//        pathAnimation.fromValue = drawing.shapeLayer.path
//        drawing.shapeLayer.path = newPath.cgPath
////        pathAnimation.fillMode = .forwards
//        pathAnimation.toValue = drawing.shapeLayer.path
//        pathAnimation.duration = 0.25
////        pathAnimation.isRemovedOnCompletion = false
//        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
//      }
      var excluded = [Int]()
      for i in 0..<hiddens.count {
        if hiddens[i] {excluded.append(i)}
      }
      let normalizedYVectors = chart.oddlyNormalizedYVectors(in: displayRange, excludedIdxs: excluded)
      let normalizedXVector = chart.normalizedXVector(in: displayRange)
      for i in 0..<drawings.count {
        let drawing = drawings[i]
        let yVector = normalizedYVectors.0[i].map{300 - ($0 * 300)}
        let newPath = bezierLine(xVector: normalizedXVector.map{$0 * 375}, yVector: yVector)
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = 0.25
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
    }
    }
  }
  
  private var yValueRange: ClosedRange<CGFloat> = 0...0
  private var hiddens: [Bool]!
  
  private var chart: LinearChart! {
    didSet {
      setNeedsLayout()
      let yVectors = chart.nyVectorGroup.vectors.map{$0.map{300 - ($0 * 300)}}
      let xVector = chart.xVector.nVector.vector.map{$0 * 375}
      var draws = [Drawing]()
      
      for i in 0..<yVectors.count {
        let line = bezierLine(xVector: xVector, yVector: yVectors[i])
        let sp = shapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor)
        layer.addSublayer(sp)
        draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, line: line, shapeLayer: sp))
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
      let yVector = normalizedYVectors.0[i].map{300 - ($0 * 300)}
      let newPath = bezierLine(xVector: normalizedXVector.map{$0 * 375}, yVector: yVector)
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
  }
  
  func bezierLine(xVector: ValueVector, yVector: ValueVector) -> UIBezierPath {
    let line = UIBezierPath()
    line.lineJoinStyle = .round
    
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
  
//  func bezierLine(for nDataSet: NormalizedDataSet) -> UIBezierPath {
//    let availableWidth = 320
//    let availableHeight = frame.height
//    //TODO: include 1 to the left and 1 to the right for proper display?
//    let includedPoints = nDataSet.points.filter{boundingXRange.contains($0.x)}
//
//    let ymin = includedPoints.minY
//    let ymax = includedPoints.maxY
//
//    let distance = availableWidth/CGFloat(includedPoints.count)
//    let notIncludedPointCount = CGFloat(nDataSet.points.count - includedPoints.count)
//
//    let line = UIBezierPath()
//    line.lineJoinStyle = .round
//    let firstPoint = nDataSet.points.first!
//    line.move(to: CGPoint(x: distance * notIncludedPointCount * -1,
//                          y: ((firstPoint.y - ymin) / (ymax - ymin)) * availableHeight))
//
//    var a = notIncludedPointCount - 1
//    for point in nDataSet.points[1..<nDataSet.points.count] {
//      line.addLine(to: CGPoint(x: distance * a * -1,
//                               y: ((point.y - ymin) / (ymax - ymin)) * availableHeight))
//      a -= 1
//    }
//    return line
//  }
  
  //MARK: - configure
  func changeDisplayedRange(_ range: ClosedRange<CGFloat>) {
    boundingXRange = CGFloat.random(in: -1000..<3500.0)...CGFloat.random(in: 3700..<11001)
  }
  
  var maxX: CGFloat = 0
  var maxY: CGFloat = 0
  
  private var boundingXRange: ClosedRange<CGFloat> = CGFloat(-500.0)...CGFloat(500.0) {
    didSet {
//      for ds in dataSets {
//        let newPath = bezierLine(for: ds.dataSet, boundingXRange: boundingXRange)
//        let pathAnimation = CABasicAnimation(keyPath: "path")
//        pathAnimation.fromValue = ds.shapeLayer.path
//        pathAnimation.fillMode = .forwards
//        pathAnimation.toValue = newPath.cgPath
//        pathAnimation.isRemovedOnCompletion = false
//        ds.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
//        ds.shapeLayer.path = newPath.cgPath
//      }
    }
  }
  
//  var dataSets = [(dataSet: DataSet, shapeLayer: CAShapeLayer)](){
//    didSet {
//      maxX = dataSets.map{$0.dataSet.maxX}.max()!
//      maxY = dataSets.map{$0.dataSet.maxY}.max()!
//    }
//  }
  
  
  
//  func drawGraph(for dataSet: DataSet, color: CGColor) -> CAShapeLayer {
//    let line = bezierLine(for: dataSet, boundingXRange: dataSet.minX...dataSet.maxX)
//    let sp = shapeLayer(withPath: line.cgPath, color: color)
//    layer.addSublayer(sp)
//    return sp
//    return CAShapeLayer()
//  }
  
//  func addDataSet(_ dataSet: DataSet, color: UIColor) {
//    dataSets.append((dataSet, drawGraph(for: dataSet, color: color.cgColor)))
  
//    let pathAnimation = CABasicAnimation(keyPath: "path")
//    pathAnimation.toValue = line2.cgPath
//    pathAnimation.autoreverses = true
//    pathAnimation.repeatCount = .greatestFiniteMagnitude
//    shapeLayer.add(pathAnimation, forKey: "pathAnimation")
//
//    let xShapes = addXAxisLayers()
//    var a: CGFloat = CGFloat(xShapes.count + 1)
//    for sh in xShapes {
//      let fadeAnim = CABasicAnimation(keyPath: "opacity")
//      fadeAnim.toValue = 0
//
//      let moveAnim = CABasicAnimation(keyPath: "position")
//      moveAnim.toValue = CGPoint(x: sh.shape.position.x, y: sh.shape.position.y - a * 50)
//
//
//
//
//      let grp = CAAnimationGroup()
//      grp.autoreverses = true
//      grp.repeatCount = .greatestFiniteMagnitude
//      grp.animations = [fadeAnim, moveAnim]
//      grp.duration = 0.25
//      sh.shape.add(grp, forKey: "groupAnimations")
//
//
//      let moveAnim2 = CABasicAnimation(keyPath: "position")
//      moveAnim2.toValue = CGPoint(x: sh.text.position.x, y: sh.text.position.y - a * 50)
//      moveAnim2.autoreverses = true
//      moveAnim2.duration = 0.25
//      moveAnim2.repeatCount = .greatestFiniteMagnitude
//      let fadeAnim2 = CABasicAnimation(keyPath: "opacity")
//      fadeAnim2.toValue = 0
//      fadeAnim2.duration = 0.5
//      fadeAnim2.autoreverses = true
//      fadeAnim2.repeatCount = .greatestFiniteMagnitude
//      sh.text.add(fadeAnim2, forKey: "fadeAnim")
//      sh.text.add(moveAnim2, forKey: "moveAnim")
//
//      a -= 1
//    }
//  }
  
  func addXAxisLayers() -> [(shape: CAShapeLayer, text: CATextLayer)]{
    
    
    let line2 = UIBezierPath()
    line2.move(to: CGPoint(x: 10, y: 60))
    line2.addLine(to: CGPoint(x: bounds.size.width - 10, y: 60))
    
    let line3 = UIBezierPath()
    line3.move(to: CGPoint(x: 10, y: 100))
    line3.addLine(to: CGPoint(x: bounds.size.width - 10, y: 100))
    
    let line4 = UIBezierPath()
    line4.move(to: CGPoint(x: 10, y: 140))
    line4.addLine(to: CGPoint(x: bounds.size.width - 10, y: 140))
    
    let line5 = UIBezierPath()
    line5.move(to: CGPoint(x: 10, y: 180))
    line5.addLine(to: CGPoint(x: bounds.size.width - 10, y: 180))
    
    var layers = [(shape: CAShapeLayer, text: CATextLayer)]()
    
    for i in [20, 60, 100, 140, 180] {
      let line = UIBezierPath()
      line.move(to: CGPoint(x: 10, y: i))
      line.addLine(to: CGPoint(x: bounds.size.width - 10, y: CGFloat(i)))
      let shapeLater = shapeLayer(withPath: line.cgPath, color: UIColor.lightGray.cgColor)
      let textLater = textLayer(position: CGPoint(x: 10, y: CGFloat(i) - 10), text: "\(i)")
      layer.addSublayer(shapeLater)
      layer.addSublayer(textLater)
      layers.append((shapeLater, textLater))
    }
    return layers
  }
  
  func shapeLayer(withPath path: CGPath, color: CGColor, lineWidth: CGFloat = 2) -> CAShapeLayer{
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path
    shapeLayer.strokeColor = color
    shapeLayer.lineWidth = lineWidth
    shapeLayer.lineJoin = .bevel
    shapeLayer.fillColor = nil
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
  
  //MARK: - draw
  
//  override func draw(_ rect: CGRect) {
//    for dataSet in dataSets {
//      UIColor.red.set()
//      let line = UIBezierPath()
//      line.move(to: CGPoint(x: 10, y: 10))
//      line.addLine(to: CGPoint(x: 90, y: 50))
//      line.lineWidth = 2
//      line.stroke()
//    }
//  }
}
