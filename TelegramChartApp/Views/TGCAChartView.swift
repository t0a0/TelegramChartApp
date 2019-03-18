//
//  TGCAChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit
import QuartzCore

class TGCAChartView: UIView {

  @IBOutlet var contentView: UIView!
  
  
  private var axisColor = UIColor.gray.cgColor
  private var axisLabelColor = UIColor.black.cgColor
  private var circlePointFillColor = UIColor.white.cgColor
  
  // MARK: - Init
  
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
  
  // MARK: - Variables
  
  //TODO: SHOULD NOT ALLOW TO SET THESE WHEN GRAPH IS DISPLAYING, or make it redraw when set
  var graphLineWidth: CGFloat = 2.0
  private let circlePointRadius: CGFloat = 4.0
  var shouldDisplaySupportAxis = false
  private let numOfSupportAxis = 6

  
  override var bounds: CGRect {
    didSet {
      //we need to inset drawing so that if the minimum or maximum points are selected, the circle is fully visible in the view
      let inset = circlePointRadius + graphLineWidth
      chartBounds = CGRect(x: bounds.origin.x + inset,
                           y: bounds.origin.y + inset,
                           width: bounds.width - inset * 2,
                           height: bounds.height - inset * 2)
    }
  }
  
  private var chartBounds: CGRect = CGRect.zero {
    didSet {
      configure(with: self.chart)
    }
  }

  private var chart: LinearChart!
  private var drawings: [Drawing]!
  private var hiddenDrawingIndicies: Set<Int>!
  private var supportAxis: [SupportAxis]!
  private var currentChartAnnotation: ChartAnnotation?
  
  // MARK: Range changing
  
  /// Range between total min and max of non-hidden graphs
  private var currentYValueRange: ClosedRange<CGFloat> = 0...0 {
    didSet {
      if shouldDisplaySupportAxis {
//        animateSupportAxisChange(fromPreviousRange: oldValue, toNewRange: currentYValueRange)
      }
    }
  }
  
  /// From 0 to 1.0.
  private var normalizedCurrentXRange: ClosedRange<CGFloat> = ZORange {
    didSet {
      guard var drawings = drawings, let chart = chart else {
        return
      }
      
      let normalizedYVectors = chart.normalizedYVectors(in: normalizedCurrentXRange, excludedIdxs: hiddenDrawingIndicies)
      let normalizedXVector = chart.normalizedXVector(in: normalizedCurrentXRange)
      
      let newYrange = normalizedYVectors.yRange
      if currentYValueRange != newYrange {
        currentYValueRange = newYrange
      }
      let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}

      for i in 0..<drawings.count {
        var drawing = drawings[i]
        let yVector = normalizedYVectors.vectors[i].map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}
        
        let points = convertToPoints(xVector: xVector, yVector: yVector)
        drawing.update(withPoints: points)
        
        let newPath = bezierLine(withPoints: points)
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = 0.25
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
        self.drawings[i] = drawing
    }
    }
  }
  
  private func reset() {
    self.chart = nil
    if let drawings = self.drawings {
      for drawing in drawings {
        drawing.shapeLayer.removeFromSuperlayer()
      }
      self.drawings = nil
    }
    if let supportAxis = self.supportAxis {
      for axis in supportAxis {
        axis.labelLayer.removeFromSuperlayer()
        axis.lineLayer.removeFromSuperlayer()
      }
      self.supportAxis = nil
    }
    self.hiddenDrawingIndicies = nil
    removeChartAnnotation()
  }
  
  // MARK: - Helping functions
  
  private func convertToPoints(xVector: [CGFloat], yVector: [CGFloat]) -> [CGPoint] {
    var points = [CGPoint]()
    for i in 0..<xVector.count {
      points.append(CGPoint(x: xVector[i], y: yVector[i]))
    }
    return points
  }

  // MARK: - Public functions
  
  /// Call to set chart
  func configure(with chart: LinearChart) {
    reset()
    self.chart = chart
    let oddlyNormalizedYVectors = chart.normalizedYVectors(in: ZORange, excludedIdxs: Set())
    let yVectors = oddlyNormalizedYVectors.vectors.map{$0.map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}}
    let xVector = chart.normalizedXVector(in: ZORange).map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    let newYrange = oddlyNormalizedYVectors.yRange
    currentYValueRange = newYrange
    
    var draws = [Drawing]()
    
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      
      let shape = shapeLayer(withPath: bezierLine(withPoints: points).cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
      layer.addSublayer(shape)
      draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, shapeLayer: shape, points: points))
    }
    self.drawings = draws
    self.hiddenDrawingIndicies = []
    if shouldDisplaySupportAxis  {
      addXAxisLayers()
    }
  }
  
  /// Call to update the diplayed X range. Accepted are subranges of 0...1.
  func updateDisplayRange(with newRange: ClosedRange<CGFloat>) {
    normalizedCurrentXRange = max(0, newRange.lowerBound)...min(1.0, newRange.upperBound)
  }

  /// Call to hide graph at index.
  func hide(at index: Int) {
    let originalHidden = hiddenDrawingIndicies.contains(index)
    if originalHidden {
      hiddenDrawingIndicies.remove(index)
    } else {
      hiddenDrawingIndicies.insert(index)
    }
    let normalizedYVectors = chart.normalizedYVectors(in: normalizedCurrentXRange, excludedIdxs: hiddenDrawingIndicies)
    let normalizedXVector = chart.normalizedXVector(in: normalizedCurrentXRange)
    let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    let newYrange = normalizedYVectors.yRange
    if currentYValueRange != newYrange {
      currentYValueRange = newYrange
    }
    
    for i in 0..<drawings.count {
      let drawing = drawings[i]
      let yVector = normalizedYVectors.vectors[i].map{chartBounds.size.height + chartBounds.origin.y - ($0 * chartBounds.size.height)}
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      let newPath = bezierLine(withPoints: points)
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

  
  
  
  // MARK: - Support axis
  
  private var supportAxisDefaultYPositions: [CGFloat] {
    let space = chartBounds.height / CGFloat(numOfSupportAxis)
    var retVal = [CGFloat]()
    for i in 0..<numOfSupportAxis {
      retVal.append(chartBounds.origin.y + chartBounds.height - (CGFloat(i) * space))
    }
    return retVal
  }
  
  private func addXAxisLayers() {
    var layers = [SupportAxis]()

    for i in 0..<supportAxisDefaultYPositions.count {
      let position = supportAxisDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: chartBounds.origin.x, y: position), to: CGPoint(x: chartBounds.origin.x + chartBounds.width, y: position))
      let shapeL = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      shapeL.opacity = 0.75
      let textL = textLayer(position: CGPoint(x: chartBounds.origin.x, y: position - 20), text: "\(((currentYValueRange.upperBound - currentYValueRange.lowerBound) * 0.85  / (CGFloat(i+1)) + currentYValueRange.lowerBound))", color: axisLabelColor)
      layer.addSublayer(shapeL)
      layer.addSublayer(textL)
      layers.append((shapeL, textL, position))
    }
    self.supportAxis = layers
  }
  
  private func animateSupportAxisChange(fromPreviousRange previousRange: ClosedRange<CGFloat>, toNewRange newRange: ClosedRange<CGFloat>) {
    
    guard let supportAxis = supportAxis else {
      return
    }
    
    let coefficient: CGFloat = newRange.upperBound / previousRange.upperBound // TODO: separately for each
    for (lineLayer, labelLayer, position) in supportAxis {
      let newLinePosition = CGPoint(x: lineLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - position) * coefficient)
      let newTextPosition = CGPoint(x: labelLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - position - 20) * coefficient)
      
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
      CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
      CATransaction.setCompletionBlock{
        lineLayer.removeFromSuperlayer()
        labelLayer.removeFromSuperlayer()
      }
      labelLayer.position = newTextPosition
      labelLayer.opacity = 0
      lineLayer.opacity = 0
      lineLayer.position = newLinePosition
      CATransaction.commit()
      CATransaction.flush()
      
    }
    
    addXAxisLayers()
    
    for (lineLayer, labelLayer, _) in supportAxis {
      let oL = lineLayer.position
      let oT = labelLayer.position
      let newLinePosition = CGPoint(x: lineLayer.position.x, y: lineLayer.position.y + chartBounds.height * coefficient)
      let newTextPosition = CGPoint(x: labelLayer.position.x, y: labelLayer.position.y + chartBounds.height * coefficient)
//      print(oT)
//      print(newTextPosition)
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
  
  private func bezierLine(withPoints points: [CGPoint]) -> UIBezierPath {
    let line = UIBezierPath()
    let firstPoint = points[0]
    line.move(to: firstPoint)
    for i in 1..<points.count {
      line.addLine(to: points[i])
    }
    return line
  }
  
  // MARK: - Drawing
  
  private func bezierLine(from fromPoint: CGPoint, to toPoint: CGPoint) -> UIBezierPath {
    let line = UIBezierPath()
    line.move(to: fromPoint)
    line.addLine(to: toPoint)
    return line
  }
  
  private func bezierCircle(at point: CGPoint, radius: CGFloat = 4.0) -> UIBezierPath {
    let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
    return UIBezierPath(ovalIn: rect)
  }
  
  private func shapeLayer(withPath path: CGPath, color: CGColor, lineWidth: CGFloat = 2, fillColor: CGColor? = nil) -> CAShapeLayer{
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path
    shapeLayer.strokeColor = color
    shapeLayer.lineWidth = lineWidth
    shapeLayer.lineJoin = .round
    shapeLayer.lineCap = .round
    shapeLayer.fillColor = fillColor
    return shapeLayer
  }
  
  func textLayer(position: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = "Helvetica" as CFTypeRef
    textLayer.fontSize = 13.0
    textLayer.string = text
    textLayer.frame = CGRect(origin: position, size: CGSize(width: 100, height: 20))
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.foregroundColor = color
    return textLayer
  }
  
  // MARK: - Touches
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return bounds.contains(point) ? self : nil
  }
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return bounds.contains(point)
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
    guard let touchLocation = touches.first?.location(in: self), chartBounds.contains(touchLocation), let currentAnnotation = currentChartAnnotation else {
      return
    }
    
    let index = closestIndex(for: touchLocation)
    if index != currentAnnotation.displayedIndex {
      moveChartAnnotation(to: index)
    }
  }
  
  // MARK: - Annotation
  
  private func closestIndex(for touchLocation: CGPoint) -> Int {
    let xPositionInChartBounds = touchLocation.x - chartBounds.origin.x
    let translatedToDisplayRange = (normalizedCurrentXRange.upperBound - normalizedCurrentXRange.lowerBound) * (xPositionInChartBounds / chartBounds.width) + normalizedCurrentXRange.lowerBound
    let index = round(CGFloat(chart.xVector.count - 1) * translatedToDisplayRange)
    return Int(index)
  }
  
  private func addChartAnnotation(for index: Int) {
    let xPoint = drawings[0].points[index].x
    var circleLayers = [CAShapeLayer]()
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector[index])/1000)

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
    let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 1.0)
    layer.addSublayer(lineLayer)
    for c in circleLayers {
      layer.addSublayer(c)
    }
    addSubview(annotationView)

    self.currentChartAnnotation = ChartAnnotation(lineLayer: lineLayer, annotationView: annotationView, circleLayers: circleLayers, displayedIndex: index)
  }
  
  private func moveChartAnnotation(to index: Int) {
    guard let annotation = currentChartAnnotation else {
      return
    }
    let xPoint = drawings[0].points[index].x
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector[index])/1000)
    
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
    currentChartAnnotation?.updateDiplayedIndex(to: index)
  }
  
  func removeChartAnnotation() {
    if let annotation = currentChartAnnotation {
      annotation.lineLayer.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      for layer in annotation.circleLayers {
        layer.removeFromSuperlayer()
      }
      self.currentChartAnnotation = nil
    }
  }

  // MARK: - Structs and typealiases
  
  private typealias SupportAxis = (lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat)
  
  private struct Drawing {
    let identifier: String
    let shapeLayer: CAShapeLayer
    private(set) var points: [CGPoint]
    
    mutating func update(withPoints points: [CGPoint]) {
      self.points = points
    }
  }
  
  private struct ChartAnnotation {
    let lineLayer: CAShapeLayer
    let annotationView: TGCAChartAnnotationView
    let circleLayers: [CAShapeLayer]
    private(set) var displayedIndex: Int
    
    mutating func updateDiplayedIndex(to toIndex: Int) {
      self.displayedIndex = toIndex
    }
  }
}


extension TGCAChartView: ThemeChangeObserving {
  
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
  
}
