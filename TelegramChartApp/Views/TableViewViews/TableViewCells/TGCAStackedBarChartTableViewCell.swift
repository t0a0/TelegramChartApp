//
//  TGCAStackedBarChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAStackedBarChartTableViewCell: TGCAChartTableViewCell {
  static let defaultReuseId = "TGCAStackedBarChartTableViewCell"
  
  @IBOutlet weak var stackedBarChartView: TGCAStackedBarChartView!
  @IBOutlet weak var stackedThumbnailBarChartView: TGCAStackedBarChartView!

  override var chartView: TGCAChartView! {
    get {
      return stackedBarChartView
    }
    set {
      stackedBarChartView = (newValue as! TGCAStackedBarChartView)
    }
  }
  
  override var thumbnailChartView: TGCAChartView! {
    get {
      return stackedThumbnailBarChartView
    }
    set {
      stackedThumbnailBarChartView = (newValue as! TGCAStackedBarChartView)
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    chartView?.valuesStartFromZero = true
  }
}
