//
//  TGCASingleBarChartTableViewCell.swift
//  TelegramChartApp
//
//  Created by Igor on 08/04/2019.
//  Copyright © 2019 Fedotov Igor. All rights reserved.
//

import UIKit

class TGCASingleBarChartTableViewCell: TGCAChartTableViewCell {
  static let defaultReuseId = "TGCASingleBarChartTableViewCell"
  
  @IBOutlet weak var singleBarChartView: TGCASingleBarChartView!
  @IBOutlet weak var singleThumbnailBarChartView: TGCASingleBarChartView!

  override var chartView: TGCAChartView! {
    get {
      return singleBarChartView
    }
    set {
      singleBarChartView = (newValue as! TGCASingleBarChartView)
    }
  }
  
  override var thumbnailChartView: TGCAChartView! {
    get {
      return singleThumbnailBarChartView
    }
    set {
      singleThumbnailBarChartView = (newValue as! TGCASingleBarChartView)
    }
  }
}
