//
//  TGCAChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit
import QuartzCore

class TGCAChartView: UIView, ThemeChangeObserving {

  
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
    applyCurrentTheme()
  }
  
  override func didMoveToWindow() {
    if window != nil {
      subscribe()
    }
  }
  
  override func willMove(toWindow newWindow: UIWindow?) {
    if newWindow == nil {
      unsubscribe()
    }
  }
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  private var axisColor = UIColor.gray.cgColor
  private var axisLabelColor = UIColor.black.cgColor
  private var circlePointFillColor = UIColor.white.cgColor
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    axisColor = theme.axisColor.cgColor
    axisLabelColor = theme.axisLabelColor.cgColor
    circlePointFillColor = theme.foregroundColor.cgColor
    
    func applyChanges() {
      if let annotation = currentChartAnnotation {
        for circle in annotation.circleLayers {
          circle.fillColor = circlePointFillColor
        }
        annotation.lineLayer.strokeColor = axisColor
      }
    }
    
    if animated {
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
        applyChanges()
      CATransaction.commit()
      CATransaction.flush()
    } else {
      applyChanges()
    }
  }
  
  override var bounds: CGRect {
    didSet {
      //we need to inset drawing so that if the minimum or maxim points are selected, the circle is fully visible
      let inset = circlePointRadius + graphLineWidth
      chartBounds = CGRect(x: bounds.origin.x + inset,
                           y: bounds.origin.y + inset,
                           width: bounds.width - inset * 2,
                           height: bounds.height - inset * 2)
    }
  }
  
  var graphLineWidth: CGFloat = 2.0
  var circlePointRadius: CGFloat = 4.0
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
  
  func bezierCircle(at point: CGPoint, radius: CGFloat = 4.0) -> UIBezierPath {
    let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
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
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return bounds.contains(point) ? self : nil
  }
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return bounds.contains(point)
  }
  
  func closestIndex(for touchLocation: CGPoint) -> Int {
    let xPositionInChartBounds = touchLocation.x - chartBounds.origin.x
    let translatedToDisplayRange = (displayRange.upperBound - displayRange.lowerBound) * (xPositionInChartBounds / chartBounds.width) + displayRange.lowerBound
    let index = round(CGFloat(chart.xVector.vector.count - 1) * translatedToDisplayRange)
    print(index)
    return Int(index)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touchLocation = touches.first?.location(in: self), chartBounds.contains(touchLocation) else {
      return
    }
    
    let index = closestIndex(for: touchLocation)

    if let annotation = currentChartAnnotation {
      if annotation.annotationView.frame.contains(touchLocation) {
        removeChartAnnotation()
        return
      } else {
        moveChartAnnotation(to: index)
      }
    } else {
      addChartAnnotation(for: index)
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touchLocation = touches.first?.location(in: self), chartBounds.contains(touchLocation) else {
      return
    }
    
    guard let currentAnnotation = currentChartAnnotation else {
      return
    }
    
    let index = closestIndex(for: touchLocation)
    if index != currentAnnotation.displayedIndex {
      moveChartAnnotation(to: index)
    }
  }
  
  struct ChartAnnotation {
    let lineLayer: CAShapeLayer
    let annotationView: TGCAChartAnnotationView
    let circleLayers: [CAShapeLayer]
    private(set) var displayedIndex: Int
    mutating func updateDiplayedIndex(to toIndex: Int) {
      self.displayedIndex = toIndex
    }
  }
  
  var currentChartAnnotation: ChartAnnotation?
  
  func addChartAnnotation(for index: Int) {
    let xPoint = drawings[0].points[index].x
    
    
    
    var circleLayers = [CAShapeLayer]()
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector.vector[index])/1000)

    for i in 0..<drawings.count {
      let drawing = drawings[i]
      let point = drawing.points[index]
      
      let circle = bezierCircle(at: point, radius: circlePointRadius)
      let circleShape = shapeLayer(withPath: circle.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth, fillColor: circlePointFillColor)
      circleLayers.append(circleShape)
      coloredValues.append((chart.yVectors[i].vector[index], chart.yVectors[i].metaData.color))
    }
    coloredValues.sort { (left, right) -> Bool in
      return left.0 >= right.0
    }
    let annotationView = TGCAChartAnnotationView(frame: CGRect.zero)
    let annotationSize = annotationView.configure(date: date, coloredValues: coloredValues)
    let xPos = min(bounds.origin.x + bounds.width - annotationSize.width / 2, max(bounds.origin.x + annotationSize.width / 2, xPoint))
    annotationView.center = CGPoint(x: xPos, y: bounds.origin.y + annotationSize.height / 2)
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotationView.frame.origin.y + annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBounds.origin.y + chartBounds.height))
    let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 1.5)
    layer.addSublayer(lineLayer)
    for c in circleLayers {
      layer.addSublayer(c)
    }
    addSubview(annotationView)

    self.currentChartAnnotation = ChartAnnotation(lineLayer: lineLayer, annotationView: annotationView, circleLayers: circleLayers, displayedIndex: index)
  }
  
  func moveChartAnnotation(to index: Int) {
    guard let annotation = currentChartAnnotation else {
      return
    }
    let xPoint = drawings[0].points[index].x
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector.vector[index])/1000)
    
    for i in 0..<drawings.count {
      let drawing = drawings[i]
      let point = drawing.points[index]
      
      let circle = bezierCircle(at: point, radius: circlePointRadius)
      currentChartAnnotation?.circleLayers[i].path = circle.cgPath
      coloredValues.append((chart.yVectors[i].vector[index], chart.yVectors[i].metaData.color))
    }
    coloredValues.sort { (left, right) -> Bool in
      return left.0 >= right.0
    }
    let annotationSize = annotation.annotationView.configure(date: date, coloredValues: coloredValues)
    let xPos = min(bounds.origin.x + bounds.width - annotationSize.width / 2, max(bounds.origin.x + annotationSize.width / 2, xPoint))
    annotation.annotationView.center = CGPoint(x: xPos, y: bounds.origin.y + annotationSize.height / 2)
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotation.annotationView.frame.origin.y + annotation.annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBounds.origin.y + chartBounds.height))
    currentChartAnnotation?.lineLayer.path = line.cgPath
  }
  
  func removeChartAnnotation() {
    if let annotation = currentChartAnnotation {
      annotation.lineLayer.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      for layer in annotation.circleLayers {
        layer.removeFromSuperlayer()
      }
      currentChartAnnotation = nil
    }
  }
  

}
