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
  
  private let chartLabelFormatterService: ChartLabelFormatterProtocol = TGCAChartLabelFormatterService()
  
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
  private let numOfSupportAxis = 5
  var animatesPositionOnHide = true
  var valuesStartFromZero = true
  private let heightForGuideLabels: CGFloat = 20.0
  private let numOfGuideLabels = 6
  
  override var bounds: CGRect {
    didSet {
      //we need to inset drawing so that if the minimum or maximum points are selected, the circle is fully visible in the view
      let inset = circlePointRadius + graphLineWidth
      chartBounds = CGRect(x: bounds.origin.x + inset,
                           y: bounds.origin.y + inset,
                           width: bounds.width - inset * 2,
                           height: bounds.height - inset * 2
                            - (shouldDisplaySupportAxis ? heightForGuideLabels : 0))
    }
  }
  
  private var chartBounds: CGRect = CGRect.zero {
    didSet {
      configure(with: self.chart)
    }
  }
  
  private func configureAxisDefaultPositions() {
    let space = chartBounds.height * capHeightMultiplierForAxis / CGFloat(numOfSupportAxis)
    var retVal = [CGFloat]()
    for i in 0..<numOfSupportAxis {
      retVal.append(chartBounds.origin.y + chartBounds.height - (CGFloat(i) * space + space))
    }
    supportAxisDefaultYPositions = retVal
  }

  private var chart: LinearChart!
  private var drawings: [Drawing]!
  private var hiddenDrawingIndicies: Set<Int>!
  private var supportAxis: [SupportAxis]!
  private var zeroAxis: SupportAxis!
  private var currentChartAnnotation: ChartAnnotation?
  private var guideLabels: [CATextLayer]!
  
  // MARK: Range changing
  
  /// Range between total min and max of non-hidden graphs
  private var currentYValueRange: ClosedRange<CGFloat> = 0...0 {
    didSet {
      if shouldDisplaySupportAxis {
        configureTextsForSupportAxisLabels()
        if !valuesStartFromZero {
          updateZeroAxis()
        }
        animateSupportAxisChange(fromPreviousRange: oldValue, toNewRange: currentYValueRange)
      }
    }
  }
  
  func configureTextsForSupportAxisLabels() {
    var textsForAxisLabels = [String]()
    for i in 0..<numOfSupportAxis {
      let value = (((currentYValueRange.upperBound - currentYValueRange.lowerBound) * capHeightMultiplierForAxis / CGFloat(numOfSupportAxis)) * CGFloat(i+1)) + currentYValueRange.lowerBound
      textsForAxisLabels.append(chartLabelFormatterService.prettyValueString(from: value))
    }
    labelTextsForCurrentYRange = textsForAxisLabels
  }
  
  /// From 0 to 1.0.
  private var normalizedCurrentXRange: ClosedRange<CGFloat> = ZORange
  
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
    if let zeroAxis = self.zeroAxis {
      zeroAxis.labelLayer.removeFromSuperlayer()
      zeroAxis.lineLayer.removeFromSuperlayer()
      self.zeroAxis = nil
    }
    if let guideLabels = self.guideLabels {
      for gL in guideLabels {
        gL.removeFromSuperlayer()
      }
      self.guideLabels = nil
    }
    self.hiddenDrawingIndicies = nil
    removeChartAnnotation()
    currentYValueRange = 0...0
  }
  
  // MARK: - Helping functions
  
  private func convertToPoints(xVector: [CGFloat], yVector: [CGFloat]) -> [CGPoint] {
    var points = [CGPoint]()
    for i in 0..<xVector.count {
      points.append(CGPoint(x: xVector[i], y: yVector[i]))
    }
    return points
  }
  
  private func getNormalizedYVectors() -> NormalizedYVectors{
    return valuesStartFromZero
      ? chart.normalizedYVectors(in: normalizedCurrentXRange, excludedIdxs: hiddenDrawingIndicies)
      : chart.normalizedYVectorsFromLocalMinimum(in: normalizedCurrentXRange, excludedIdxs: hiddenDrawingIndicies)
  }

  // MARK: - Public functions
  
  /// Call to set chart
  func configure(with chart: LinearChart) {
    reset()
    configureAxisDefaultPositions()
    self.chart = chart
    self.hiddenDrawingIndicies = Set()
    let normalizedYVectors = getNormalizedYVectors()
    let yVectors = normalizedYVectors.vectors.map{$0.map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}}
    let xVector = chart.normalizedXVector(in: normalizedCurrentXRange).map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    currentYValueRange = normalizedYVectors.yRange
    
    var draws = [Drawing]()
    
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      
      let shape = shapeLayer(withPath: bezierLine(withPoints: points).cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
      shape.zPosition = zPositions.Chart.graph.rawValue
      layer.addSublayer(shape)
      draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, shapeLayer: shape, points: points))
    }
    self.drawings = draws
    if shouldDisplaySupportAxis  {
      addZeroAxis()
      addXAxisLayers()
      addGuideLabels()
    }
  }
  
  /// Call to update the diplayed X range. Accepted are subranges of 0...1.
  func updateDisplayRange(with newRange: ClosedRange<CGFloat>, ended: Bool) {
    guard normalizedCurrentXRange != newRange else {
      return
    }
    animateGuideLabelsChange(from: normalizedCurrentXRange, to: newRange)
    normalizedCurrentXRange = max(0, newRange.lowerBound)...min(1.0, newRange.upperBound)

    guard var drawings = drawings, let chart = chart else {
      return
    }
    
    let normalizedYVectors = getNormalizedYVectors()
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
      if drawing.shapeLayer.animationKeys() != nil && !ended {
        continue
      }
      let newPath = bezierLine(withPoints: points)
      let pathAnimation = CABasicAnimation(keyPath: "path")
      pathAnimation.fromValue = drawing.shapeLayer.path
      drawing.shapeLayer.path = newPath.cgPath
      pathAnimation.toValue = drawing.shapeLayer.path
      pathAnimation.duration = ended ? 0.25 : 0.075
      
      drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      self.drawings[i] = drawing
    }
  }

  /// Call to hide graph at index.
  func hide(at index: Int) {
    let originalHidden = hiddenDrawingIndicies.contains(index)
    if originalHidden {
      hiddenDrawingIndicies.remove(index)
    } else {
      hiddenDrawingIndicies.insert(index)
    }
    let normalizedYVectors = getNormalizedYVectors()
    let normalizedXVector = chart.normalizedXVector(in: normalizedCurrentXRange)
    let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    let newYrange = normalizedYVectors.yRange
    if currentYValueRange != newYrange {
      currentYValueRange = newYrange
    }
    
    for i in 0..<drawings.count {
      let drawing = drawings[i]
      
      let positionChangeBlock = {
        let yVector = normalizedYVectors.vectors[i].map{self.chartBounds.size.height + self.chartBounds.origin.y - ($0 * self.chartBounds.size.height)}
        let points = self.convertToPoints(xVector: xVector, yVector: yVector)
        let newPath = self.bezierLine(withPoints: points)
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = 0.25
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      }
      
      if animatesPositionOnHide {
        positionChangeBlock()
      } else {
        if !hiddenDrawingIndicies.contains(i) {
          positionChangeBlock()
        }
      }
      
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

  // MARK: - Guide Labels
  
  private func addGuideLabels() {
    let rangeSpacing = normalizedCurrentXRange.distance / CGFloat(numOfGuideLabels)
    let chartboundsSpacing = chartBounds.width / CGFloat(numOfGuideLabels)
    var locations = [normalizedCurrentXRange.lowerBound]
    for i in 1..<numOfGuideLabels - 1 {
      locations.append(normalizedCurrentXRange.lowerBound + rangeSpacing * CGFloat(i))
    }
    locations.append(normalizedCurrentXRange.upperBound)
    
    //TODO: what if values are less than 6 in this range?
    
    let actualIndexes = locations.map{chart.translatedIndex(for: $0)}
    let timeStamps = actualIndexes.map{chart.xVector[$0]}
    let strings = timeStamps.map{chartLabelFormatterService.prettyDateString(from: $0)}
    
    var guideLayers = [CATextLayer]()
    for i in 0..<strings.count {
      let textL = textLayer(origin: CGPoint(x: chartBounds.origin.x + chartboundsSpacing * CGFloat(i), y: chartBounds.origin.y + chartBounds.height + 5), text: strings[i], color: axisLabelColor)
      guideLayers.append(textL)
      layer.addSublayer(textL)
    }
    guideLabels = guideLayers
  }
  
  
  
  // MARK: - Support axis
  
  private let capHeightMultiplierForAxis: CGFloat = 0.85
  
  private var supportAxisDefaultYPositions: [CGFloat]!
  private var labelTextsForCurrentYRange: [String]!
  
  private func addZeroAxis() {
    let zposition = chartBounds.origin.y + chartBounds.height
    let zline = bezierLine(from: CGPoint(x: chartBounds.origin.x, y: zposition), to: CGPoint(x: chartBounds.origin.x + chartBounds.width, y: zposition))
    let zshapeL = shapeLayer(withPath: zline.cgPath, color: axisColor, lineWidth: 0.5)
    zshapeL.opacity = 1
    let text = chartLabelFormatterService.prettyValueString(from: currentYValueRange.lowerBound)
    let ztextL = textLayer(origin: CGPoint(x: chartBounds.origin.x, y: zposition - 20), text: text, color: axisLabelColor)
    zshapeL.zPosition = zPositions.Chart.axis.rawValue
    ztextL.zPosition = zPositions.Chart.axisLabel.rawValue
    layer.addSublayer(zshapeL)
    layer.addSublayer(ztextL)
    
    zeroAxis = SupportAxis(zshapeL, ztextL)
  }
  
  private func updateZeroAxis() {
    guard let zeroAxis = self.zeroAxis else {
      return
    }
    let text = chartLabelFormatterService.prettyValueString(from: currentYValueRange.lowerBound)
    zeroAxis.labelLayer.string = text
  }
  
  private func addXAxisLayers() {
    var newAxis = [SupportAxis]()

    for i in 0..<supportAxisDefaultYPositions.count {
      let position = supportAxisDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: chartBounds.origin.x, y: position), to: CGPoint(x: chartBounds.origin.x + chartBounds.width, y: position))
      let shapeL = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      shapeL.opacity = 0.75
      shapeL.zPosition = zPositions.Chart.axis.rawValue
      let textL = textLayer(origin: CGPoint(x: chartBounds.origin.x, y: position - 20), text: labelTextsForCurrentYRange[i], color: axisLabelColor)
      textL.zPosition = zPositions.Chart.axisLabel.rawValue
      layer.addSublayer(shapeL)
      layer.addSublayer(textL)
      newAxis.append((shapeL, textL))
    }
    self.supportAxis = newAxis
  }
  
  private func animateSupportAxisChange(fromPreviousRange previousRange: ClosedRange<CGFloat>, toNewRange newRange: ClosedRange<CGFloat>) {
    guard let supportAxis = self.supportAxis else {
      return
    }
    
    let coefficient: CGFloat = newRange.upperBound / previousRange.upperBound
    
    var blocks = [()->()]()
    var removalBlocks = [()->()]()
    var newAxis = [SupportAxis]()
    
    for i in 0..<supportAxis.count {
      let ax = supportAxis[i]
      
      let newLinePosition = CGPoint(x: ax.lineLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - ax.lineLayer.position.y) / coefficient)
      let newTextPosition = CGPoint(x: ax.labelLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - ax.labelLayer.position.y) / coefficient)
      
      
      let position = supportAxisDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: chartBounds.origin.x, y: position), to: CGPoint(x: chartBounds.origin.x + chartBounds.width, y: position))
      let shapeL = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      let textL = textLayer(origin: CGPoint(x: chartBounds.origin.x, y: position - 20), text: labelTextsForCurrentYRange[i], color: axisLabelColor)
      textL.opacity = 0
      shapeL.opacity = 0
      shapeL.zPosition = zPositions.Chart.axis.rawValue
      textL.zPosition = zPositions.Chart.axisLabel.rawValue
      layer.addSublayer(shapeL)
      layer.addSublayer(textL)
      let oldShapePos = shapeL.position
      let oldTextPos = textL.position
      shapeL.position = CGPoint(x: shapeL.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - shapeL.position.y) * coefficient)
      textL.position = CGPoint(x: textL.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - textL.position.y) * coefficient)
      newAxis.append((shapeL, textL))
      
      
      blocks.append {
        ax.labelLayer.position = newTextPosition
        ax.labelLayer.opacity = 0
        ax.lineLayer.opacity = 0
        ax.lineLayer.position = newLinePosition
        
        shapeL.opacity = 0.75
        shapeL.position = oldShapePos
        textL.position = oldTextPos
        textL.opacity = 1.0
        
      }
      removalBlocks.append {
        ax.lineLayer.removeFromSuperlayer()
        ax.labelLayer.removeFromSuperlayer()
      }
    }
    
    self.supportAxis = newAxis
    
    DispatchQueue.main.async {
      CATransaction.flush()
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
      CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
      CATransaction.setCompletionBlock{
        for r in removalBlocks {
          r()
        }
      }
      for b in blocks {
        b()
      }
      CATransaction.commit()
    }
    
  }
  
  // MARK: - Drawing
  
  private func bezierLine(withPoints points: [CGPoint]) -> UIBezierPath {
    let line = UIBezierPath()
    let firstPoint = points[0]
    line.move(to: firstPoint)
    for i in 1..<points.count {
      line.addLine(to: points[i])
    }
    return line
  }
  
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
    shapeLayer.contentsScale = UIScreen.main.scale
    return shapeLayer
  }
  
  func textLayer(origin: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = "Helvetica" as CFTypeRef
    textLayer.fontSize = 13.0
    textLayer.string = text
    textLayer.frame = CGRect(origin: origin, size: CGSize(width: 100, height: heightForGuideLabels))
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.foregroundColor = color
    return textLayer
  }
  
  func textLayer(position: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = "Helvetica" as CFTypeRef
    textLayer.fontSize = 13.0
    textLayer.string = text
    textLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 45, height: heightForGuideLabels))
    textLayer.position = position
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
    return chart.translatedIndex(for: translatedToDisplayRange)
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
      circleShape.zPosition = zPositions.Annotation.circleShape.rawValue
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
    lineLayer.zPosition = zPositions.Annotation.lineShape.rawValue
    layer.addSublayer(lineLayer)
    for c in circleLayers {
      layer.addSublayer(c)
    }
    annotationView.layer.zPosition = zPositions.Annotation.view.rawValue
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
  
  private typealias SupportAxis = (lineLayer: CAShapeLayer, labelLayer: CATextLayer)
  
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
  
  private struct zPositions {
    enum Annotation: CGFloat {
      case view = 10.0
      case lineShape = 5.0
      case circleShape = 6.0
    }
    
    enum Chart: CGFloat {
      case axis = -10.0
      case axisLabel = 7.0
      case graph = 0
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
      if let supportAxis = supportAxis {
        for axis in supportAxis {
          axis.labelLayer.foregroundColor = axisLabelColor
          axis.lineLayer.strokeColor = axisColor
        }
      }
      if let zeroAxis = zeroAxis {
        zeroAxis.labelLayer.foregroundColor = axisLabelColor
        zeroAxis.lineLayer.strokeColor = axisColor
      }
    }
    
    if animated {
      CATransaction.begin()
      CATransaction.setAnimationDuration(0.25)
      applyChanges()
      CATransaction.commit()
    } else {
      applyChanges()
    }
  }
  
}
