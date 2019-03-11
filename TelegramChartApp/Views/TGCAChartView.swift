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
  
  weak var delegate: TGCAChartViewDelegate?
  
  @IBOutlet var contentView: UIView!
  
  //TODO: Limit it by overriding will set
  var displayRange: ClosedRange<CGFloat> = 0.0...1.0 {
    didSet {
      guard let drawings = drawings, let chart = chart else {
        return
      }
      
      for drawing in drawings {
        
      }
      
//      for dr in charts {
//        let nds = chart.normalizedDataSet
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
  
  private var chart: LinearChart?
  private var drawings: [Drawing]?
  
  
  private struct Drawing {
    let identifier: String
    let line: UIBezierPath
    let shapeLayer: CAShapeLayer
  }
  
  func configure(with chart: LinearChart) {
    let xVector = chart.xVector.normalizedVector
    let yVectors = chart.yVectors.map{$0.normalizedVector}
    
    var draws = [Drawing]()
    
    for i in 0..<yVectors.count {
      let line = bezierLine(xVector: xVector, yVector: yVectors[i])
      let sp = shapeLayer(withPath: line.cgPath, color: chart.yVectors[i].metaData.color.cgColor)
      layer.addSublayer(sp)
      draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, line: line, shapeLayer: sp))
    }
    self.chart = chart
    self.drawings = draws
  }
  
  func bezierLine(xVector: NormalizedValueVector, yVector: NormalizedValueVector) -> UIBezierPath {
    let line = UIBezierPath()
    line.lineJoinStyle = .round
    
    func point(for i: Int) -> CGPoint {
      return CGPoint(x: xVector.vector[i], y: yVector.vector[i])
    }
    
    let firstPoint = point(for: 0)
    line.move(to: firstPoint)
    
    for i in 1..<xVector.vector.count {
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
