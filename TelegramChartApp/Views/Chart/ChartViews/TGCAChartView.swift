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
  
  var onRangeChange: ((_ left: Date?, _ right: Date?) -> ())?
  var onAnnotationClick: ((_ date: Date) -> (Bool))?
  
  @IBOutlet var contentView: UIView!
  
  var axisColor = UIColor.gray.cgColor
  var axisLabelColor = UIColor.black.cgColor
  var circlePointFillColor = UIColor.white.cgColor
  
  struct ChartViewConstants {
    static let axisLineWidth: CGFloat = 0.5
    static let annotationLineWidth: CGFloat = 1.0
    static let sizeForGuideLabels = CGSize(width: 60.0, height: 20.0)
    static let circlePointRadius: CGFloat = 4.0
    static let guideLabelsFont = "Helvetica" as CFTypeRef
    static let guideLabelsFontSize: CGFloat = 12
    static let contentScaleForShapes: CGFloat = 1.0
    static let contentScaleForText = UIScreen.main.scale
    /// The axes are drawn from the bottom of the bounds to the top of the bounds, capped by this value.
    static let capHeightMultiplierForHorizontalAxes: CGFloat = 0.85
  }
  
  let axisLayer = CALayer()
  let lineLayer = CALayer()
  let datesLayer = CALayer()
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  func commonInit () {
    Bundle.main.loadNibNamed("TGCAChartView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    isMultipleTouchEnabled = false
    applyCurrentTheme()
    axisLayer.zPosition = zPositions.Chart.axis.rawValue
    lineLayer.zPosition = zPositions.Chart.graph.rawValue
    datesLayer.zPosition = zPositions.Chart.dates.rawValue
    for l in [axisLayer, lineLayer, datesLayer] {
      layer.addSublayer(l)
    }
//    lineLayer.masksToBounds = true

  }
  
  // MARK: - Variables
  
  /// Need to redraw the chart when the bounds did change.
  override var bounds: CGRect {
    didSet {
      numOfGuideLabels = Int(bounds.width / ChartViewConstants.sizeForGuideLabels.width)
      if chart != nil {
        configure(with: chart, hiddenIndicies: hiddenDrawingIndicies)
      }
    }
  }
  
  /// Service that knows how to format values for Y axes and dates for X axis.
  let chartLabelFormatterService = TGCAChartLabelFormatterService()
  
  var graphLineWidth: CGFloat = 2.0
  
  var shouldDisplayAxesAndLabels = false
  
  /// If true, than when after some graph was hidden and the local maximum Y has changed, the chart would animate its position relative to the new maximum. If false, it will just fade.
  var animatesPositionOnHide = true
  
  /// If true than the minimum Y value would always be zero
  var valuesStartFromZero = true
  
  var canShowAnnotations = true
  
  
  /// Number of horizontal axes that should be shown on screen. Doesnt include zero axis
  let numOfHorizontalAxes = 6
  
  /// Maximum number of guide labels that should be visible on the screen
  var numOfGuideLabels = 6
  
  /// The rect in which the chart drawing is happening
  var chartBounds: CGRect = CGRect.zero {
    didSet {
      chartBoundsRight = chartBounds.origin.x + chartBounds.width
      chartBoundsBottom = chartBounds.origin.y + chartBounds.height
    }
  }
  var chartBoundsBottom: CGFloat = 0
  var chartBoundsRight: CGFloat = 0
  
  var chart: DataChart!
  var underlyingChart: DataChart?
  var drawings: ChartDrawings!
  
  /// Contains indicies of the hidden charts
  var hiddenDrawingIndicies: Set<Int>!
  
  private var horizontalAxes: [HorizontalAxis]!
  var horizontalAxesSpacing: CGFloat!

  var horizontalAxesDefaultYPositions: [CGFloat]!
  
  var currentChartAnnotation: ChartAnnotationProtocol?
  
  /// Guide labels that are currently shown
  var activeGuideLabels: [GuideLabel]!
  
  /// Guide labels that are currently in fading animation
  var transitioningGuideLabels: [GuideLabel]!
  
  /// Range of X values that is curently diplayed
  var currentXIndexRange: ClosedRange<Int>! {
    didSet {
      guard onRangeChange != nil else {
        return
      }
      if currentXIndexRange == nil {
        onRangeChange?(nil, nil)
      } else {
        let datesVector = chart.datesVector
        onRangeChange?(datesVector[currentXIndexRange.lowerBound], datesVector[currentXIndexRange.upperBound])
      }
    }
  }
  
  /// Range between total min and max Y of currently visible charts
  private(set) var currentYValueRange: ClosedRange<CGFloat> = 0...0
  
  private func updateCurrentYValueRange(with newRange: ClosedRange<CGFloat>) -> YRangeChangeResult {
    guard newRange != currentYValueRange else {
      return YRangeChangeResult(didChange: false)
    }
    currentYValueRange = newRange
    if horizontalAxes != nil {
      var animBlocks = [()->()]()
      var removalBlocks = [()->()]()
      
      let blocks = updateHorizontalAxes()
      animBlocks.append(contentsOf: blocks.animationBlocks)
      removalBlocks.append(contentsOf: blocks.removalBlocks)
      
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
    return YRangeChangeResult(didChange: true)
  }

  // MARK: - Public functions
  
  func reset() {
    chart = nil
    removeDrawings()
    removeHorizontalAxes()
    removeGuideLabels()
    removeChartAnnotation()
    currentYValueRange = 0...0
    hiddenDrawingIndicies = nil
    currentXIndexRange = nil
  }

  /// Configures the view to display the chart.
  func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: ClosedRange<CGFloat>? = nil) {
    reset()
    configure()

    self.chart = chart
    hiddenDrawingIndicies = hiddenIndicies
    
    var curXRange = currentXIndexRange ?? 0...chart.xVector.count-1
    if let dR = displayRange {
      curXRange = chart.translatedBounds(for: dR)
    }
    currentXIndexRange = curXRange
    
    drawChart()
    
    if shouldDisplayAxesAndLabels  {
      addHorizontalAxes()
      addGuideLabels()
    }
  }
  
  func transitionToMainChart() {
    
    
    
    
    underlyingChart = nil
  }
  
  func transitionToUnderlyingChart(_ underlyingChart: DataChart, displayRange: ClosedRange<CGFloat>? = nil) {
    self.underlyingChart = underlyingChart
    removeChartAnnotation()
    configure(with: underlyingChart, hiddenIndicies: hiddenDrawingIndicies, displayRange: displayRange)
    
  }
  
  /// Updates the diplayed X range. Accepted are subranges of 0...1.
  func trimDisplayRange(to newRange: ClosedRange<CGFloat>, with event: DisplayRangeChangeEvent) {
    trimXDisplayRange(to: chart.translatedBounds(for: newRange), with: event)
  }
  
  private func trimXDisplayRange(to newRange: ClosedRange<Int>, with event: DisplayRangeChangeEvent) {
    
    removeChartAnnotation()
    
    if currentXIndexRange == newRange {
      if event == .Ended {
        removeTransitioningGuideLabels()
      }
      return
    }
    
    currentXIndexRange = newRange
    
    updateChart()
    
    animateGuideLabelsChange(to: newRange, event: event)
  }
  
  func hideAll() {
    //TODO: optimize and hide labels and axis
    for i in 0..<chart.yVectors.count {
      if !hiddenDrawingIndicies.contains(i) {
        toggleHidden(at: i)
      }
    }
  }
  
  func showAll() {
    //TODO: optimize and hide labels and axis
    for i in hiddenDrawingIndicies {
      toggleHidden(at: i)
    }
  }
  
  /// Hides or shows the graph with identifier.
  func toggleHidden(identifier: String) {
    if let index = chart.indexOfChartValueVector(withId: identifier) {
      toggleHidden(at: index)
    }
  }
  
  /// Hides or shows the graph at index.
  func toggleHidden(at index: Int) {
    
    let originalHidden = hiddenDrawingIndicies.contains(index)
    if originalHidden {
      hiddenDrawingIndicies.remove(index)
    } else {
      hiddenDrawingIndicies.insert(index)
    }
    
    updateChartByHiding(at: index, originalHidden: originalHidden)
    
    if let annotation = currentChartAnnotation {
      if hiddenDrawingIndicies.count == chart.yVectors.count {
        removeChartAnnotation()
      } else {
        moveChartAnnotation(to: annotation.displayedIndex, animated: true)
      }
    }
  }
  
  // MARK: - Methods to subclass
  
  func prepareToDrawChart() { }
  
  func getCurrentVectorData() -> VectorDataProtocol {
    let normalizedYVectors = getNormalizedYVectors()
    let yVectors = normalizedYVectors.vectors.map{mapToChartBoundsHeight($0)}
    let xVector = mapToChartBoundsWidth(getNormalizedXVector())
    let points = (0..<yVectors.count).map{
      convertToPoints(xVector: xVector, yVector: yVectors[$0])
    }
    return VectorData(xVector: xVector, yVectors: yVectors, yRangeData: YRangeData(yRange: normalizedYVectors.yRange), points: points)
  }
  
  func updateYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResultProtocol? {
    guard let yRangeData = yRangeData as? YRangeData else {
      return nil
    }
    return updateCurrentYValueRange(with: yRangeData.yRange)
  }
  
  func getPathsToDraw(with vectorData: VectorDataProtocol) -> [CGPath] {
    let vectorData = vectorData as! VectorData
    return vectorData.points.map{bezierLine(withPoints: $0).cgPath}
  }
  
  func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      shapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor, lineWidth: graphLineWidth)
    }
  }
  
  func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.forEach{
      lineLayer.addSublayer($0)
    }
  }
  
  func animateChartUpdate(withYChangeResult yChangeResult: YRangeChangeResultProtocol?, paths: [CGPath]) {
    let didYChange = (yChangeResult as? YRangeChangeResult)?.didChange ?? false
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      if let oldAnim = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = drawing.shapeLayer.presentation()?.value(forKey: "path") ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = paths[i]
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        if !didYChange {
          pathAnimation.beginTime = oldAnim.beginTime
        } else {
          pathAnimation.beginTime = CACurrentMediaTime()
        }
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      } else {
        if didYChange  {
          let pathAnimation = CABasicAnimation(keyPath: "path")
          pathAnimation.fromValue = drawing.shapeLayer.path
          drawing.shapeLayer.path = paths[i]
          pathAnimation.toValue = drawing.shapeLayer.path
          pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
          pathAnimation.beginTime = CACurrentMediaTime()
          drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
        } else {
          drawing.shapeLayer.path = paths[i]
        }
      }
    }
    
  }
  
  func prepareToUpdateChartByHiding() {}
  
  func animateChartHide(at index: Int, originalHidden: Bool, newPaths: [CGPath]) {
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      
      var oldPath: Any?
      if let _ = drawing.shapeLayer.animation(forKey: "pathAnimation") {
        oldPath = drawing.shapeLayer.presentation()?.value(forKey: "path")
        drawing.shapeLayer.removeAnimation(forKey: "pathAnimation")
      }
      
      let positionChangeBlock = {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = oldPath ?? drawing.shapeLayer.path
        drawing.shapeLayer.path = newPaths[i]
        pathAnimation.toValue = drawing.shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        drawing.shapeLayer.add(pathAnimation, forKey: "pathAnimation")
      }
      
      if animatesPositionOnHide {
        positionChangeBlock()
      } else {
        if !hiddenDrawingIndicies.contains(i) && !(originalHidden && i == index) {
          positionChangeBlock()
        }
        if (originalHidden && i == index) {
          drawing.shapeLayer.path = newPaths[i]
        }
      }
      
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
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        drawing.shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  //MARK: - Chart
  
  private func drawChart() {
    prepareToDrawChart()
    let vectorData = getCurrentVectorData()
    _ = updateYValueRange(with: vectorData.yRangeData)
    let pathsToDraw = getPathsToDraw(with: vectorData)
    let shapesToDraw = getShapeLayersToDraw(for: pathsToDraw)

    var draws = [Drawing]()
    for i in 0..<shapesToDraw.count {
      let shape = shapesToDraw[i]
      if hiddenDrawingIndicies.contains(i) {
        shape.opacity = 0
      }
      draws.append(Drawing(shapeLayer: shape, yPositions: vectorData.yVectors[i]))
    }
    drawings = ChartDrawings(drawings: draws, xPositions: vectorData.xVector)
    
    addShapeSublayers(shapesToDraw)
  }
  
  private func updateChart() {
    let vectorData = getCurrentVectorData()
    let yChangeResult = updateYValueRange(with: vectorData.yRangeData)
    let pathsToDraw = getPathsToDraw(with: vectorData)

    animateChartUpdate(withYChangeResult: yChangeResult, paths: pathsToDraw)
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      drawing.yPositions = vectorData.yVectors[i]
    }
    drawings.xPositions = vectorData.xVector
  }
  
  private func updateChartByHiding(at index: Int, originalHidden: Bool) {
    prepareToUpdateChartByHiding()
    let vectorData = getCurrentVectorData()
    _ = updateYValueRange(with: vectorData.yRangeData)
    let pathsToDraw = getPathsToDraw(with: vectorData)
    
    animateChartHide(at: index, originalHidden: originalHidden, newPaths: pathsToDraw)
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      drawing.yPositions = vectorData.yVectors[i]
    }
  }
  
  // MARK: - Configuration
  
  private func configure() {
    configureChartBounds()
    configureHorizontalAxesSpacing()
    configureHorizontalAxesDefaultPositions()
  }
  
  private func configureChartBounds() {
    // We need to inset drawing so that if the edge points are selected, the circular point on the graph is fully visible in the view
    let inset = graphLineWidth + (canShowAnnotations ? ChartViewConstants.circlePointRadius : 0)
    chartBounds = CGRect(x: bounds.origin.x + inset,
                         y: bounds.origin.y + inset,
                         width: bounds.width - inset * 2,
                         height: bounds.height - inset * 2
                          - (shouldDisplayAxesAndLabels ? ChartViewConstants.sizeForGuideLabels.height : 0))
  }
  
  private func configureHorizontalAxesSpacing() {
    horizontalAxesSpacing = chartBounds.height * ChartViewConstants.capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes - 1)
  }
  
  private func configureHorizontalAxesDefaultPositions() {
    horizontalAxesDefaultYPositions = (0..<numOfHorizontalAxes).map{chartBoundsBottom - (CGFloat($0) * horizontalAxesSpacing)}
  }
  
  // MARK: - Guide Labels
  
  func addGuideLabels() {
    
    let (spacing, leftover) = bestIndexSpacing(for: currentXIndexRange.distance + 1)
    lastLeftover = leftover
    lastSpacing = spacing
    var actualIndexes = [Int]()
    var j = 0
    while j < chart.xVector.count {
      actualIndexes.append(j)
      j += lastSpacing
    }
    lastActualIndexes = actualIndexes
    
    let newActiveGuideLabels = generateGuideLabels(for: lastActualIndexes)
    newActiveGuideLabels.forEach{
      datesLayer.addSublayer($0.textLayer)
    }
    activeGuideLabels = newActiveGuideLabels
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
  
  private func animateGuideLabelsChange(to toRange: ClosedRange<Int>, event: DisplayRangeChangeEvent) {
  
    if event != .Scrolled {
      let (spacing, leftover) = bestIndexSpacing(for: toRange.distance + 1)
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
        
        let newActiveGuideLabels = generateGuideLabels(for: lastActualIndexes)
        newActiveGuideLabels.forEach{
          datesLayer.addSublayer($0.textLayer)
        }
        activeGuideLabels = newActiveGuideLabels
        
      }
      if transitioningGuideLabels == nil {
        if leftover < 0.5 && leftover > 0 {
          var actualIndexes = [Int]()
          var i = 0
          while i < chart.xVector.count {
            actualIndexes.append(i)
            i += spacing / 2
          }
          
          let currentIndexes = activeGuideLabels.map{$0.indexInChart}
          actualIndexes.removeAll { actualIndex -> Bool in
            currentIndexes.contains(actualIndex)
          }
          
          let newTransitioningLabels = generateGuideLabels(for: actualIndexes)
          newTransitioningLabels.forEach{
            $0.textLayer.opacity = Float(1.0 - leftover)/2.0
            datesLayer.addSublayer($0.textLayer)
          }
          transitioningGuideLabels = newTransitioningLabels
        }
      }
      
      if event == .Scaled {
        let coef: CGFloat = (leftover > 0.5 && leftover < 1.0) ? 2 : 0.5
        transitioningGuideLabels?.forEach{$0.textLayer.opacity = Float((1.0 - leftover) * coef)}
      } else {
        transitioningGuideLabels?.forEach{$0.textLayer.opacity = 0}
      }
      
    }
    
    CATransaction.begin()
    // position is animated by default but we dont want it
    CATransaction.setDisableActions(true)
    activeGuideLabels?.forEach{
      $0.textLayer.frame.origin = CGPoint(x: drawings.xPositions[$0.indexInChart], y: $0.textLayer.frame.origin.y)
    }
    transitioningGuideLabels?.forEach{
      $0.textLayer.frame.origin = CGPoint(x: drawings.xPositions[$0.indexInChart], y: $0.textLayer.frame.origin.y)
    }
    CATransaction.commit()
    
  }
  
  private func generateGuideLabels(for xIndexes: [Int]) -> [GuideLabel] {
    
    let dates = xIndexes.map{chart.datesVector[$0]}
    let strings = dates.map{chartLabelFormatterService.prettyDateString(from: $0)}
    
    var labels = [GuideLabel]()
    for i in 0..<xIndexes.count {
      let textL = textLayer(origin: CGPoint(x: drawings.xPositions[xIndexes[i]], y: chartBoundsBottom + 5/* + heightForGuideLabels / 2*/), text: strings[i], color: axisLabelColor)
      labels.append(GuideLabel(textLayer: textL, indexInChart: xIndexes[i]))
    }
    return labels
  }
  
  // MARK: - Horizontal axes
  
  typealias AxisAnimationBlocks = (animationBlocks: [()->()], removalBlocks: [()->()])
  
  private func valuesForAxes() -> [CGFloat] {
    let distanceInYRange = currentYValueRange.upperBound - currentYValueRange.lowerBound
    let distanceInBounds = ChartViewConstants.capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes-1)
    var retVal = [currentYValueRange.lowerBound]
    for i in 1..<numOfHorizontalAxes {
      retVal.append((distanceInYRange * distanceInBounds * CGFloat(i)) + currentYValueRange.lowerBound)
    }
    return retVal
  }

  func addHorizontalAxes() {
    
    let boundsRight = bounds.origin.x + bounds.width
    
    let values = valuesForAxes()
    let texts = values.map{chartLabelFormatterService.prettyValueString(from: $0)}
    
    var newAxis = [HorizontalAxis]()
    
    for i in 0..<horizontalAxesDefaultYPositions.count {
      let position = horizontalAxesDefaultYPositions[i]
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: 0), to: CGPoint(x: boundsRight, y: 0))
      let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.axisLineWidth)
      lineLayer.position.y = position
      let labelLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[i], color: axisLabelColor)
      labelLayer.alignmentMode = .left
      axisLayer.addSublayer(lineLayer)
      axisLayer.addSublayer(labelLayer)
      newAxis.append(HorizontalAxis(lineLayer: lineLayer, labelLayer: labelLayer, value: values[i]))
    }
    horizontalAxes = newAxis
  }
  
  func updateHorizontalAxes() -> AxisAnimationBlocks{
    let boundsRight = bounds.origin.x + bounds.width

    let values = valuesForAxes()
    let texts = values.map{chartLabelFormatterService.prettyValueString(from: $0)}
  
    //diffs between new values and old values
    let diffs: [CGFloat] = zip(values, horizontalAxes.map{$0.value}).map{ arg in
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
    
    if diffs[0] != 0 {
      //update zero axis without line animation
      let ax = horizontalAxes[0]
      let position = horizontalAxesDefaultYPositions[0]
      let oldTextLayerTargetPosition = CGPoint(x: ax.labelLayer.position.x, y: ax.labelLayer.position.y + diffs[0])
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[0], color: axisLabelColor)
      newTextLayer.opacity = 0
      axisLayer.addSublayer(newTextLayer)
      let oldTextPos = newTextLayer.position
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: newTextLayer.position.y - diffs[0])
      
      let oldLabelLayer = ax.labelLayer
      
      blocks.append {
        oldLabelLayer.position = oldTextLayerTargetPosition
        oldLabelLayer.opacity = 0
        newTextLayer.position = oldTextPos
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        oldLabelLayer.removeFromSuperlayer()
      }
      ax.update(labelLayer: newTextLayer, value: values[0])
    }
    
    for i in 1..<horizontalAxes.count {
      let ax = horizontalAxes[i]
      
      //no need to check for diff == 0 because its impossible
      
      let position = horizontalAxesDefaultYPositions[i]

      let oldLineLayerTargetPosition = CGPoint(x: ax.lineLayer.position.x, y: ax.lineLayer.position.y + diffs[i])
      let oldTextLayerTargetPosition = CGPoint(x: ax.labelLayer.position.x, y: ax.labelLayer.position.y + diffs[i])
      
      let line = bezierLine(from: CGPoint(x: bounds.origin.x, y: 0), to: CGPoint(x: boundsRight, y: 0))
      let newLineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.axisLineWidth)
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[i], color: axisLabelColor)
      newTextLayer.opacity = 0
      newLineLayer.opacity = 0
      axisLayer.addSublayer(newLineLayer)
      newLineLayer.position.y = position
      axisLayer.addSublayer(newTextLayer)
      let oldShapePos = newLineLayer.position
      let oldTextPos = newTextLayer.position
      newLineLayer.position = CGPoint(x: newLineLayer.position.x, y: newLineLayer.position.y - diffs[i])
      newTextLayer.position = CGPoint(x: newTextLayer.position.x, y: newTextLayer.position.y - diffs[i])
      
      let oldLabelLayer = ax.labelLayer
      let oldLineLayer = ax.lineLayer
      
      ax.update(lineLayer: newLineLayer, labelLayer: newTextLayer, value: values[i])
      
      blocks.append {
        oldLabelLayer.position = oldTextLayerTargetPosition
        oldLabelLayer.opacity = 0
        oldLineLayer.opacity = 0
        oldLineLayer.position = oldLineLayerTargetPosition
        
        newLineLayer.opacity = 1.0
        newLineLayer.position = oldShapePos
        newTextLayer.position = oldTextPos
        newTextLayer.opacity = 1.0
      }
      removalBlocks.append {
        oldLabelLayer.removeFromSuperlayer()
        oldLineLayer.removeFromSuperlayer()
      }
    }
    
    return (blocks, removalBlocks)
  }
  
  // MARK: - Annotation
  func getMaxPossibleLabelsCountForChartAnnotation() -> Int {
    return chart.yVectors.count
  }
  
  func getChartAnnotationViewConfiguration(for index: Int) -> TGCAChartAnnotationView.AnnotationViewConfiguration {
    let includedIndicies = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    var coloredValues: [TGCAChartAnnotationView.ColoredValue] = includedIndicies.map{
      let yVector = chart.yVectors[$0]
      return TGCAChartAnnotationView.ColoredValue(title: yVector.metaData.name, value: yVector.vector[index], color: yVector.metaData.color)
    }
    coloredValues.sort { (left, right) -> Bool in
      return left.value >= right.value
    }
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: true, mode: .Date, showsLeftColumn: false, coloredValues: coloredValues)
  }
  
  func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    
    addSubview(chartAnnotation.annotationView)
    layer.addSublayer(chartAnnotation.lineLayer)
    chartAnnotation.circleLayers.forEach {
      layer.addSublayer($0)
    }
  }
  
  func desiredOriginForChartAnnotationPlacing(chartAnnotation: ChartAnnotationProtocol) -> CGPoint {
    let xPoint = drawings.xPositions[chartAnnotation.displayedIndex]
    let annotationSize = chartAnnotation.annotationView.bounds.size
    
    let xPos = min(bounds.origin.x + bounds.width - annotationSize.width / 2, max(bounds.origin.x + annotationSize.width / 2, xPoint))
    return CGPoint(x: xPos - annotationSize.width / 2, y: bounds.origin.y + 40.0)
  }
  
  func generateChartAnnotation(for index: Int, with annotationView: TGCAChartAnnotationView) -> ChartAnnotationProtocol {
    let xPoint = drawings.xPositions[index]
    var circleLayers = [CAShapeLayer]()
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      let color = chart.yVectors[i].metaData.color
      let point = CGPoint(x: xPoint, y: drawing.yPositions[index])
      let circle = bezierCircle(at: point, radius: ChartViewConstants.circlePointRadius)
      let circleShape = shapeLayer(withPath: circle.cgPath, color: color.cgColor, lineWidth: graphLineWidth, fillColor: circlePointFillColor)
      circleShape.zPosition = zPositions.Annotation.circleShape.rawValue
      circleLayers.append(circleShape)
      if !hiddenDrawingIndicies.contains(i) {
        circleShape.opacity = 1
      } else {
        circleShape.opacity = 0
      }
    }
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotationView.frame.origin.y + annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    let lineLayer = shapeLayer(withPath: line.cgPath, color: axisColor, lineWidth: ChartViewConstants.annotationLineWidth)
    
    lineLayer.zPosition = zPositions.Annotation.lineShape.rawValue
    annotationView.layer.zPosition = zPositions.Annotation.view.rawValue
    
    return ChartAnnotation(lineLayer: lineLayer, annotationView: annotationView, circleLayers: circleLayers, displayedIndex: index)
  }
  
  func performUpdatesForMovingChartAnnotation(to index: Int, with chartAnnotation: ChartAnnotationProtocol, animated: Bool) {
    guard let annotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    
    let xPoint = drawings.xPositions[index]
    
    for i in 0..<drawings.drawings.count {
      let drawing = drawings.drawings[i]
      
      let point = CGPoint(x: xPoint, y: drawing.yPositions[index])
      let circle = bezierCircle(at: point, radius: ChartViewConstants.circlePointRadius)
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
        grp.duration = ANIMATION_DURATION
        grp.animations = [pathAnim, opacityAnim]
        circleLayer.add(grp, forKey: "circleGrpAnimation")
        
      } else {
        circleLayer.path = circle.cgPath
        circleLayer.opacity = hiddenDrawingIndicies.contains(i) ? 0 : 1
      }
      
    }
    
    let line = bezierLine(from: CGPoint(x: xPoint, y: annotation.annotationView.frame.origin.y + annotation.annotationView.frame.height), to: CGPoint(x: xPoint, y: chartBoundsBottom))
    annotation.lineLayer.path = line.cgPath
  }
  
  private func addChartAnnotation(for index: Int) {
    let configuration = getChartAnnotationViewConfiguration(for: index)
    let annotationView = TGCAChartAnnotationView(maxPossibleLabels: getMaxPossibleLabelsCountForChartAnnotation())
    annotationView.configure(with: configuration)
    let chartAnnotation = generateChartAnnotation(for: index, with: annotationView)
    addChartAnnotation(chartAnnotation)
    chartAnnotation.annotationView.frame.origin = desiredOriginForChartAnnotationPlacing(chartAnnotation: chartAnnotation)
    currentChartAnnotation = chartAnnotation
  }
  
  private func moveChartAnnotation(to index: Int, animated: Bool = false) {
    guard let currentChartAnnotation = currentChartAnnotation else {
      return
    }
    let configuration = getChartAnnotationViewConfiguration(for: index)
    currentChartAnnotation.annotationView.configure(with: configuration)
    performUpdatesForMovingChartAnnotation(to: index, with: currentChartAnnotation, animated: animated)
    currentChartAnnotation.annotationView.frame.origin = desiredOriginForChartAnnotationPlacing(chartAnnotation: currentChartAnnotation)
    currentChartAnnotation.updateDisplayedIndex(to: index)
  }
  
  // MARK: - Touches
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return bounds.contains(point) ? self : nil
  }
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return bounds.contains(point)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard canShowAnnotations && hiddenDrawingIndicies.count != chart.yVectors.count else {
      return super.touchesBegan(touches, with: event)
    }
    guard let touchLocation = touches.first?.location(in: self), chartBounds.contains(touchLocation) else {
      return super.touchesBegan(touches, with: event)
    }
    
    let index = closestIndex(for: touchLocation)
    
    if let annotation = currentChartAnnotation {
      if annotation.annotationView.frame.contains(touchLocation) {
        //TODO: DISMISS ANNOTATION ON LONG TAP
        let handled = onAnnotationClick?(chart.datesVector[index]) ?? false
        if !handled {
          removeChartAnnotation()
        }
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
  
  func closestIndex(for touchLocation: CGPoint) -> Int {
    let xPositionInChartBounds = touchLocation.x - chartBounds.origin.x
    let translatedToDisplayRange = (CGFloat(currentXIndexRange.upperBound) - CGFloat(currentXIndexRange.lowerBound)) * (xPositionInChartBounds / chartBounds.width) + CGFloat(currentXIndexRange.lowerBound)
    return Int(round(translatedToDisplayRange))
  }
  
  // MARK: - Reset
  
  func removeDrawings() {
    drawings?.drawings.forEach{$0.shapeLayer.removeFromSuperlayer()}
    drawings = nil
  }
  
  private func removeGuideLabels() {
    removeActiveGuideLabels()
    removeTransitioningGuideLabels()
  }
  
  func removeHorizontalAxes() {
    horizontalAxes?.forEach{
      $0.labelLayer.removeFromSuperlayer()
      $0.lineLayer.removeFromSuperlayer()
    }
    horizontalAxes = nil
  }
  
  func removeActiveGuideLabels() {
    activeGuideLabels?.forEach{$0.textLayer.removeFromSuperlayer()}
    activeGuideLabels = nil
  }
  
  func removeTransitioningGuideLabels() {
    transitioningGuideLabels?.forEach{$0.textLayer.removeFromSuperlayer()}
    transitioningGuideLabels = nil
  }
  
  func removeChartAnnotation() {
    if let annotation = currentChartAnnotation as? ChartAnnotation {
      annotation.lineLayer.removeFromSuperlayer()
      annotation.annotationView.removeFromSuperview()
      for layer in annotation.circleLayers {
        layer.removeFromSuperlayer()
      }
      currentChartAnnotation = nil
    }
  }
  
  // MARK: - Helping functions
  
  func convertToPoints(xVector: [CGFloat], yVector: [CGFloat]) -> [CGPoint] {
    var points = [CGPoint]()
    for i in 0..<xVector.count {
      points.append(CGPoint(x: xVector[i], y: yVector[i]))
    }
    return points
  }
  
  func getNormalizedYVectors() -> NormalizedYVectors{
    return valuesStartFromZero
      ? chart.normalizedYVectorsFromZeroMinimum(in: currentXIndexRange, excludedIdxs: hiddenDrawingIndicies)
      : chart.normalizedYVectorsFromLocalMinimum(in: currentXIndexRange, excludedIdxs: hiddenDrawingIndicies)
  }
  
  func getNormalizedXVector() -> ValueVector {
    return chart.normalizedXVector(in: currentXIndexRange)
  }
  
  func mapToChartBoundsWidth(_ vector: ValueVector) -> ValueVector {
    return vector.map{$0 * chartBoundsRight + chartBounds.origin.x}
  }
  
  func mapToChartBoundsHeight(_ vector: ValueVector) -> ValueVector {
    return vector.map{chartBoundsBottom - ($0 * chartBounds.height)}
  }
  
  /// Calculates what is the best "power of two" for the provided count, depending on the max number of labels that fit the screen. Leftover is how far am I to the point, where the best index would change. < 0.5 is changing towards smaller spacing. >0.5 changing towards higher spacing.
  func bestIndexSpacing(for indexCount: Int) -> (spacing: Int, leftover: CGFloat) {
    var i = 1
    while i * numOfGuideLabels < indexCount {
      i *= 2
    }
    let extra = indexCount % ((i / 2) * numOfGuideLabels)
    let higherBound = i * numOfGuideLabels
    let leftover = 2.0 * CGFloat(extra) / CGFloat(higherBound)
    return (i, leftover)
  }
  
  // MARK: - Drawing
  
  func bezierLine(withPoints points: [CGPoint]) -> UIBezierPath {
    let line = UIBezierPath()
    let firstPoint = points[0]
    line.move(to: firstPoint)
    for i in 1..<points.count {
      line.addLine(to: points[i])
    }
    return line
  }
  
  func squareBezierLine(withPoints points: [CGPoint]) -> UIBezierPath {
    let line = UIBezierPath()
    let firstPoint = points[0]
    line.move(to: firstPoint)
    for i in 1..<points.count {
      let nextPoint = points[i]
      line.addLine(to: CGPoint(x: nextPoint.x, y: line.currentPoint.y))
      line.addLine(to: CGPoint(x: line.currentPoint.x, y: nextPoint.y))
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
  
  func squareBezierArea(topPoints: [CGPoint], bottom: CGFloat) -> UIBezierPath {
    let line = UIBezierPath()
    var curY = bottom
    let firstPoint = topPoints.first!
    line.move(to: CGPoint(x: firstPoint.x, y: curY))
    line.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
    curY = firstPoint.y
    for tp in topPoints[1..<topPoints.count] {
      line.addLine(to: CGPoint(x: tp.x, y: curY))
      line.addLine(to: CGPoint(x: tp.x, y: tp.y))
      curY = tp.y
    }
    line.addLine(to: CGPoint(x: line.currentPoint.x, y: bottom))
    line.close()
    return line
  }
  
  func bezierArea(topPoints: [CGPoint], bottom: CGFloat) -> UIBezierPath {
    let line = UIBezierPath()
    let firstPoint = topPoints.first!
    line.move(to: CGPoint(x: firstPoint.x, y: bottom))
    for tp in topPoints {
      line.addLine(to: CGPoint(x: tp.x, y: tp.y))
    }
    line.addLine(to: CGPoint(x: line.currentPoint.x, y: bottom))
    line.close()
    return line
  }
  
  func bezierArea(topPath: UIBezierPath, bottomPath: UIBezierPath) -> UIBezierPath {
    let path = UIBezierPath()
    path.append(topPath)
    path.addLine(to: bottomPath.currentPoint)
    path.append(bottomPath.reversing())
    path.addLine(to: topPath.reversing().currentPoint)
    return path
  }
  
  func shapeLayer(withPath path: CGPath, color: CGColor, lineWidth: CGFloat = 2, fillColor: CGColor? = nil) -> CAShapeLayer{
    let shapeLayer = CAShapeLayer()
    shapeLayer.path = path
    shapeLayer.strokeColor = color
    shapeLayer.lineWidth = lineWidth
    shapeLayer.lineJoin = .round
    shapeLayer.lineCap = .round
    shapeLayer.fillColor = fillColor
    shapeLayer.contentsScale = ChartViewConstants.contentScaleForShapes
    return shapeLayer
  }
  
  func filledShapeLayer(withPath path: CGPath, color: CGColor) -> CAShapeLayer {
    let fillLayer = CAShapeLayer()
    fillLayer.path = path
    fillLayer.fillColor = color
    fillLayer.lineJoin = .miter
    fillLayer.lineCap = .butt
    fillLayer.contentsScale = ChartViewConstants.contentScaleForShapes
    return fillLayer
  }
  
  func textLayer(origin: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = ChartViewConstants.guideLabelsFont
    textLayer.fontSize = ChartViewConstants.guideLabelsFontSize
    textLayer.string = text
    textLayer.frame = CGRect(origin: origin, size: ChartViewConstants.sizeForGuideLabels)
    textLayer.contentsScale = ChartViewConstants.contentScaleForText
    textLayer.foregroundColor = color
    return textLayer
  }
  
  func textLayer(position: CGPoint, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.font = ChartViewConstants.guideLabelsFont
    textLayer.fontSize = ChartViewConstants.guideLabelsFontSize
    textLayer.string = text
    textLayer.frame = CGRect(origin: CGPoint.zero, size: ChartViewConstants.sizeForGuideLabels)
    textLayer.position = position
    textLayer.contentsScale = ChartViewConstants.contentScaleForText
    textLayer.foregroundColor = color
    return textLayer
  }
  
  // MARK: - Structs and typealiases
  
  struct VectorData: VectorDataProtocol {
    let xVector: ValueVector
    let yVectors: [ValueVector]
    let yRangeData: YRangeDataProtocol
    let points: [[CGPoint]]
  }
  
  struct YRangeData: YRangeDataProtocol {
    let yRange: ClosedRange<CGFloat>
  }
  
  private struct YRangeChangeResult: YRangeChangeResultProtocol {
    let didChange: Bool
  }
  
  private class HorizontalAxis {
    private(set) var lineLayer: CAShapeLayer
    private(set) var labelLayer: CATextLayer
    private(set) var value: CGFloat
    
    init(lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat) {
      self.lineLayer = lineLayer
      self.labelLayer = labelLayer
      self.value = value
    }
    
    func update(labelLayer: CATextLayer, value: CGFloat) {
      self.labelLayer = labelLayer
      self.value = value
    }
    
    func update(lineLayer: CAShapeLayer, labelLayer: CATextLayer, value: CGFloat) {
      self.lineLayer = lineLayer
      update(labelLayer: labelLayer, value: value)
    }
  }
  
  class ChartDrawings {
    let drawings: [Drawing]
    var xPositions: [CGFloat]
    
    init(drawings: [Drawing], xPositions: [CGFloat]) {
      self.drawings = drawings
      self.xPositions = xPositions
    }
  }
  
  class Drawing {
    let shapeLayer: CAShapeLayer
    var yPositions: [CGFloat]
    
    init(shapeLayer: CAShapeLayer, yPositions: [CGFloat]) {
      self.shapeLayer = shapeLayer
      self.yPositions = yPositions
    }
  }
  
  private class ChartAnnotation: BaseChartAnnotation {
    let lineLayer: CAShapeLayer
    let circleLayers: [CAShapeLayer]
    
    init(lineLayer: CAShapeLayer, annotationView: TGCAChartAnnotationView, circleLayers: [CAShapeLayer], displayedIndex: Int){
      self.lineLayer = lineLayer
      self.circleLayers = circleLayers
      super.init(annotationView: annotationView, displayedIndex: displayedIndex)
    }
    
  }
  
  struct zPositions {
    enum Annotation: CGFloat {
      case view = 10
      case lineShape = 5
      case circleShape = 6
    }
    
    enum Chart: CGFloat {
      case axis = 7
      case graph = 0
      case axisLabels = 2
      case dates = 8
    }
  }
  
  struct GuideLabel {
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
      (currentChartAnnotation as? ChartAnnotation)?.circleLayers.forEach{$0.fillColor = circlePointFillColor}
      (currentChartAnnotation as? ChartAnnotation)?.lineLayer.strokeColor = axisColor
      
      //axis
      horizontalAxes?.forEach{
        $0.lineLayer.strokeColor = axisColor
        $0.labelLayer.foregroundColor = axisLabelColor
      }
      
      //guide labels
      activeGuideLabels?.forEach{$0.textLayer.foregroundColor = axisLabelColor}
      transitioningGuideLabels?.forEach{$0.textLayer.foregroundColor = axisLabelColor}
    }
    
    if animated {
      CATransaction.begin()
      CATransaction.setAnimationDuration(ANIMATION_DURATION)
      applyChanges()
      CATransaction.commit()
    } else {
      applyChanges()
    }
  }
  
}

protocol ChartAnnotationProtocol {
  var displayedIndex: Int {get}
  var annotationView: TGCAChartAnnotationView {get}
  
  func updateDisplayedIndex(to index: Int)
}

class BaseChartAnnotation: ChartAnnotationProtocol {
  private(set) var displayedIndex: Int
  let annotationView: TGCAChartAnnotationView
  
  init(annotationView: TGCAChartAnnotationView, displayedIndex: Int){
    self.annotationView = annotationView
    self.displayedIndex = displayedIndex
  }
  
  func updateDisplayedIndex(to index: Int) {
    self.displayedIndex = index
  }

}

protocol VectorDataProtocol {
  var xVector: ValueVector {get}
  var yVectors: [ValueVector] {get}
  var points: [[CGPoint]] {get}
  var yRangeData: YRangeDataProtocol {get}
}

protocol YRangeDataProtocol {}
protocol YRangeChangeResultProtocol {}
