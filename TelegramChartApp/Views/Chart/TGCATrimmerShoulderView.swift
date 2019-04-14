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
  
  var increasedBounds: CGRect {
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
    
    imageView.isUserInteractionEnabled = false
    imageView.tintColor = .white
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFit
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isUserInteractionEnabled = true
    addSubview(imageView)
    
    imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75).isActive = true
    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1).isActive = true
    imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
  }
}

class TGCATrimmerLeftShoulderView: TGCATrimmerShoulderView {
  
  override func layoutSubviews() {
    super.layoutSubviews()
    roundCorners([.topLeft, .bottomLeft], radius: TGCATrimmerView.shoulderWidth)
  }
  
  override func setupImageView() {
    super.setupImageView()
    imageView.image = UIImage(named: "disclosure_image_reversed")?.withRenderingMode(.alwaysTemplate)
    imageView.isOpaque = true
  }
  
  override var increasedBounds: CGRect {
    return bounds.inset(by: UIEdgeInsets(top: 0, left: -boundsInsetIncreaseValue, bottom: 0, right: -boundsInsetIncreaseValue/4.0))
  }
  
}

class TGCATrimmerRightShoulderView: TGCATrimmerShoulderView {
  
  override func layoutSubviews() {
    super.layoutSubviews()
    roundCorners([.topRight, .bottomRight], radius: TGCATrimmerView.shoulderWidth)
  }
  
  override func setupImageView() {
    super.setupImageView()
    imageView.image = UIImage(named: "disclosure_image")?.withRenderingMode(.alwaysTemplate)
    imageView.isOpaque = true
  }
  
  override var increasedBounds: CGRect {
    return bounds.inset(by: UIEdgeInsets(top: 0, left: -boundsInsetIncreaseValue/4.0, bottom: 0, right: -boundsInsetIncreaseValue))
  }
  
}
