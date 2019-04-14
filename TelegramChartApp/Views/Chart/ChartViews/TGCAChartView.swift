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
  
  struct ChartViewConstants {
    static let scrollViewPadding: CGFloat = 15.0
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
    
    struct AnimationKeys {
      static let updateByTrimming = "updateByTrimming"
    }
  }
  
  struct ChartConfiguration {
    let graphLineWidth: CGFloat
    let isThumbnail: Bool
    let valuesStartFromZero: Bool
    let canDisplayCircles: Bool
    
    static let Default = ChartConfiguration(graphLineWidth: 2.0, isThumbnail: false, valuesStartFromZero: false, canDisplayCircles: true)
    static let ThumbnailDefault = ChartConfiguration(graphLineWidth: 1.0, isThumbnail: true, valuesStartFromZero: false, canDisplayCircles: false)
    
    static let BarChartConfiguration = ChartConfiguration(graphLineWidth: 0, isThumbnail: false, valuesStartFromZero: true, canDisplayCircles: false)
    static let BarThumbnailChartConfiguration = ChartConfiguration(graphLineWidth: 0, isThumbnail: true, valuesStartFromZero: false, canDisplayCircles: false)

    //values start from zero will be ignored
    static let PercentageChartConfiguration = ChartConfiguration(graphLineWidth: 0, isThumbnail: false, valuesStartFromZero: true, canDisplayCircles: false)
    static let PercentageThumbnailChartConfiguration = ChartConfiguration(graphLineWidth: 0, isThumbnail: true, valuesStartFromZero: true, canDisplayCircles: false)

  }

  var onAnnotationClick: ((_ date: Date) -> (Bool))?

  // MARK: - Init
  let scrollView = UIScrollView()
  let axisLayer = CALayer()
  let lineLayer = CALayer()
  let lineBackgroundLayer = CALayer()
  let datesLayer = CALayer()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  func commonInit () {
    isMultipleTouchEnabled = false
    isUserInteractionEnabled = true
    applyCurrentTheme()
    axisLayer.zPosition = zPositions.Chart.axis.rawValue
    lineLayer.zPosition = zPositions.Chart.graph.rawValue
    lineBackgroundLayer.zPosition = zPositions.Chart.graph.rawValue
    datesLayer.zPosition = zPositions.Chart.dates.rawValue
    for l in [axisLayer, datesLayer] {
      layer.addSublayer(l)
    }
    
    scrollView.bounces = false
    scrollView.isScrollEnabled = false
    scrollView.isUserInteractionEnabled = false
    
    lineBackgroundLayer.masksToBounds = true
    lineBackgroundLayer.addSublayer(lineLayer)
    scrollView.layer.addSublayer(lineBackgroundLayer)
    addSubview(scrollView)

  }
  
  func setChartConfiguration(_ configuration: ChartConfiguration) {
    self.chartConfiguration = configuration
  }
  
  private(set) var chartConfiguration = ChartConfiguration.Default {
    didSet {
     layoutSubviews()
    }
  }
  
  // MARK: - Variables
  
  /// Service that knows how to format values for Y axes and dates for X axis.
  let chartLabelFormatterService = TGCAChartLabelFormatterService()
  
  func getGuideLabelDateString(for date: Date) -> String {
    return isUnderlying
    ? chartLabelFormatterService.prettyTimeString(from: date)
    : chartLabelFormatterService.prettyDateString(from: date)
  }
  
  var padding: CGFloat = 15
  
  var isUnderlying = false
  
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
  
  /// Range between total min and max Y of currently visible charts
  private(set) var currentYValueRange: ClosedRange<CGFloat> = 0...0
  private(set) var currentTrimRange: CGFloatRangeInBounds!
  
  private func updateCurrentYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResult {
    guard let yRangeData = (yRangeData as? YRangeData), yRangeData.yRange != currentYValueRange else {
      return YRangeChangeResult(didChange: false)
    }
    currentYValueRange = yRangeData.yRange
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
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    removeDrawings()
    removeHorizontalAxes()
    removeGuideLabels()
    removeChartAnnotation()
    CATransaction.commit()
//    currentYValueRange = 0...0
//    hiddenDrawingIndicies = nil
//    currentTrimRange = nil
  }
  
  func resetAxesAndLabels() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    removeHorizontalAxes()
    removeGuideLabels()
    CATransaction.commit()
  }
  
  override func layoutSubviews() {
    
    scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
    
    numOfGuideLabels = Int(scrollView.frame.width / ChartViewConstants.sizeForGuideLabels.width)
    if chart != nil {
//      lineLayer.frame = CGRect(origin: CGPoint.zero, size: scrollView.contentSize)
      configure()
      if drawings != nil {
        resetAxesAndLabels()
        addAxesAndLabelsIfNeeded()
        trimDisplayRange(to: currentTrimRange, with: .Reset)
      } else {
        updateScrollView(with: currentTrimRange, event: .Reset)
        drawChart()
        addAxesAndLabelsIfNeeded()
      }
      
    }
    
  }
  
  func addAxesAndLabelsIfNeeded() {
    if !chartConfiguration.isThumbnail  {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      addHorizontalAxes()
      addGuideLabels(for: chart.translatedBounds(for: currentTrimRange))
      CATransaction.commit()
    }
  }
  
  /// Configures the view to display the chart.
  func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: CGFloatRangeInBounds) {
    self.chart = chart
    currentTrimRange = displayRange
    hiddenDrawingIndicies = hiddenIndicies
  }
  
  private func updateScrollView(with newRange: CGFloatRangeInBounds, event: DisplayRangeChangeEvent) {
    if event != .Scrolled {
      
      scrollView.contentSize = CGSize(width: scrollView.frame.width * newRange.scale, height: scrollView.frame.height)
      
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      if !chartConfiguration.isThumbnail {
        lineBackgroundLayer.frame.size.width = scrollView.contentSize.width
        lineLayer.frame.size.width = lineBackgroundLayer.frame.width - padding*2
      } else {
        lineBackgroundLayer.frame.size.width = scrollView.contentSize.width
        lineLayer.frame.size.width = lineBackgroundLayer.frame.size.width
      }
      CATransaction.commit()
      
    }
    scrollView.contentOffset.x = scrollView.contentSize.width * newRange.offset
  }
  
  /// Updates the diplayed X range. Accepted are subranges of 0...1.
  func trimDisplayRange(to newRange: CGFloatRangeInBounds, with event: DisplayRangeChangeEvent) {
    if event == .Started {
      removeChartAnnotation()
      return
    }
    
    currentTrimRange = newRange
    updateScrollView(with: newRange, event: event)
  
    trimXDisplayRange(to: chart.translatedBounds(for: newRange), with: event)
  }
  
  private func trimXDisplayRange(to newRange: ClosedRange<Int>, with event: DisplayRangeChangeEvent) {
    
    
    if drawings.shapeLayers.first?.animation(forKey: ChartViewConstants.AnimationKeys.updateByTrimming) != nil && event == .Scrolled {
      return
    }
    
    updateChart(withEvent: event)

    if !chartConfiguration.isThumbnail {
      animateGuideLabelsChange(to: newRange, event: event)
    }
  }
  
  func hideAll() {
    toggleHidden(at: Set((0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}))
  }
  
  func showAll() {
    toggleHidden(at: hiddenDrawingIndicies)
  }
  
  /// Hides or shows the graph with identifier.
  func toggleHidden(identifier: String) {
    if let index = chart.indexOfChartValueVector(withId: identifier) {
      toggleHidden(at: [index])
    }
  }
  
  /// Hides or shows the graph at index.
  func toggleHidden(at indexes: Set<Int>) {
    var originalHiddens = Set<Int>()
    for index in indexes {
      let originalHidden = hiddenDrawingIndicies.contains(index)
      if originalHidden {
        hiddenDrawingIndicies.remove(index)
        originalHiddens.insert(index)
      } else {
        hiddenDrawingIndicies.insert(index)
      }
    }
   
    
    updateChartByHiding(at: indexes, originalHiddens: originalHiddens)
    
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
  
  func getCurrentYVectorData() -> YVectorDataProtocol {
    let normalizedYVectors = getNormalizedYVectors()
    let yVectors = normalizedYVectors.vectors.map{mapToChartBoundsHeight($0)}
    let yRangeData = YRangeData(yRange: normalizedYVectors.yRange)
    return YVectorData(yVectors: yVectors, yRangeData: yRangeData)
  }
  
  func updateYValueRange(with yRangeData: YRangeDataProtocol) -> YRangeChangeResultProtocol {
    return updateCurrentYValueRange(with: yRangeData)
  }
  
  func getPathsToDraw(with points: [[CGPoint]]) -> [CGPath] {
    return points.map{bezierLine(withPoints: $0).cgPath}
  }
  
  func getShapeLayersToDraw(for paths: [CGPath]) -> [CAShapeLayer] {
    return (0..<paths.count).map{
      shapeLayer(withPath: paths[$0], color: chart.yVectors[$0].metaData.color.cgColor, lineWidth: chartConfiguration.graphLineWidth)
    }
  }
  
  func addShapeSublayers(_ layers: [CAShapeLayer]) {
    layers.forEach{
      lineLayer.addSublayer($0)
    }
  }
  
  func animateChartUpdate(withYChangeResult yChangeResult: YRangeChangeResultProtocol?, paths: [CGPath], event: DisplayRangeChangeEvent) {
    //should not get scaled event here
    
    let didYChange = yChangeResult?.didChange ?? false
    
    if event == .Ended {
      drawings.shapeLayers.forEach{
        if let presPath = $0.presentation()?.value(forKey: "path") {
          $0.path = (presPath as! CGPath)
        }
        $0.removeAnimation(forKey: ChartViewConstants.AnimationKeys.updateByTrimming)
      }
    }
    
    for i in 0..<drawings.shapeLayers.count {
      let shapeLayer = drawings.shapeLayers[i]
      if didYChange || event == .Ended {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = shapeLayer.path
        shapeLayer.path = paths[i]
        pathAnimation.toValue = shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shapeLayer.add(pathAnimation, forKey: ChartViewConstants.AnimationKeys.updateByTrimming)
      } else {
        shapeLayer.path = paths[i]
      }
    }
  }
  
  func prepareToUpdateChartByHiding() {}
  
  func animateChartHide(at indexes: Set<Int>, originalHiddens: Set<Int>, newPaths: [CGPath]) {
    for i in 0..<drawings.shapeLayers.count {
      let shapeLayer = drawings.shapeLayers[i]
      
      var oldPath: Any?
      if let _ = shapeLayer.animation(forKey: ChartViewConstants.AnimationKeys.updateByTrimming) {
        oldPath = shapeLayer.presentation()?.value(forKey: "path")
        shapeLayer.removeAnimation(forKey: ChartViewConstants.AnimationKeys.updateByTrimming)
      }
      
      let positionChangeBlock = {
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = oldPath ?? shapeLayer.path
        shapeLayer.path = newPaths[i]
        pathAnimation.toValue = shapeLayer.path
        pathAnimation.duration = CHART_PATH_ANIMATION_DURATION
        shapeLayer.add(pathAnimation, forKey: ChartViewConstants.AnimationKeys.updateByTrimming)
      }
      
      if !chartConfiguration.isThumbnail {
        positionChangeBlock()
      } else {
        if !hiddenDrawingIndicies.contains(i) && !(originalHiddens.contains(i) && indexes.contains(i)) {
          positionChangeBlock()
        }
        if (originalHiddens.contains(i) && indexes.contains(i)) {
          shapeLayer.path = newPaths[i]
        }
      }
      
      if indexes.contains(i) {
        var oldOpacity: Any?
        if let _ = shapeLayer.animation(forKey: "opacityAnimation") {
          oldOpacity = shapeLayer.presentation()?.value(forKey: "opacity")
          shapeLayer.removeAnimation(forKey: "opacityAnimation")
        }
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = oldOpacity ?? shapeLayer.opacity
        shapeLayer.opacity = originalHiddens.contains(i) ? 1 : 0
        opacityAnimation.toValue = shapeLayer.opacity
        opacityAnimation.duration = CHART_FADE_ANIMATION_DURATION
        shapeLayer.add(opacityAnimation, forKey: "opacityAnimation")
      }
    }
  }
  
  //MARK: - Chart
  
  private func points(fromXvector xVector: ValueVector, yVectors: [ValueVector]) -> [[CGPoint]] {
    return (0..<yVectors.count).map{
      convertToPoints(xVector: xVector, yVector: yVectors[$0])
    }
  }
  
  private func drawChart() {
    prepareToDrawChart()
    let xVector = getXVectorMappedToScrollView()
    let yVectorData = getCurrentYVectorData()
    _ = updateYValueRange(with: yVectorData.yRangeData)
    
    let pathsToDraw = getPathsToDraw(with: points(fromXvector: xVector, yVectors: yVectorData.yVectors))
    let shapesToDraw = getShapeLayersToDraw(for: pathsToDraw)

    var shapeLayers = [CAShapeLayer]()
    for i in 0..<shapesToDraw.count {
      let shapeLayer = shapesToDraw[i]
      if hiddenDrawingIndicies.contains(i) {
        shapeLayer.opacity = 0
      }
      shapeLayers.append(shapeLayer)
    }
    
    drawings = ChartDrawings(shapeLayers: shapeLayers, xPositions: xVector, yVectorData: yVectorData)
    
    addShapeSublayers(shapesToDraw)
  }
  
  private func updateChart(withEvent event: DisplayRangeChangeEvent) {
    let xVector = event == .Scrolled ? drawings.xPositions : getXVectorMappedToScrollView()
    
    let yVectorData = event == .Scaled ? drawings.yVectorData : getCurrentYVectorData()
    
    let pathsToDraw = getPathsToDraw(with: points(fromXvector: xVector, yVectors: yVectorData.yVectors))

    let yChangeResult = updateYValueRange(with: yVectorData.yRangeData)
    
    if event == .Reset {
      (0..<drawings.shapeLayers.count).forEach{
        drawings.shapeLayers[$0].removeAnimation(forKey: ChartViewConstants.AnimationKeys.updateByTrimming)
        drawings.shapeLayers[$0].path = pathsToDraw[$0]
      }
    } else if event == .Scaled {
      (0..<drawings.shapeLayers.count).forEach{
        drawings.shapeLayers[$0].path = pathsToDraw[$0]
      }
    } else {
      animateChartUpdate(withYChangeResult: yChangeResult, paths: pathsToDraw, event: event)
    }
    
    drawings.yVectorData = yVectorData
    drawings.xPositions = xVector
  }
  
  private func updateChartByHiding(at indexes: Set<Int>, originalHiddens: Set<Int>) {
    prepareToUpdateChartByHiding()
    let xVector = getXVectorMappedToScrollView()
    let yVectorData = getCurrentYVectorData()
    
    let pathsToDraw = getPathsToDraw(with: points(fromXvector: xVector, yVectors: yVectorData.yVectors))

    _ = updateYValueRange(with: yVectorData.yRangeData)
    
    animateChartHide(at: indexes, originalHiddens: originalHiddens, newPaths: pathsToDraw)
    
    drawings.yVectorData = yVectorData

  }
  
  // MARK: - Configuration
  
  private func configure() {
    configureChartBounds()
    configureHorizontalAxesSpacing()
    configureHorizontalAxesDefaultPositions()
    applyFrameChangesRelativeToChartConfiguration()
  }
  
  func configureChartBounds() {
    // We need to inset drawing so that if the edge points are selected, the circular point on the graph is fully visible in the view
    let inset = chartConfiguration.graphLineWidth + ((!chartConfiguration.isThumbnail && chartConfiguration.canDisplayCircles) ? ChartViewConstants.circlePointRadius : 0)
    let additionalHeightInset = !chartConfiguration.isThumbnail ? ChartViewConstants.sizeForGuideLabels.height : 0
    chartBounds = CGRect(x: bounds.origin.x + inset,
                         y: bounds.origin.y + inset,
                         width: bounds.width - inset * 2,
                         height: bounds.height - inset * 2
                          - additionalHeightInset)
  }
  
  private func configureHorizontalAxesSpacing() {
    //add orogin y becase read comment in applyFrameChanges
    horizontalAxesSpacing = (chartBounds.height + chartBounds.origin.y) * ChartViewConstants.capHeightMultiplierForHorizontalAxes / CGFloat(numOfHorizontalAxes - 1)
  }
  
  private func configureHorizontalAxesDefaultPositions() {
    horizontalAxesDefaultYPositions = (0..<numOfHorizontalAxes).map{chartBoundsBottom - (CGFloat($0) * horizontalAxesSpacing)}
  }
  
  private func applyFrameChangesRelativeToChartConfiguration() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    
    
    axisLayer.frame = CGRect(origin: CGPoint(x: padding, y: 0), size: CGSize(width: bounds.size.width - padding*2, height: bounds.size.height - ChartViewConstants.sizeForGuideLabels.height))
    
    if !chartConfiguration.isThumbnail {
      lineLayer.frame.origin = CGPoint(x: padding, y: chartBounds.origin.y)
      // i remove origin y from both once so that they are cut off at zero, but circles i will add on to self.layer
      lineBackgroundLayer.frame.size.height = scrollView.frame.height - ChartViewConstants.sizeForGuideLabels.height - chartBounds.origin.y
      lineLayer.frame.size.height = lineBackgroundLayer.frame.height - chartBounds.origin.y
    } else {
      lineLayer.frame.origin = CGPoint.zero
      lineBackgroundLayer.frame.size.height = scrollView.frame.height
      lineLayer.frame.size.height = lineBackgroundLayer.frame.size.height
    }
    
    
    CATransaction.commit()
  }
  
  // MARK: - Guide Labels
  
  func addGuideLabels(for indexRange: ClosedRange<Int>) {
    
    let (spacing, leftover) = bestIndexSpacing(for: indexRange.distance + 1)
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
    if event == .Ended {
      removeTransitioningGuideLabels()
    }
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
    let strings = dates.map{getGuideLabelDateString(for: $0)}
    
    var labels = [GuideLabel]()
    for i in 0..<xIndexes.count {
      let textL = textLayer(origin: CGPoint(x: drawings.xPositions[xIndexes[i]], y: chartBoundsBottom + 5/* + heightForGuideLabels / 2*/), text: strings[i], color: axisXLabelColor)
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
      let labelLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[i], color: axisYLabelColor)
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
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[0], color: axisYLabelColor)
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
      let newTextLayer = textLayer(origin: CGPoint(x: bounds.origin.x, y: position - 20), text: texts[i], color: axisYLabelColor)
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
    return TGCAChartAnnotationView.AnnotationViewConfiguration(date: chart.datesVector[index], showsDisclosureIcon: !isUnderlying, mode: .Date, showsLeftColumn: false, coloredValues: coloredValues)
  }
  
  func addChartAnnotation(_ chartAnnotation: ChartAnnotationProtocol) {
    guard let chartAnnotation = chartAnnotation as? ChartAnnotation else {
      return
    }
    
    addSubview(chartAnnotation.annotationView)
    lineLayer.addSublayer(chartAnnotation.lineLayer)
    chartAnnotation.circleLayers.forEach {
      lineLayer.addSublayer($0)
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
    
    for i in 0..<drawings.yVectorData.yVectors.count {
      let color = chart.yVectors[i].metaData.color
      let point = CGPoint(x: xPoint, y: drawings.yVectorData.yVectors[i][index])
      let circle = bezierCircle(at: point, radius: ChartViewConstants.circlePointRadius)
      let circleShape = shapeLayer(withPath: circle.cgPath, color: color.cgColor, lineWidth: chartConfiguration.graphLineWidth, fillColor: circlePointFillColor)
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
    
    for i in 0..<drawings.yVectorData.yVectors.count {
      
      let point = CGPoint(x: xPoint, y: drawings.yVectorData.yVectors[i][index])
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
        grp.duration = CHART_PATH_ANIMATION_DURATION
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
    chartAnnotation.annotationView.onLongTap = { [weak self] in
      self?.removeChartAnnotation()
    }
    chartAnnotation.annotationView.onTap = { [weak self] in
      guard let strongSelf = self else {
        return
      }
      _ = strongSelf.onAnnotationClick?(strongSelf.chart.datesVector[chartAnnotation.displayedIndex])
    }
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
  
//  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//    return bounds.contains(point) ? self : nil
//  }
//
//  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//    return bounds.contains(point)
//  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first,
      !chartConfiguration.isThumbnail && hiddenDrawingIndicies.count != chart.yVectors.count,
      scrollView.frame.contains(touch.location(in: self)),
      !(currentChartAnnotation?.annotationView.frame.contains(touch.location(in: self)) ?? false)
    else {
        return super.touchesBegan(touches, with: event)
    }
    
    let index = closestIndex(for: touch.location(in: scrollView))
    
    if currentChartAnnotation != nil {
      moveChartAnnotation(to: index)
    } else {
      addChartAnnotation(for: index)
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first,
      let currentAnnotation = currentChartAnnotation,
      scrollView.frame.contains(touch.location(in: self)),
      !(currentChartAnnotation?.annotationView.frame.contains(touch.location(in: self)) ?? false)
      else {
        return super.touchesMoved(touches, with: event)
    }

    let index = closestIndex(for: touch.location(in: scrollView))

    if index != currentAnnotation.displayedIndex {
      moveChartAnnotation(to: index)
    }
  }
  
  func closestIndex(for touchLocation: CGPoint) -> Int {
    return min(chart.xVector.count-1, max(0, Int(round(touchLocation.x * CGFloat(chart.xVector.count-1) / scrollView.contentSize.width))))
  }
  
  // MARK: - Reset
  
  func removeDrawings() {
    drawings?.shapeLayers.forEach{$0.removeFromSuperlayer()}
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
      annotation.annotationView.removeFromSuperview()
      annotation.lineLayer.removeFromSuperlayer()
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
  
  func getNormalizedYVectors() -> NormalizedYVectors {
    let translatedBounds = chart.translatedBounds(for: currentTrimRange)
    return chartConfiguration.valuesStartFromZero
      ? chart.normalizedYVectorsFromZeroMinimum(in: translatedBounds, excludedIdxs: hiddenDrawingIndicies)
      : chart.normalizedYVectorsFromLocalMinimum(in: translatedBounds, excludedIdxs: hiddenDrawingIndicies)
  }
  
  func getXVectorMappedToScrollView() -> ValueVector {
    return chart.normalizedXPositions.map{$0 * lineLayer.frame.width}
  }
  
  func mapToChartBoundsHeight(_ vector: ValueVector) -> ValueVector {
    return vector.map{lineLayer.frame.height - ($0 * lineLayer.frame.height)}
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
    let additionalSpacingNeeded = topPoints.last!.x / CGFloat(topPoints.count)
    let decrement = additionalSpacingNeeded / CGFloat(topPoints.count)

    let line = UIBezierPath()
    var curY = bottom
    let firstPoint = topPoints.first!
    line.move(to: CGPoint(x: firstPoint.x, y: curY))
    line.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
    curY = firstPoint.y
    for i in 1..<topPoints.count {
      let tp = topPoints[i]
      let d =  tp.x - (decrement*CGFloat(i))
      line.addLine(to: CGPoint(x: d, y: curY))
      line.addLine(to: CGPoint(x: d, y: tp.y))
      curY = tp.y
    }
    line.addLine(to: topPoints.last!)
    line.addLine(to: CGPoint(x: line.currentPoint.x, y: bottom))
    line.close()
    return line
  }
  
  func squareBezierMaskAreas(topPoints: [CGPoint], bottom: CGFloat, visibleIdx: Int) -> (leftPath: CGPath, rightPath: CGPath) {
    let additionalSpacingNeeded = topPoints.last!.x / CGFloat(topPoints.count)
    let decrement = additionalSpacingNeeded / CGFloat(topPoints.count)
    
    let leftLine = UIBezierPath()
    
    if visibleIdx != 0 {
      let firstPoint = topPoints.first!
      leftLine.move(to: CGPoint(x: firstPoint.x, y: bottom))
      leftLine.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y))
      var curY = firstPoint.y
      for i in 1..<visibleIdx {
        let tp = topPoints[i]
        let d =  tp.x - (decrement*CGFloat(i))
        leftLine.addLine(to: CGPoint(x: d, y: curY))
        leftLine.addLine(to: CGPoint(x: d, y: tp.y))
        curY = tp.y
      }
      let a = topPoints[visibleIdx]
      leftLine.addLine(to: CGPoint(x: a.x - (decrement*CGFloat(visibleIdx)), y: curY))
      leftLine.addLine(to: CGPoint(x: leftLine.currentPoint.x, y: bottom))
      leftLine.close()
    }
    
    
    let rightLine = UIBezierPath()
    
    if visibleIdx != topPoints.count - 1 {
      let firstRightPoint = topPoints[visibleIdx+1]
      let c = firstRightPoint.x - (decrement*CGFloat(visibleIdx+1))
      rightLine.move(to: CGPoint(x: c, y: bottom))
      rightLine.addLine(to: CGPoint(x: c, y: firstRightPoint.y))
      var curY = firstRightPoint.y
      for i in (visibleIdx+1)..<topPoints.count {
        let tp = topPoints[i]
        let d =  tp.x - (decrement*CGFloat(i))
        rightLine.addLine(to: CGPoint(x: d, y: curY))
        rightLine.addLine(to: CGPoint(x: d, y: tp.y))
        curY = tp.y
      }
      rightLine.addLine(to: topPoints.last!)
      rightLine.addLine(to: CGPoint(x: rightLine.currentPoint.x, y: bottom))
      rightLine.close()
    }
    
    
    return (leftLine.cgPath, rightLine.cgPath)
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
  
  struct YVectorData: YVectorDataProtocol {
    let yVectors: [ValueVector]
    let yRangeData: YRangeDataProtocol
  }
  
  private struct YRangeData: YRangeDataProtocol {
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
    let shapeLayers: [CAShapeLayer]
    var xPositions: [CGFloat]
    var yVectorData: YVectorDataProtocol

    init(shapeLayers: [CAShapeLayer], xPositions: [CGFloat], yVectorData: YVectorDataProtocol) {
      self.shapeLayers = shapeLayers
      self.xPositions = xPositions
      self.yVectorData = yVectorData
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
  
  // MARK: - THeme
  
  var axisColor = UIColor.gray.cgColor
  var axisXLabelColor = UIColor.black.cgColor
  var axisYLabelColor = UIColor.black.cgColor
  var circlePointFillColor = UIColor.white.cgColor
  
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
  
  func applyColors() {
    let theme = UIApplication.myDelegate.currentTheme
    
    axisColor = theme.axisColor.cgColor
    axisXLabelColor = theme.axisLabelColor.cgColor
    axisYLabelColor = theme.axisLabelColor.cgColor
    circlePointFillColor = theme.foregroundColor.cgColor
  }
  
  func applyChanges() {
    //annotation
    (currentChartAnnotation as? ChartAnnotation)?.circleLayers.forEach{$0.fillColor = circlePointFillColor}
    (currentChartAnnotation as? ChartAnnotation)?.lineLayer.strokeColor = axisColor
    
    //axis
    horizontalAxes?.forEach{
      $0.lineLayer.strokeColor = axisColor
      $0.labelLayer.foregroundColor = axisYLabelColor
    }
    
    //guide labels
    activeGuideLabels?.forEach{$0.textLayer.foregroundColor = axisXLabelColor}
    transitioningGuideLabels?.forEach{$0.textLayer.foregroundColor = axisXLabelColor}
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    applyColors()
    
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

protocol YVectorDataProtocol {
  var yVectors: [ValueVector] {get}
  var yRangeData: YRangeDataProtocol {get}
}

protocol YRangeDataProtocol {}
protocol YRangeChangeResultProtocol {
  var didChange: Bool {get}
}
