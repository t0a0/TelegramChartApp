//
//  TGCALinearChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCALinearChartTableViewCell: TGCAChartTableViewCell {
  static let defaultReuseId = "TGCALinearChartTableViewCell"
  
  @IBOutlet weak var linearChartView: TGCALinearChartView!
  @IBOutlet weak var linearThumbnailChartView: TGCALinearChartView!
  override var chartView: TGCAChartView! {
    get {
      return linearChartView
    }
    set {
      linearChartView = (newValue as! TGCALinearChartView)
    }
  }
  
  override var thumbnailChartView: TGCAChartView! {
    get {
      return linearThumbnailChartView
    }
    set {
      linearThumbnailChartView = (newValue as! TGCALinearChartView)
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    chartView?.valuesStartFromZero = false
  }
}
