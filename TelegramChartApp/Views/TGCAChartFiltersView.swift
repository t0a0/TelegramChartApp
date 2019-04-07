//
//  TGCAChartFiltersView.swift
//  TelegramChartApp
//
//  Created by Igor on 07/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartFiltersView: UIView {
  
  static let spacing: CGFloat = 8.0
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    clipsToBounds = true
    backgroundColor = .clear
  }
  
  func setupButtons(_ buttons: [TGCAFilterButton]) {
    var i = 0
    var curX: CGFloat = 0
    var curY: CGFloat = 0
    while i < buttons.count {
      let b = buttons[i]
      if curX + b.frame.width > bounds.width {
        curX = 0
        curY += TGCAFilterButton.buttonHeight + TGCAChartFiltersView.spacing
      }
      addSubview(b)
      b.frame.origin = CGPoint(x: curX, y: curY)
      curX += b.frame.width + TGCAChartFiltersView.spacing
      i += 1
    }
  }
}
