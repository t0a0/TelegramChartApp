//
//  TGCAChartHeaderView.swift
//  TelegramChartApp
//
//  Created by Igor on 06/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartHeaderView: UIView {

  @IBOutlet var contentView: UIView!
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var zoomOutButton: UIButton!
  
  var onZoomOut: (()->())?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit () {
    Bundle.main.loadNibNamed("TGCAChartHeaderView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    applyCurrentTheme()
  }
  
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
  
  @IBAction func zoomOutTapped(_ sender: Any) {
    onZoomOut?()
  }
  
}

extension TGCAChartHeaderView: ThemeChangeObserving {
  
  func handleThemeChangedNotification() {
    applyCurrentTheme(animated: true)
  }
  
  func applyCurrentTheme(animated: Bool = false) {
    let theme = UIApplication.myDelegate.currentTheme
    
    func applyChanges() {
      label.textColor = theme.mainTextColor
    }
    
    if animated {
      UIView.animate(withDuration: ANIMATION_DURATION) {
        applyChanges()
      }
    } else {
      applyChanges()
    }
  }
  
}
