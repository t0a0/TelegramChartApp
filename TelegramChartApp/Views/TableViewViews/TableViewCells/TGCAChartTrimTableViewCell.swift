//
//  TGCAChartTrimTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 15/03/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCAChartTrimTableViewCell: UITableViewCell {
  static let defaultReuseId = "chartTrimCell"
  
  @IBOutlet weak var trimmerView: TGCATrimmerView!
  
  @IBOutlet weak var chartView: TGCAChartView!
  
}
