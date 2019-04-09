//
//  TGCAPercentageChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAPercentageChartTableViewCell: TGCAChartTableViewCell {
  static let defaultReuseId = "TGCAPercentageChartTableViewCell"
  
  @IBOutlet weak var percentageChartView: TGCAPercentageChartView!
  @IBOutlet weak var percentageThumbnailChartView: TGCAPercentageChartView!

  override var chartView: TGCAChartView! {
    get {
      return percentageChartView
    }
    set {
      percentageChartView = (newValue as! TGCAPercentageChartView)
    }
  }
  
  override var thumbnailChartView: TGCAChartView! {
    get {
      return percentageThumbnailChartView
    }
    set {
      percentageThumbnailChartView = (newValue as! TGCAPercentageChartView)
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    thumbnailChartView?.graphLineWidth = 0.0
  }
  
}
