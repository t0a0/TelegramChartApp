//
//  UIViewExtensions.swift
//  TelegramChartApp
//
//  Created by Igor on 10/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
  func revealTransition() {
    let animation = CATransition()
    animation.type = .reveal
    animation.subtype = .fromTop
    animation.duration = ANIMATION_DURATION
    layer.removeAnimation(forKey: "reveal")
    layer.add(animation, forKey: "reveal")
  }
  
  func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    self.layer.mask = mask
  }
  
}
