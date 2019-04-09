//
//  TGCALinearChartWith2AxesTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCALinearChartWith2AxesTableViewCell: TGCAChartTableViewCell {
  static let defaultReuseId = "TGCALinearChartWith2AxesTableViewCell"
  
  @IBOutlet weak var linearChartWith2AxesView: TGCALinearChartWithTwoYAxisView!
  @IBOutlet weak var linearThumbnailChartWith2AxesView: TGCALinearChartWithTwoYAxisView!

  override var chartView: TGCAChartView! {
    get {
      return linearChartWith2AxesView
    }
    set {
      linearChartWith2AxesView = (newValue as! TGCALinearChartWithTwoYAxisView)
    }
  }
  override var thumbnailChartView: TGCAChartView! {
    get {
      return linearThumbnailChartWith2AxesView
    }
    set {
      linearThumbnailChartWith2AxesView = (newValue as! TGCALinearChartWithTwoYAxisView)
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    chartView?.valuesStartFromZero = false
  }
}
