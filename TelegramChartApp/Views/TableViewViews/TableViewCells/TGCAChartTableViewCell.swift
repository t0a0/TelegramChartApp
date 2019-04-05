//
//  TGCAChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 09/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartTableViewCell: UITableViewCell {

  static let defaultReuseId = "chartViewCell"

  @IBOutlet weak var chartView: TGCAChartView!

  @IBOutlet weak var thumbnailChartView: TGCAChartView!
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    chartView?.graphLineWidth = 2.0
    chartView?.shouldDisplayAxesAndLabels = true
    thumbnailChartView?.animatesPositionOnHide = false
    thumbnailChartView?.valuesStartFromZero = false
    thumbnailChartView?.canShowAnnotations = false
    thumbnailChartView?.isUserInteractionEnabled = false
    thumbnailChartView?.graphLineWidth = 1.0
  }
}
