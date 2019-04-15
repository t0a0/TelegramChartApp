//
//  TGCAPieChartView.swift
//  TelegramChartApp
//
//  Created by Igor on 15/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAPieChartView: TGCAChartView {
  
  //MARK: - Configs
  var segmentLabelFont: UIFont = UIFont.systemFont(ofSize: 14) {
    didSet {
      textAttributes[.font] = segmentLabelFont
    }
  }
  private let paragraphStyle: NSParagraphStyle = {
    var p = NSMutableParagraphStyle()
    p.alignment = .center
    return p.copy() as! NSParagraphStyle
  }()
  
  private lazy var textAttributes: [NSAttributedString.Key: Any] = [
    .paragraphStyle: self.paragraphStyle, .font: self.segmentLabelFont
  ]
  
  var radius: CGFloat {
    return min(frame.width, frame.height) * 0.4
  }
  
  //MARK: - Body
  
  private var pieSegments: [PieSegment]!
  private var trimmedXRange: ClosedRange<Int>!
  
  override func configure(with chart: DataChart, hiddenIndicies: Set<Int>, displayRange: CGFloatRangeInBounds) {
    clean()
    self.chart = chart
    self.hiddenDrawingIndicies = hiddenIndicies
    self.trimmedXRange = chart.translatedBounds(for: displayRange)
    drawPie()
  }
  
  override func trimDisplayRange(to newRange: CGFloatRangeInBounds, with event: DisplayRangeChangeEvent) {
    let newTranslatedRange = chart.translatedBounds(for: newRange)
    guard newTranslatedRange != trimmedXRange else {
      return
    }
    
    trimmedXRange = newTranslatedRange
    updatePie()
  }
  
  override func hideAll() {
    
  }
  
  override func showAll() {
    
  }
  
  override func toggleHidden(at indexes: Set<Int>) {
    
  }
  
  //MARK: - Draw
  
  func drawPie() {
    let slices = getYVectorsMappedToSlices()
    
    var segments = [PieSegment]()
    
    forEachSlice(in: slices) { (slice, startAngle, endAngle) in
      let halfAngle = startAngle + (endAngle - startAngle) * 0.5;
      
      // Get the 'center' of the segment.
      var segmentCenter = center
      if slices.count > 1 {
        segmentCenter = segmentCenter
          .projected(by: radius * 0.67, angle: halfAngle)
      }
      
      let textToRender = slice.text
    
      let textRenderSize = textToRender.size(withAttributes: textAttributes)
      
      // The bounds that the text will occupy.
      let renderRect = CGRect(
        centeredOn: segmentCenter, size: textRenderSize
      )
      
      let textLayerr = textLayer(in: renderRect, text: slice.text, color: UIColor.black.cgColor)
      textLayerr.zPosition = 2
      let path = pieSlicePath(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle)
      let shape = shapeLayer(pieSlicePath: path, fillColor: slice.color)
      shape.zPosition = 1
      let segment = PieSegment(value: slice.value, text: slice.text, angle: halfAngle, textLayer: textLayerr, shapeLayer: shape)
      segments.append(segment)
    }
    
    self.pieSegments = segments
    pieSegments.forEach{
      layer.addSublayer($0.shapeLayer)
      layer.addSublayer($0.textLayer)
    }
  }
  
  private func updatePie() {
    let slices = getYVectorsMappedToSlices()
    
    var newPaths = [CGPath]()
    var newValues = [CGFloat]()
    var newAngles = [CGFloat]()
    var newTexts = [String]()
    forEachSlice(in: slices) { (slice, startAngle, endAngle) in
      let halfAngle = startAngle + (endAngle - startAngle) * 0.5;
      
      // Get the 'center' of the segment.
      var segmentCenter = center
      if slices.count > 1 {
        segmentCenter = segmentCenter
          .projected(by: radius * 0.67, angle: halfAngle)
      }
      
      let textToRender = slice.text
      
      let textRenderSize = textToRender.size(withAttributes: textAttributes)
      
      // The bounds that the text will occupy.
      let renderRect = CGRect(
        centeredOn: segmentCenter, size: textRenderSize
      )
      
      let path = pieSlicePath(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle)
      newPaths.append(path)
      newValues.append(slice.value)
      newAngles.append(halfAngle)
      newTexts.append(slice.text)
    }
    for i in 0..<pieSegments.count {
      pieSegments[i].angle = newAngles[i]
      pieSegments[i].value = newValues[i]
      pieSegments[i].text = newTexts[i]
    }
    animatePies(with: newPaths)
  }
  
  private func animatePies(with newPaths: [CGPath]) {
    for i in 0..<pieSegments.count {
      let pieSegment = pieSegments[i]
      
//      var oldPath: Any?
//      if let _ = pieSegment.shapeLayer.animation(forKey: "pathAnim") {
//        oldPath = pieSegment.shapeLayer.presentation()?.value(forKey: "path")
//        pieSegment.shapeLayer.removeAnimation(forKey: "pathAnim")
//      }
      
      let anim = CABasicAnimation(keyPath: "path")
      anim.duration = CHART_PATH_ANIMATION_DURATION
      anim.timingFunction = CAMediaTimingFunction(name: .linear)
      anim.fromValue = /*oldPath ?? */pieSegment.shapeLayer.path
      pieSegment.shapeLayer.path = newPaths[i]
      anim.toValue = pieSegment.shapeLayer.path
      pieSegment.shapeLayer.add(anim, forKey: "pathAnim")
    }
  }
  
  //MARK: - Annotation
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
  }
  
  //MARK: - Helpers
  
  private func getYVectorsMappedToSlices() -> [Slice] {
    let includedIndicies = (0..<chart.yVectors.count).filter{!hiddenDrawingIndicies.contains($0)}
    let yVectors = chart.yVectors
    let percentages = chart.percentages(at: Array(trimmedXRange), includedIndicies: includedIndicies)
    let sums = chart.sums(at: Array(trimmedXRange))
    var slices = [Slice]()
    for i in 0..<yVectors.count {
      let yV = yVectors[i]
      let slice = Slice(value: sums[i], text: "\(percentages[i])%", color: yV.metaData.color.cgColor)
      slices.append(slice)
    }
    return slices
  }
  
  private func forEachSlice(in slices: [Slice],
                            _ body: (Slice, _ startAngle: CGFloat,
    _ endAngle: CGFloat) -> Void
    ) {
    let valueCount = slices.map { $0.value }.sum()
    var startAngle: CGFloat = -.pi * 0.5
    for pieSlice in slices {
      let endAngle = startAngle + .pi * 2 * (pieSlice.value / valueCount)
      defer {
        startAngle = endAngle
      }
      body(pieSlice, startAngle, endAngle)
    }
  }
  
  //MARK: - Clean
  
  func clean() {
    pieSegments?.forEach {
      $0.textLayer.removeFromSuperlayer()
      $0.shapeLayer.removeFromSuperlayer()
    }
    pieSegments = nil
    
    chart = nil
  }
  
  //MARK: - Drawing
  
  func pieSlicePath(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> CGPath {
    let path = UIBezierPath()
    path.move(to: center)
    path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    return path.cgPath
  }
  
  func shapeLayer(pieSlicePath: CGPath, fillColor: CGColor) -> CAShapeLayer{
    
    let layer = CAShapeLayer()
    layer.path = pieSlicePath
    layer.fillColor = fillColor
    layer.strokeColor = fillColor
    layer.lineWidth = 0.2
    layer.contentsScale = UIScreen.main.scale
    return layer
  }
  
  func textLayer(in rect: CGRect, text: String, color: CGColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.frame = rect
    textLayer.font = textAttributes[.font] as CFTypeRef
    textLayer.fontSize = ChartViewConstants.guideLabelsFontSize
    textLayer.string = text
    textLayer.contentsScale = ChartViewConstants.contentScaleForText
    textLayer.foregroundColor = color
    textLayer.alignmentMode = .center
    return textLayer
  }
  
  //MARK: - Classes
  
  private class PieSegment {
    var value: CGFloat
    var text: String
    var angle: CGFloat
    let textLayer: CATextLayer
    let shapeLayer: CAShapeLayer
    
    init(value: CGFloat, text: String, angle: CGFloat, textLayer: CATextLayer, shapeLayer: CAShapeLayer) {
      self.value = value
      self.text = text
      self.angle = angle
      self.textLayer = textLayer
      self.shapeLayer = shapeLayer
    }
  }
  
  private struct Slice {
    let value: CGFloat
    let text: String
    let color: CGColor
  }
  
  //MARK: - dummy overrides
  
  override func commonInit() {}
  
  override func layoutSubviews() {}
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
  
}

extension Collection where Element : Numeric {
  func sum() -> Element {
    return reduce(0, +)
  }
}

extension CGPoint {
  func projected(by value: CGFloat, angle: CGFloat) -> CGPoint {
    return CGPoint(
      x: x + value * cos(angle), y: y + value * sin(angle)
    )
  }
}

extension CGRect {
  init(centeredOn center: CGPoint, size: CGSize) {
    self.init(
      origin: CGPoint(
        x: center.x - size.width * 0.5, y: center.y - size.height * 0.5
      ),
      size: size
    )
  }
  
  var center: CGPoint {
    return CGPoint(
      x: origin.x + size.width * 0.5, y: origin.y + size.height * 0.5
    )
  }
}
