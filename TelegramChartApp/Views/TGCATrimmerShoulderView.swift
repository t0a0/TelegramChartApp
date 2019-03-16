//
//  TGCATrimmerShoulderView.swift
//  TelegramChartApp
//
//  Created by Igor on 10/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit
import Foundation

class TGCATrimmerShoulderView: UIView {
  
  /// Specify a value by which to increase the hit detection rect. Default is 15.0.
  var boundsInsetIncreaseValue: CGFloat = 15.0
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return increasedBounds.contains(point) ? self : nil
  }
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return increasedBounds.contains(point)
  }
  
  private var increasedBounds: CGRect {
    return bounds.insetBy(dx: -1 * boundsInsetIncreaseValue, dy: -1 * boundsInsetIncreaseValue)
  }
  
}

class TGCATrimmerLeftShoulderView: TGCATrimmerShoulderView {
  
  override func draw(_ rect: CGRect) {
    let line = UIBezierPath()
    line.lineWidth = 2.0
    line.lineJoinStyle = .round
    UIColor.white.setStroke()
    line.move(to: CGPoint(x: rect.origin.x + rect.width * 0.6, y: rect.origin.y + rect.height * 0.35))
    line.addLine(to: CGPoint(x: rect.origin.x + rect.width * 0.4, y: rect.origin.y + rect.height * 0.5))
    line.addLine(to: CGPoint(x: rect.origin.x + rect.width * 0.6, y: rect.origin.y + rect.height * 0.65))
    line.stroke()
  }
  
}

class TGCATrimmerRightShoulderView: TGCATrimmerShoulderView {
  
  override func draw(_ rect: CGRect) {
    let line = UIBezierPath()
    line.lineWidth = 2.0
    line.lineJoinStyle = .round
    UIColor.white.setStroke()
    line.move(to: CGPoint(x: rect.origin.x + rect.width * 0.4, y: rect.origin.y + rect.height * 0.35))
    line.addLine(to: CGPoint(x: rect.origin.x + rect.width * 0.6, y: rect.origin.y + rect.height * 0.5))
    line.addLine(to: CGPoint(x: rect.origin.x + rect.width * 0.4, y: rect.origin.y + rect.height * 0.65))
    line.stroke()
  }
  
}
