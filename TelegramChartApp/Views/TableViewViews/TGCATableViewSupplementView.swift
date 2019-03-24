//
//  TGCATableViewSupplementView.swift
//  TelegramChartApp
//
//  Created by Igor on 20/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import Foundation
import UIKit

class TGCATableViewSupplementView: UIView {
  
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var bottomLabel: UILabel!
  @IBOutlet weak var topLabel: UILabel!
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required init?(coder aDecoder:NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit () {
    Bundle.main.loadNibNamed("TGCATableViewSupplementView", owner: self, options: nil)
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }
}
