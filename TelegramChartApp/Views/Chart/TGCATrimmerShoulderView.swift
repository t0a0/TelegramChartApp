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

  let imageView = UIImageView()
  /// Increases the hit detection rect.
  var boundsInsetIncreaseValue: CGFloat = 10.0
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    return increasedBounds.contains(point) ? self : nil
  }
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return increasedBounds.contains(point)
  }
  
  private var increasedBounds: CGRect {
    return bounds.insetBy(dx: -1 * boundsInsetIncreaseValue, dy: -1 * boundsInsetIncreaseValue)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    setupImageView()
  }
  
  func setupImageView() {
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isUserInteractionEnabled = true
    addSubview(imageView)
    
    imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1).isActive = true
    imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    imageView.isUserInteractionEnabled = false
    imageView.tintColor = .white
  }
}

class TGCATrimmerLeftShoulderView: TGCATrimmerShoulderView {
  
  override func layoutSubviews() {
    super.layoutSubviews()
    roundCorners([.topLeft, .bottomLeft], radius: TGCATrimmerView.shoulderWidth)
  }
  
  override func setupImageView() {
    super.setupImageView()
    imageView.image = UIImage(named: "disclosure_image_reversed")
  }
  
}

class TGCATrimmerRightShoulderView: TGCATrimmerShoulderView {
  
  override func layoutSubviews() {
    super.layoutSubviews()
    roundCorners([.topRight, .bottomRight], radius: TGCATrimmerView.shoulderWidth)
  }
  
  override func setupImageView() {
    super.setupImageView()
    imageView.image = UIImage(named: "disclosure_image")
  }
  
}
