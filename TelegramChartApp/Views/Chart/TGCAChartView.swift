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
      //we need to inset drawing so that if the minimum or maximum points are selected, the circular point on the graph is fully visible in the view
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
  private var drawings: ChartDrawings!
  private var hiddenDrawingIndicies: Set<Int>!
  private var supportAxis: [SupportAxis]!
  private var zeroAxis: SupportAxis!
  private var currentChartAnnotation: ChartAnnotation?
  private var activeGuideLabels: [GuideLabel]!
  private var transitioningGuideLabels: [GuideLabel]!
  
  // MARK: - Range changing
  
  /// Range between total min and max of non-hidden graphs
  private var currentYValueRange: ClosedRange<CGFloat> = 0...0 {
    didSet {
      guard oldValue != currentYValueRange else {
        return
      }
      if shouldDisplaySupportAxis {
        configureTextsForSupportAxisLabels()
        if !valuesStartFromZero {
          updateZeroAxis()
        }
        animateSupportAxisChange(fromPreviousRange: oldValue, toNewRange: currentYValueRange)
      }
    }
  }
  
  private func configureTextsForSupportAxisLabels() {
    var textsForAxisLabels = [String]()
    for i in 0..<numOfSupportAxis {
      let value = (((currentYValueRange.upperBound - currentYValueRange.lowerBound) * capHeightMultiplierForAxis / CGFloat(numOfSupportAxis)) * CGFloat(i+1)) + currentYValueRange.lowerBound
      textsForAxisLabels.append(chartLabelFormatterService.prettyValueString(from: value))
    }
    labelTextsForCurrentYRange = textsForAxisLabels
  }
  
  /// From 0 to 1.0.
  private var currentXIndexRange: ClosedRange<Int>!
  
  
  
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
      ? chart.normalizedYVectorsFromZeroMinimum(in: currentXIndexRange, excludedIdxs: hiddenDrawingIndicies)
      : chart.normalizedYVectorsFromLocalMinimum(in: currentXIndexRange, excludedIdxs: hiddenDrawingIndicies)
  }

  // MARK: - Public functions
  
  /// Call to set chart
  func configure(with chart: LinearChart) {
    reset()
    configureAxisDefaultPositions()
    self.chart = chart
    self.hiddenDrawingIndicies = Set()
    self.currentXIndexRange = self.currentXIndexRange ?? 0...chart.xVector.count-1
    let normalizedYVectors = getNormalizedYVectors()
    let yVectors = normalizedYVectors.vectors.map{$0.map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}}
    let xVector = chart.normalizedXVector(in: currentXIndexRange).map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    currentYValueRange = normalizedYVectors.yRange
    
    var draws = [Drawing]()
    
    for i in 0..<yVectors.count {
      let yVector = yVectors[i]
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      
      let shape = shapeLayer(withPath: bezierLine(withPoints: points).cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth)
      shape.zPosition = zPositions.Chart.graph.rawValue
      layer.addSublayer(shape)
      draws.append(Drawing(identifier: chart.yVectors[i].metaData.identifier, shapeLayer: shape, yPositions: yVector))
    }
    self.drawings = ChartDrawings(drawings: draws, xPositions: xVector)
    if shouldDisplaySupportAxis  {
      addZeroAxis()
      addXAxisLayers()
      addGuideLabels()
    }
  }
  
  /// Call to update the diplayed X range. Accepted are subranges of 0...1.
  func updateDisplayRange(with newRange: ClosedRange<CGFloat>, event: DisplayRangeChangeEvent) {
    let newBounds = chart.translatedBounds(for: newRange)
    guard let drawings = drawings, let chart = chart, currentXIndexRange != newBounds else {
      return
    }
    currentXIndexRange = newBounds

    let normalizedYVectors = getNormalizedYVectors()
    let normalizedXVector = chart.normalizedXVector(in: currentXIndexRange)
    
    let didYChange = currentYValueRange != normalizedYVectors.yRange
    
    currentYValueRange = normalizedYVectors.yRange
    
    let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    var newDrawings = [Drawing]()
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let yVector = normalizedYVectors.vectors[i].map{chartBounds.size.height - ($0 * chartBounds.size.height) + chartBounds.origin.y}
      
      let points = convertToPoints(xVector: xVector, yVector: yVector)
      newDrawings.append(Drawing(identifier: drawing.identifier, shapeLayer: drawing.shapeLayer, yPositions: yVector))
      let newPath = bezierLine(withPoints: points)

      if let oldAnim = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.presentation()?.value(forKey: "path") ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPath.cgPath
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = 0.25
        if !didYChange {
          pathAnimation.beginTime = oldAnim.beginTime
        }
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      } else {
        if didYChange  {
          let pathAnimation = CABasicAnimation(keyPath: "path")
          pathAnimation.fromValue = drawing.shapeLayer.path
          drawing.shapeLayer.path = newPath.cgPath
          pathAnimation.toValue = drawing.shapeLayer.path
          pathAnimation.duration = 0.25
          drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
        } else {
          drawing.shapeLayer.path = newPath.cgPath
        }
      }
    }
    self.drawings = ChartDrawings(drawings: newDrawings, xPositions: xVector)
    animateGuideLabelsChange(from: currentXIndexRange, to: newBounds, event: event)
    removeChartAnnotation()
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
    let normalizedXVector = chart.normalizedXVector(in: currentXIndexRange)
    let xVector = normalizedXVector.map{$0 * chartBounds.size.width + chartBounds.origin.x}
    
    currentYValueRange = normalizedYVectors.yRange
    
    var newDrawings = [Drawing]()
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let yVector = normalizedYVectors.vectors[i].map{chartBounds.size.height + chartBounds.origin.y - ($0 * chartBounds.size.height)}
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
        pathAnimation.duration = 0.25
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
      newDrawings.append(Drawing(identifier: drawing.identifier, shapeLayer: drawing.shapeLayer, yPositions: yVector))

      
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
        opacityAnimation.duration = 0.25
        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }

    }
    self.drawings = ChartDrawings(drawings: newDrawings, xPositions: xVector)
    if let annotation = currentChartAnnotation {
      moveChartAnnotation(to: annotation.displayedIndex, animated: true)
    }
  }

  // MARK: - Guide Labels
  
  private func addGuideLabels() {
    
    let (spacing, leftover) = chart.labelSpacing(for: chart.xVector.count)
    lastLeftover = leftover
    lastSpacing = spacing
    var actualIndexes = [Int]()
    var j = 0
    while j < chart.xVector.count {
      actualIndexes.append(j)
      j += lastSpacing
    }
    lastActualIndexes = actualIndexes
    let timeStamps = actualIndexes.map{chart.xVector[$0]}
    let strings = timeStamps.map{chartLabelFormatterService.prettyDateString(from: $0)}
    
    var guideLayers = [GuideLabel]()
    for i in 0..<strings.count {
      let textL = textLayer(origin: CGPoint(x: drawings.xPositions[lastActualIndexes[i]], y: chartBounds.origin.y + chartBounds.height + 5 /*+ heightForGuideLabels / 2*/), text: strings[i], color: axisLabelColor)
      guideLayers.append(GuideLabel(textLayer: textL, indexInChart: lastActualIndexes[i]))
      layer.addSublayer(textL)
    }
    activeGuideLabels = guideLayers
  }
  
  private var lastSpacing: Int!
  private var lastActualIndexes: [Int]!
  private var lastLeftover: CGFloat! {
    didSet {
      guard oldValue != nil else {
        return
      }
      if (oldValue > 0 && oldValue < 0.5 && (lastLeftover <= 1 || lastLeftover >= 0.5)) ||
        (oldValue > 0.5 && oldValue < 1 && (lastLeftover <= 0.5 || lastLeftover >= 0)) {
        removeTransitioningGuideLabels()
      }
    }
  }

  
  private func animateGuideLabelsChange(from fromRange: ClosedRange<Int>, to toRange: ClosedRange<Int>, event: DisplayRangeChangeEvent) {
    //TODO: TRANSITIONING SHIT IS SHOWING EXTRA LABELS! BUT U CANT SEE COS THEY HAVE ALPHA
    let (spacing, leftover) = chart.labelSpacing(for: toRange.distance + 1)
    lastLeftover = leftover
    if lastSpacing != spacing {
      removeActiveGuideLabels()
      
      if spacing < lastSpacing {
        removeTransitioningGuideLabels()

        var actualIndexes = [Int]()
        var i = 0
        while i < chart.xVector.count {
          actualIndexes.append(i)
          i += spacing
        }
        actualIndexes.append(contentsOf: lastActualIndexes)
        actualIndexes = Array(Set(actualIndexes)).sorted()
        lastActualIndexes = actualIndexes
      } else {
        var actualIndexes = [Int]()
        var i = lastSpacing!
        while i < chart.xVector.count {
          actualIndexes.append(i)
          i += spacing
        }
        lastActualIndexes.removeAll { elem -> Bool in
          actualIndexes.contains(elem)
        }
      }
      lastSpacing = spacing
      let timeStamps = lastActualIndexes.map{chart.xVector[$0]}
      let strings = timeStamps.map{chartLabelFormatterService.prettyDateString(from: $0)}
      
      var guideLayers = [GuideLabel]()
      for i in 0..<strings.count {
        let textL = textLayer(origin: CGPoint(x: drawings.xPositions[lastActualIndexes[i]], y: chartBounds.origin.y + chartBounds.height + 5/* + heightForGuideLabels / 2*/), text: strings[i], color: axisLabelColor)
        guideLayers.append(GuideLabel(textLayer: textL, indexInChart: lastActualIndexes[i]))
        layer.addSublayer(textL)
      }
      activeGuideLabels = guideLayers
    } else {
      if transitioningGuideLabels == nil {
        if leftover > 0.5 && leftover < 1 {
          var actualIndexes = [Int]()
          var i = 0
          while i < chart.xVector.count {
            actualIndexes.append(i)
            i += spacing * 2
          }
          
          var currentIndexes = activeGuideLabels.map{$0.indexInChart}
          currentIndexes.removeAll { currentIndex -> Bool in
            actualIndexes.contains(currentIndex)
          }
          
          let timeStamps = currentIndexes.map{chart.xVector[$0]}
          let strings = timeStamps.map{chartLabelFormatterService.prettyDateString(from: $0)}
          var transitioningLabels = [GuideLabel]()
          for i in 0..<currentIndexes.count {
            let textL = textLayer(origin: CGPoint(x: drawings.xPositions[currentIndexes[i]], y: chartBounds.origin.y + chartBounds.height + 5/* + heightForGuideLabels / 2*/), text: strings[i], color: axisLabelColor)
            transitioningLabels.append(GuideLabel(textLayer: textL, indexInChart: currentIndexes[i]))
            textL.opacity = Float((1.0 - leftover) * 2.0)
            layer.addSublayer(textL)
          }
          transitioningGuideLabels = transitioningLabels
        } else if leftover < 0.5 && leftover > 0 {
          var actualIndexes = [Int]()
          var i = 0
          while i < chart.xVector.count {
            actualIndexes.append(i)
            i += spacing / 2
          }
          let timeStamps = actualIndexes.map{chart.xVector[$0]}
          let strings = timeStamps.map{chartLabelFormatterService.prettyDateString(from: $0)}
          
          var transitioningLabels = [GuideLabel]()
          for i in 0..<actualIndexes.count {
            let textL = textLayer(origin: CGPoint(x: drawings.xPositions[actualIndexes[i]], y: chartBounds.origin.y + chartBounds.height + 5/* + heightForGuideLabels / 2*/), text: strings[i], color: axisLabelColor)
            transitioningLabels.append(GuideLabel(textLayer: textL, indexInChart: actualIndexes[i]))
            textL.opacity = Float(1.0 - leftover)/2.0
            layer.addSublayer(textL)
          }
          transitioningGuideLabels = transitioningLabels
        }
      }
      
    }
    
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for guideLabel in activeGuideLabels {
      guideLabel.textLayer.frame.origin = CGPoint(x: drawings.xPositions[guideLabel.indexInChart], y: guideLabel.textLayer.frame.origin.y)
      //        guideLabel.textLayer.opacity = Float(leftover/2)
    }
    if transitioningGuideLabels != nil {
      for guideLabel in transitioningGuideLabels {
        guideLabel.textLayer.frame.origin = CGPoint(x: drawings.xPositions[guideLabel.indexInChart], y: guideLabel.textLayer.frame.origin.y)
        //        guideLabel.textLayer.opacity = Float(leftover/2)
      }
    }
    CATransaction.commit()

    if event != .Scaled {
      self.transitioningGuideLabels?.forEach{$0.textLayer.opacity = 0}
    } else {
      let coef: CGFloat = (leftover > 0.5 && leftover < 1.0) ? 2 : 0.5
      self.transitioningGuideLabels?.forEach{$0.textLayer.opacity = Float((1.0 - leftover) * coef)}
    }
  }

  
  // MARK: - Support axis
  
  private let capHeightMultiplierForAxis: CGFloat = 0.85
  
  private var supportAxisDefaultYPositions: [CGFloat]!
  private var labelTextsForCurrentYRange: [String]!
  
  private func addZeroAxis() {
    let zposition = chartBounds.origin.y + chartBounds.height
    let zline = bezierLine(from: CGPoint(x: bounds.origin.x, y: zposition), to: CGPoint(x: bounds.origin.x + bounds.width, y: zposition))
    let zshapeL = shapeLayer(withPath: zline.cgPath, color: axisColor, lineWidth: 0.5)
    zshapeL.opacity = 1
    let text = chartLabelFormatterService.prettyValueString(from: currentYValueRange.lowerBound)
    let ztextL = textLayer(origin: CGPoint(x: bounds.origin.x, y: zposition - 20), text: text, color: axisLabelColor)
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
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: position), to: CGPoint(x: bounds.origin.x + bounds.width, y: position))
      let shapeL = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      shapeL.opacity = 0.75
      shapeL.zPosition = zPositions.Chart.axis.rawValue
      let textL = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: labelTextsForCurrentYRange[i], color: axisLabelColor)
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
    
    //TODO: Doesnt repect the starts from zero stuff. to do it should be line specific coefficient
    let coefficient: CGFloat = newRange.upperBound / previousRange.upperBound
    let isZero = coefficient == 0
    let isInf = coefficient == CGFloat.infinity
    var blocks = [()->()]()
    var removalBlocks = [()->()]()
    var newAxis = [SupportAxis]()
    
    for i in 0..<supportAxis.count {
      let ax = supportAxis[i]
      
      let newLinePosition = CGPoint(x: ax.lineLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - ax.lineLayer.position.y) / coefficient)
      let newTextPosition = CGPoint(x: ax.labelLayer.position.x, y: chartBounds.origin.y + chartBounds.height - (chartBounds.origin.y + chartBounds.height - ax.labelLayer.position.y) / coefficient)
      
      
      let position = supportAxisDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: position), to: CGPoint(x: bounds.origin.x + bounds.width, y: position))
      let shapeL = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: 0.5)
      let textL = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: labelTextsForCurrentYRange[i], color: axisLabelColor)
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
  
  private func textLayer(origin: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = "Helvetica" as CFTypeRef
    textLayer.fontSize = 13.0
    textLayer.string = text
    textLayer.frame = CGRect(origin: origin, size: CGSize(width: 100, height: heightForGuideLabels))
    textLayer.contentsScale = UIScreen.main.scale
    textLayer.foregroundColor = color
    return textLayer
  }
  
  private func textLayer(position: CGPoint, text: String, color: CGColor) -> CATextLayer {
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
    let translatedToDisplayRange = (CGFloat(currentXIndexRange.upperBound) - CGFloat(currentXIndexRange.lowerBound)) * (xPositionInChartBounds / chartBounds.width) + CGFloat(currentXIndexRange.lowerBound)
    return Int(round(translatedToDisplayRange))
  }
  
  private func addChartAnnotation(for index: Int) {
    let xPoint = drawings.xPositions[index]
    var circleLayers = [CAShapeLayer]()
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector[index])/1000)

    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let point = CGPoint(x: xPoint, y: drawing.yPositions[index])
      
      let circle = bezierCircle(at: point, radius: circlePointRadius)
      let circleShape = shapeLayer(withPath: circle.cgPath, color: chart.yVectors[i].metaData.color.cgColor, lineWidth: graphLineWidth, fillColor: circlePointFillColor)
      circleShape.zPosition = zPositions.Annotation.circleShape.rawValue
      circleLayers.append(circleShape)
      if hiddenDrawingIndicies.contains(i) {
        circleShape.opacity = 0
        continue
      } else {
        circleShape.opacity = 1
      }
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
  
  private func moveChartAnnotation(to index: Int, animated: Bool = false) {
    guard let annotation = currentChartAnnotation else {
      return
    }
    let xPoint = drawings.xPositions[index]
    
    var coloredValues = [(CGFloat, UIColor)]()
    let date = Date(timeIntervalSince1970: TimeInterval(chart.xVector[index])/1000)
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let point = CGPoint(x: xPoint, y: drawing.yPositions[index])
      let circle = bezierCircle(at: point, radius: circlePointRadius)
      let circleLayer = annotation.circleLayers[i]
      
      if animated {
        var oldPath: Any?
        var oldOpacity: Any?
        if let _ = circleLayer.animation(forKey: "circleGrpAnimation") {
          oldPath = circleLayer.presentation()?.value(forKey: "path")
          oldOpacity = circleLayer.presentation()?.value(forKey: "opacity")
          circleLayer.removeAnimation(forKey: "circleGrpAnimation")
        }
        
        let pathAnim = CABasicAnimation(keyPath: "path")
        pathAnim.fromValue = oldPath ?? circleLayer.path
        circleLayer.path = circle.cgPath
        pathAnim.toValue = circleLayer.path

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = oldOpacity ?? circleLayer.opacity
        circleLayer.opacity = hiddenDrawingIndicies.contains(i) ? 0 : 1
        opacityAnim.toValue = circleLayer.opacity
        
        let grp = CAAnimationGroup()
        grp.duration = 0.25
        grp.animations = [pathAnim, opacityAnim]
        circleLayer.add(grp, forKey: "circleGrpAnimation")
        
      } else {
        circleLayer.path = circle.cgPath
        circleLayer.opacity = hiddenDrawingIndicies.contains(i) ? 0 : 1
      }
      
      if !hiddenDrawingIndicies.contains(i) {
        coloredValues.append((chart.yVectors[i].vector[index], chart.yVectors[i].metaData.color))
      }
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
  
  // MARK: - Reset
  
  private func reset() {
    self.chart = nil
    removeDrawings()
    removeAxis()
    removeGuideLabels()
    self.hiddenDrawingIndicies = nil
    removeChartAnnotation()
    currentYValueRange = 0...0
    //do not reset x range
  }
  private func removeDrawings() {
    self.drawings?.drawings.forEach{$0.shapeLayer.removeFromSuperlayer()}
    self.drawings = nil
  }
  
  private func removeAxis() {
    removeZeroAxis()
    removeSupportAxis()
  }
  
  private func removeZeroAxis() {
    self.zeroAxis?.labelLayer.removeFromSuperlayer()
    self.zeroAxis?.lineLayer.removeFromSuperlayer()
    self.zeroAxis = nil
  }
  
  private func removeSupportAxis() {
    self.supportAxis?.forEach{
      $0.labelLayer.removeFromSuperlayer()
      $0.lineLayer.removeFromSuperlayer()
    }
    self.supportAxis = nil
  }
  
  private func removeGuideLabels() {
    removeActiveGuideLabels()
    removeTransitioningGuideLabels()
  }
  
  private func removeActiveGuideLabels() {
    self.activeGuideLabels?.forEach{$0.textLayer.removeFromSuperlayer()}
    self.activeGuideLabels = nil
  }
  
  private func removeTransitioningGuideLabels() {
    self.transitioningGuideLabels?.forEach{$0.textLayer.removeFromSuperlayer()}
    self.transitioningGuideLabels = nil
  }
  
  private func removeChartAnnotation() {
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
  
  private struct ChartDrawings {
    let drawings: [Drawing]
    let xPositions: [CGFloat]
  }
  
  private struct Drawing {
    let identifier: String
    let shapeLayer: CAShapeLayer
    let yPositions: [CGFloat]
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
  
  private struct GuideLabel {
    let textLayer: CATextLayer
    let indexInChart: Int
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
      //annotation
      self.currentChartAnnotation?.circleLayers.forEach{$0.fillColor = circlePointFillColor}
      self.currentChartAnnotation?.lineLayer.strokeColor = axisColor

      //axis
      self.supportAxis?.forEach{
        $0.lineLayer.strokeColor = axisColor
        $0.labelLayer.foregroundColor = axisLabelColor
      }
      self.zeroAxis?.labelLayer.foregroundColor = axisLabelColor
      self.zeroAxis?.lineLayer.strokeColor = axisColor
      
      //guide labels
      self.activeGuideLabels?.forEach{$0.textLayer.foregroundColor = axisLabelColor}
      self.transitioningGuideLabels?.forEach{$0.textLayer.foregroundColor = axisLabelColor}
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
