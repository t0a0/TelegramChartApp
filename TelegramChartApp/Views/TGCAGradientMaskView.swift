//
//  TGCAGradientMaskView.swift
//  TelegramChartApp
//
//  Created by Igor on 12/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCAGradientMaskView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureGradient()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureGradient() {
    let gradient = CAGradientLayer()
    gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
    gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
    let whiteColor = UIColor.white
    gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(1.0).cgColor]
    gradient.locations = [NSNumber(value: 0.0) ,NSNumber(value: 1.0)]
    gradient.frame = bounds
    layer.mask = gradient
  }
  
}
